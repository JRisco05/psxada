with Interfaces;
with PSX.Types;
with PSX.GTE.Instruction;

package body PSX.GTE.Execute is

   use type Interfaces.Unsigned_32;

   subtype Word32 is PSX.Types.Word32;

     function Signed_16 (Value : Word32) return Long_Long_Integer is
      V : constant Long_Long_Integer :=
        Long_Long_Integer
          (Value and 16#0000_FFFF#);
   begin
      if (Value and 16#0000_8000#) /= 0 then
         return V - 16#1_0000#;
      else
         return V;
      end if;
   end Signed_16;


      function Signed_32 (Value : Word32) return Long_Long_Integer is
   begin
      if (Value and 16#8000_0000#) /= 0 then
         return Long_Long_Integer (Value)
           - 16#1_0000_0000#;
      else
         return Long_Long_Integer (Value);
      end if;
   end Signed_32;

   function To_Word32
     (Value : Long_Long_Integer) return Word32 is
   begin
      return Word32
        (Interfaces.Unsigned_32
           (Value mod 16#1_0000_0000#));
   end To_Word32;


   function SAR
     (Value : Long_Long_Integer;
      Amount : Natural) return Long_Long_Integer is

      Divisor : constant Long_Long_Integer :=
        2 ** Amount;
   begin
      if Value >= 0 then
         return Value / Divisor;
      else
         return -((-Value) / Divisor);
      end if;
   end SAR;


   procedure Set_Flag
     (GTE : in out PSX.GTE.GTE_State;
      Bit : Natural) is
   begin
      GTE.FLAG :=
        GTE.FLAG or
        Interfaces.Shift_Left
          (Word32 (1), Bit);
   end Set_Flag;


   function Saturate_IR
     (GTE   : in out PSX.GTE.GTE_State;
      Value : Long_Long_Integer;
      Bit   : Natural;
      LM    : Boolean) return Word32 is

      Min_Value : constant Long_Long_Integer :=
        (if LM then 0 else -32_768);

      Max_Value : constant Long_Long_Integer := 32_767;

      Result : Long_Long_Integer := Value;

   begin
      if Result > Max_Value then
         Result := Max_Value;
         Set_Flag (GTE, Bit);

      elsif Result < Min_Value then
         Result := Min_Value;
         Set_Flag (GTE, Bit);
      end if;

      return To_Word32 (Result);
   end Saturate_IR;


   function Saturate_SZ3
     (GTE   : in out PSX.GTE.GTE_State;
      Value : Long_Long_Integer) return Word32 is

      Result : Long_Long_Integer := Value;

   begin
      if Result < 0 then
         Result := 0;
         Set_Flag (GTE, 18);

      elsif Result > 16#FFFF# then
         Result := 16#FFFF#;
         Set_Flag (GTE, 18);
      end if;

      return To_Word32 (Result);
   end Saturate_SZ3;


   function Saturate_Screen
     (GTE   : in out PSX.GTE.GTE_State;
      Value : Long_Long_Integer;
      Bit   : Natural) return Word32 is

      Result : Long_Long_Integer := Value;

   begin
      if Result < -16#400# then
         Result := -16#400#;
         Set_Flag (GTE, Bit);

      elsif Result > 16#3FF# then
         Result := 16#3FF#;
         Set_Flag (GTE, Bit);
      end if;

      return To_Word32 (Result);
   end Saturate_Screen;


   function Divide_Perspective
     (GTE : in out PSX.GTE.GTE_State;
      H   : Long_Long_Integer;
      SZ3 : Long_Long_Integer) return Long_Long_Integer is

      Numerator : Long_Long_Integer;
      Result    : Long_Long_Integer;

   begin
      if SZ3 <= 0 then
         Set_Flag (GTE, 17);
         Set_Flag (GTE, 31);
         return 16#1_FFFF#;
      end if;

      Numerator := H * 16#20_000#;

      Result := (Numerator / SZ3 + 1) / 2;

      if Result > 16#1_FFFF# then
         Set_Flag (GTE, 17);
         Set_Flag (GTE, 31);
         Result := 16#1_FFFF#;
      end if;

      return Result;
   end Divide_Perspective;

   procedure Transform_Vertex
  (GTE : in out PSX.GTE.GTE_State;
   VX  : Long_Long_Integer;
   VY  : Long_Long_Integer;
   VZ  : Long_Long_Integer;
   SF  : Natural;
   LM  : Boolean) is

   RT11 : constant Long_Long_Integer := Signed_16 (GTE.RT11);
   RT12 : constant Long_Long_Integer := Signed_16 (GTE.RT12);
   RT13 : constant Long_Long_Integer := Signed_16 (GTE.RT13);

   RT21 : constant Long_Long_Integer := Signed_16 (GTE.RT21);
   RT22 : constant Long_Long_Integer := Signed_16 (GTE.RT22);
   RT23 : constant Long_Long_Integer := Signed_16 (GTE.RT23);

   RT31 : constant Long_Long_Integer := Signed_16 (GTE.RT31);
   RT32 : constant Long_Long_Integer := Signed_16 (GTE.RT32);
   RT33 : constant Long_Long_Integer := Signed_16 (GTE.RT33);

   TRX : constant Long_Long_Integer := Signed_32 (GTE.TRX);
   TRY : constant Long_Long_Integer := Signed_32 (GTE.TRY);
   TRZ : constant Long_Long_Integer := Signed_32 (GTE.TRZ);

   H_Value : constant Long_Long_Integer :=
     Long_Long_Integer (GTE.H and 16#0000_FFFF#);

   OFX_Value : constant Long_Long_Integer :=
     Signed_32 (GTE.OFX);

   OFY_Value : constant Long_Long_Integer :=
     Signed_32 (GTE.OFY);

   DQA_Value : constant Long_Long_Integer :=
     Signed_16 (GTE.DQA);

   DQB_Value : constant Long_Long_Integer :=
     Signed_32 (GTE.DQB);

   MAC1_Raw : Long_Long_Integer;
   MAC2_Raw : Long_Long_Integer;
   MAC3_Raw : Long_Long_Integer;

   MAC1 : Long_Long_Integer;
   MAC2 : Long_Long_Integer;
   MAC3 : Long_Long_Integer;

   SZ3_Value : Long_Long_Integer;
   Perspective : Long_Long_Integer;
   MAC0 : Long_Long_Integer;

begin
   MAC1_Raw :=
     TRX * 16#1000#
     + RT11 * VX
     + RT12 * VY
     + RT13 * VZ;

   MAC2_Raw :=
     TRY * 16#1000#
     + RT21 * VX
     + RT22 * VY
     + RT23 * VZ;

   MAC3_Raw :=
     TRZ * 16#1000#
     + RT31 * VX
     + RT32 * VY
     + RT33 * VZ;

   MAC1 := SAR (MAC1_Raw, SF * 12);
   MAC2 := SAR (MAC2_Raw, SF * 12);
   MAC3 := SAR (MAC3_Raw, SF * 12);

   GTE.MAC1 := To_Word32 (MAC1);
   GTE.MAC2 := To_Word32 (MAC2);
   GTE.MAC3 := To_Word32 (MAC3);

   GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
   GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
   GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);

   -- Desplazamiento del FIFO SZ.
   GTE.SZ0 := GTE.SZ1;
   GTE.SZ1 := GTE.SZ2;
   GTE.SZ2 := GTE.SZ3;

   SZ3_Value := SAR (MAC3_Raw, 12);

   GTE.SZ3 := Saturate_SZ3 (GTE, SZ3_Value);

   SZ3_Value :=
     Long_Long_Integer
       (GTE.SZ3 and 16#0000_FFFF#);

   Perspective :=
     Divide_Perspective
       (GTE, H_Value, SZ3_Value);

   -- FIFO SXY.
   GTE.SX0 := GTE.SX1;
   GTE.SY0 := GTE.SY1;

   GTE.SX1 := GTE.SX2;
   GTE.SY1 := GTE.SY2;

   MAC0 :=
     Perspective * Signed_16 (GTE.IR1)
     + OFX_Value;

   GTE.MAC0 := To_Word32 (MAC0);

   GTE.SX2 :=
     Saturate_Screen
       (GTE, SAR (MAC0, 16), 14);

   MAC0 :=
     Perspective * Signed_16 (GTE.IR2)
     + OFY_Value;

   GTE.MAC0 := To_Word32 (MAC0);

   GTE.SY2 :=
     Saturate_Screen
       (GTE, SAR (MAC0, 16), 13);

   MAC0 :=
     Perspective * DQA_Value
     + DQB_Value;

   GTE.MAC0 := To_Word32 (MAC0);

   GTE.IR0 :=
     To_Word32
       (Long_Long_Integer'Min
          (16#1000#,
           Long_Long_Integer'Max
             (0,
              SAR (MAC0, 12))));

   if SAR (MAC0, 12) < 0
     or else SAR (MAC0, 12) > 16#1000#
   then
      Set_Flag (GTE, 12);
   end if;
end Transform_Vertex;

procedure Execute_RTPT
  (GTE  : in out PSX.GTE.GTE_State;
   Inst : PSX.GTE.Instruction.Instruction) is

   LM : constant Boolean :=
     PSX.GTE.Instruction.Lm (Inst) /= 0;

   SF : constant Natural :=
     Natural (PSX.GTE.Instruction.Sf (Inst));

begin
   GTE.FLAG := 0;

   Transform_Vertex
     (GTE,
      Signed_16 (GTE.V0_X),
      Signed_16 (GTE.V0_Y),
      Signed_16 (GTE.V0_Z),
      SF,
      LM);

   Transform_Vertex
     (GTE,
      Signed_16 (GTE.V1_X),
      Signed_16 (GTE.V1_Y),
      Signed_16 (GTE.V1_Z),
      SF,
      LM);

   Transform_Vertex
     (GTE,
      Signed_16 (GTE.V2_X),
      Signed_16 (GTE.V2_Y),
      Signed_16 (GTE.V2_Z),
      SF,
      LM);
end Execute_RTPT;

   procedure Execute_RTPS
     (GTE : in out PSX.GTE.GTE_State;
      Inst : PSX.GTE.Instruction.Instruction) is

      LM : constant Boolean :=
        PSX.GTE.Instruction.Lm (Inst) /= 0;

      SF : constant Natural :=
        Natural (PSX.GTE.Instruction.Sf (Inst));

      VX : constant Long_Long_Integer :=
        Signed_16 (GTE.V0_X);

      VY : constant Long_Long_Integer :=
        Signed_16 (GTE.V0_Y);

      VZ : constant Long_Long_Integer :=
        Signed_16 (GTE.V0_Z);

      RT11 : constant Long_Long_Integer := Signed_16 (GTE.RT11);
      RT12 : constant Long_Long_Integer := Signed_16 (GTE.RT12);
      RT13 : constant Long_Long_Integer := Signed_16 (GTE.RT13);

      RT21 : constant Long_Long_Integer := Signed_16 (GTE.RT21);
      RT22 : constant Long_Long_Integer := Signed_16 (GTE.RT22);
      RT23 : constant Long_Long_Integer := Signed_16 (GTE.RT23);

      RT31 : constant Long_Long_Integer := Signed_16 (GTE.RT31);
      RT32 : constant Long_Long_Integer := Signed_16 (GTE.RT32);
      RT33 : constant Long_Long_Integer := Signed_16 (GTE.RT33);

      TRX : constant Long_Long_Integer := Signed_32 (GTE.TRX);
      TRY : constant Long_Long_Integer := Signed_32 (GTE.TRY);
      TRZ : constant Long_Long_Integer := Signed_32 (GTE.TRZ);

      MAC1_Raw : Long_Long_Integer;
      MAC2_Raw : Long_Long_Integer;
      MAC3_Raw : Long_Long_Integer;

      MAC1 : Long_Long_Integer;
      MAC2 : Long_Long_Integer;
      MAC3 : Long_Long_Integer;

      SZ3_Value : Long_Long_Integer;

      H_Value   : constant Long_Long_Integer :=
        Long_Long_Integer (GTE.H and 16#0000_FFFF#);

      OFX_Value : constant Long_Long_Integer :=
        Signed_32 (GTE.OFX);

      OFY_Value : constant Long_Long_Integer :=
        Signed_32 (GTE.OFY);

      DQA_Value : constant Long_Long_Integer :=
        Signed_16 (GTE.DQA);

      DQB_Value : constant Long_Long_Integer :=
        Signed_32 (GTE.DQB);

      Perspective : Long_Long_Integer;

      MAC0 : Long_Long_Integer;

   begin

      -- A new GTE command clears the calculation flags.
      GTE.FLAG := 0;

      -- -------------------------------------------------------
      -- Rotation + translation
      -- -------------------------------------------------------

      MAC1_Raw :=
        TRX * 16#1000#
        + RT11 * VX
        + RT12 * VY
        + RT13 * VZ;

      MAC2_Raw :=
        TRY * 16#1000#
        + RT21 * VX
        + RT22 * VY
        + RT23 * VZ;

      MAC3_Raw :=
        TRZ * 16#1000#
        + RT31 * VX
        + RT32 * VY
        + RT33 * VZ;

      -- -------------------------------------------------------
      -- MAC registers
      -- -------------------------------------------------------

      MAC1 := SAR (MAC1_Raw, SF * 12);
      MAC2 := SAR (MAC2_Raw, SF * 12);
      MAC3 := SAR (MAC3_Raw, SF * 12);

      GTE.MAC1 := To_Word32 (MAC1);
      GTE.MAC2 := To_Word32 (MAC2);
      GTE.MAC3 := To_Word32 (MAC3);

      -- -------------------------------------------------------
      -- IR registers
      -- -------------------------------------------------------

      GTE.IR1 :=
        Saturate_IR (GTE, MAC1, 24, LM);

      GTE.IR2 :=
        Saturate_IR (GTE, MAC2, 23, LM);

      GTE.IR3 :=
        Saturate_IR (GTE, MAC3, 22, LM);

      -- -------------------------------------------------------
      -- SZ FIFO
      -- -------------------------------------------------------

      SZ3_Value :=
  SAR (MAC3_Raw, 12);

      GTE.SZ0 := GTE.SZ1;
      GTE.SZ1 := GTE.SZ2;
      GTE.SZ2 := GTE.SZ3;

      GTE.SZ3 :=
        Saturate_SZ3 (GTE, SZ3_Value);

      SZ3_Value :=
        Long_Long_Integer
          (GTE.SZ3 and 16#0000_FFFF#);

      -- -------------------------------------------------------
      -- Perspective division
      -- -------------------------------------------------------

      Perspective :=
        Divide_Perspective
          (GTE, H_Value, SZ3_Value);

      -- -------------------------------------------------------
      -- SX2
      -- -------------------------------------------------------

      MAC0 :=
        Perspective * Signed_16 (GTE.IR1)
        + OFX_Value;

      GTE.MAC0 := To_Word32 (MAC0);

      GTE.SX0 := GTE.SX1;
      GTE.SY0 := GTE.SY1;
      GTE.SX1 := GTE.SX2;
      GTE.SY1 := GTE.SY2;

      GTE.SX2 :=
        Saturate_Screen
          (GTE, SAR (MAC0, 16), 14);

      -- -------------------------------------------------------
      -- SY2
      -- -------------------------------------------------------

      MAC0 :=
        Perspective * Signed_16 (GTE.IR2)
        + OFY_Value;

      GTE.MAC0 := To_Word32 (MAC0);

      GTE.SY2 :=
        Saturate_Screen
          (GTE, SAR (MAC0, 16), 13);

      -- -------------------------------------------------------
      -- Depth cue
      -- -------------------------------------------------------

      MAC0 :=
        Perspective * DQA_Value
        + DQB_Value;

      GTE.MAC0 := To_Word32 (MAC0);

      GTE.IR0 :=
        To_Word32
          (Long_Long_Integer'Min
             (16#1000#,
              Long_Long_Integer'Max
                (0,
                 SAR (MAC0, 12))));

      if SAR (MAC0, 12) < 0
        or else SAR (MAC0, 12) > 16#1000#
      then
         Set_Flag (GTE, 12);
      end if;

   end Execute_RTPS;

      procedure Execute_MVMVA
     (GTE  : in out PSX.GTE.GTE_State;
      Inst : PSX.GTE.Instruction.Instruction)
   is
      use type Interfaces.Unsigned_32;

      SF : constant Boolean :=
        PSX.GTE.Instruction.Sf (Inst) /= 0;

      LM : constant Boolean :=
        PSX.GTE.Instruction.Lm (Inst) /= 0;

      VX : Long_Long_Integer;
      VY : Long_Long_Integer;
      VZ : Long_Long_Integer;

      MAC1_Raw : Long_Long_Integer;
      MAC2_Raw : Long_Long_Integer;
      MAC3_Raw : Long_Long_Integer;

      MAC1_Scaled : Long_Long_Integer;
      MAC2_Scaled : Long_Long_Integer;
      MAC3_Scaled : Long_Long_Integer;

      Matrix_11 : Long_Long_Integer;
      Matrix_12 : Long_Long_Integer;
      Matrix_13 : Long_Long_Integer;
      Matrix_21 : Long_Long_Integer;
      Matrix_22 : Long_Long_Integer;
      Matrix_23 : Long_Long_Integer;
      Matrix_31 : Long_Long_Integer;
      Matrix_32 : Long_Long_Integer;
      Matrix_33 : Long_Long_Integer;

      TX : Long_Long_Integer;
      TY : Long_Long_Integer;
      TZ : Long_Long_Integer;

   begin
      -- MVMVA currently starts with the RT matrix.
      Matrix_11 := Signed_16 (GTE.RT11);
      Matrix_12 := Signed_16 (GTE.RT12);
      Matrix_13 := Signed_16 (GTE.RT13);

      Matrix_21 := Signed_16 (GTE.RT21);
      Matrix_22 := Signed_16 (GTE.RT22);
      Matrix_23 := Signed_16 (GTE.RT23);

      Matrix_31 := Signed_16 (GTE.RT31);
      Matrix_32 := Signed_16 (GTE.RT32);
      Matrix_33 := Signed_16 (GTE.RT33);

      -- V = 0 -> V0
      VX := Signed_16 (GTE.V0_X);
      VY := Signed_16 (GTE.V0_Y);
      VZ := Signed_16 (GTE.V0_Z);

      -- CV = 0 -> translation vector TR.
      TX := Signed_32 (GTE.TRX);
      TY := Signed_32 (GTE.TRY);
      TZ := Signed_32 (GTE.TRZ);

      -- Matrix * vector + translation << 12.
      MAC1_Raw :=
        TX * 16#1000# +
        Matrix_11 * VX +
        Matrix_12 * VY +
        Matrix_13 * VZ;

      MAC2_Raw :=
        TY * 16#1000# +
        Matrix_21 * VX +
        Matrix_22 * VY +
        Matrix_23 * VZ;

      MAC3_Raw :=
        TZ * 16#1000# +
        Matrix_31 * VX +
        Matrix_32 * VY +
        Matrix_33 * VZ;

      if SF then
         MAC1_Scaled := SAR (MAC1_Raw, 12);
         MAC2_Scaled := SAR (MAC2_Raw, 12);
         MAC3_Scaled := SAR (MAC3_Raw, 12);
      else
         MAC1_Scaled := MAC1_Raw;
         MAC2_Scaled := MAC2_Raw;
         MAC3_Scaled := MAC3_Raw;
      end if;

      GTE.MAC1 := To_Word32 (MAC1_Scaled);
      GTE.MAC2 := To_Word32 (MAC2_Scaled);
      GTE.MAC3 := To_Word32 (MAC3_Scaled);

            GTE.IR1 :=
        Saturate_IR (GTE, MAC1_Scaled, 24, LM);

      GTE.IR2 :=
        Saturate_IR (GTE, MAC2_Scaled, 23, LM);

      GTE.IR3 :=
        Saturate_IR (GTE, MAC3_Scaled, 22, LM);
   end Execute_MVMVA;


   procedure Execute
     (GTE  : in out PSX.GTE.GTE_State;
      Inst : PSX.GTE.Instruction.Instruction) is

      Command : constant Word32 :=
        PSX.GTE.Instruction.Command (Inst);

   begin

            case Command is
         when 1 =>
            Execute_RTPS (GTE, Inst);

         when 12 =>
            Execute_MVMVA (GTE, Inst);

         when 16#30# =>
            Execute_RTPT (GTE, Inst);

         when others =>
            null;
      end case;

   end Execute;

end PSX.GTE.Execute;