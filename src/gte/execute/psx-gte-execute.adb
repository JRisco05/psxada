with PSX.Types;
with Interfaces;
with Ada.Text_IO; use Ada.Text_IO;

package body PSX.GTE.Execute is

   use type Interfaces.Integer_64;
   subtype Word32 is PSX.Types.Word32;

   function Signed_16 (Value : Word32) return Long_Long_Integer is
      V : constant Long_Long_Integer :=
        Long_Long_Integer (Value and 16#0000_FFFF#);
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
         return Long_Long_Integer (Value) - 16#1_0000_0000#;
      else
         return Long_Long_Integer (Value);
      end if;
   end Signed_32;

   function To_Word32 (Value : Long_Long_Integer) return Word32 is
   begin
      return Word32 (Interfaces.Unsigned_32 (Value mod 16#1_0000_0000#));
   end To_Word32;

   function SAR
     (Value : Long_Long_Integer; Amount : Natural) return Long_Long_Integer
   is
      Divisor : constant Long_Long_Integer := 2 ** Amount;
   begin
      if Value >= 0 then
         return Value / Divisor;
      else
         return -(((-Value) + Divisor - 1) / Divisor);
      end if;
   end SAR;

   procedure Set_Flag (GTE : in out PSX.GTE.GTE_State; Bit : Natural) is
   begin
      GTE.FLAG := GTE.FLAG or Interfaces.Shift_Left (Word32 (1), Bit);
   end Set_Flag;

   function Saturate_IR
     (GTE   : in out PSX.GTE.GTE_State;
      Value : Long_Long_Integer;
      Bit   : Natural;
      LM    : Boolean) return Word32
   is
      Min_Value : constant Long_Long_Integer := (if LM then 0 else -32_768);

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

   function Saturate_IR_RTPS_IR3
     (GTE        : in out PSX.GTE.GTE_State;
      Value      : Long_Long_Integer;
      Flag_Value : Long_Long_Integer;
      Bit        : Natural;
      LM         : Boolean) return Word32
   is
      Result : Long_Long_Integer := Value;
   begin
      -- El valor almacenado en IR3 respeta LM.
      if Result > 32_767 then
         Result := 32_767;
      elsif Result < (if LM then 0 else -32_768) then
         Result := (if LM then 0 else -32_768);
      end if;

      -- FLAG.22 en RTPS/RTPT se evalúa sobre el
      -- resultado correspondiente a MAC3 SAR (SF*12).
      if Flag_Value > 32_767 or else Flag_Value < -32_768 then
         Set_Flag (GTE, Bit);
      end if;

      return To_Word32 (Result);
   end Saturate_IR_RTPS_IR3;

   function Saturate_SZ3
     (GTE : in out PSX.GTE.GTE_State; Value : Long_Long_Integer) return Word32
   is

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
     (GTE : in out PSX.GTE.GTE_State; Value : Long_Long_Integer; Bit : Natural)
      return Word32
   is

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
      SZ3 : Long_Long_Integer) return Long_Long_Integer
   is
      Z      : Natural;
      N      : Long_Long_Integer;
      D      : Long_Long_Integer;
      U      : Long_Long_Integer;
      Result : Long_Long_Integer;

      function Count_Leading_Zeros (Value : Long_Long_Integer) return Natural
      is
         V     : Long_Long_Integer := Value;
         Count : Natural := 0;
      begin
         while V < 16#8000# loop
            V := V * 2;
            Count := Count + 1;
         end loop;

         return Count;
      end Count_Leading_Zeros;

      function UNR_Table (Index : Natural) return Long_Long_Integer is
         I     : constant Long_Long_Integer := Long_Long_Integer (Index);
         Value : Long_Long_Integer;
      begin
         Value := ((16#40_000# / (I + 16#100#)) + 1) / 2 - 16#101#;

         if Value < 0 then
            return 0;
         else
            return Value;
         end if;
      end UNR_Table;

   begin
      -- Perspective division overflow.
      -- The GTE overflows when H >= 2 * SZ3.
      if SZ3 <= 0 or else H >= SZ3 * 2 then
         Set_Flag (GTE, 17);
         Set_Flag (GTE, 31);
         return 16#1_FFFF#;
      end if;

      -- Normalize SZ3 to 8000h..FFFFh.
      Z := Count_Leading_Zeros (SZ3);

      N := H * (2 ** Z);
      D := SZ3 * (2 ** Z);

      -- Initial reciprocal approximation.
      U := UNR_Table (Natural ((D - 16#7FC0#) / 128)) + 16#101#;

      -- First Newton-Raphson refinement.
      D := (16#20_00080# - D * U) / 256;

      -- Second Newton-Raphson refinement.
      D := (16#000080# + D * U) / 256;

      -- Final fixed-point multiplication.
      Result := ((N * D) + 16#8000#) / 16#1_0000#;

      -- The UNR result itself is saturated here.
      if Result > 16#1_FFFF# then
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
      LM  : Boolean)
   is

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

      OFX_Value : constant Long_Long_Integer := Signed_32 (GTE.OFX);

      OFY_Value : constant Long_Long_Integer := Signed_32 (GTE.OFY);

      DQA_Value : constant Long_Long_Integer := Signed_16 (GTE.DQA);

      DQB_Value : constant Long_Long_Integer := Signed_32 (GTE.DQB);

      MAC1_Raw : Long_Long_Integer;
      MAC2_Raw : Long_Long_Integer;
      MAC3_Raw : Long_Long_Integer;

      MAC1 : Long_Long_Integer;
      MAC2 : Long_Long_Integer;
      MAC3 : Long_Long_Integer;

      SZ3_Value   : Long_Long_Integer;
      Perspective : Long_Long_Integer;
      MAC0        : Long_Long_Integer;

   begin
      MAC1_Raw := TRX * 16#1000# + RT11 * VX + RT12 * VY + RT13 * VZ;

      MAC2_Raw := TRY * 16#1000# + RT21 * VX + RT22 * VY + RT23 * VZ;

      MAC3_Raw := TRZ * 16#1000# + RT31 * VX + RT32 * VY + RT33 * VZ;

      -- MAC1..MAC3 overflow detection.
      if MAC1_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 30);
      elsif MAC1_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 27);
      end if;

      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      elsif MAC2_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 26);
      end if;

      if MAC3_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 28);
      elsif MAC3_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 25);
      end if;

      MAC1 := SAR (MAC1_Raw, SF * 12);
      MAC2 := SAR (MAC2_Raw, SF * 12);
      MAC3 := SAR (MAC3_Raw, SF * 12);

      GTE.MAC1 := To_Word32 (MAC1);
      GTE.MAC2 := To_Word32 (MAC2);
      GTE.MAC3 := To_Word32 (MAC3);

      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);

      --  Desplazamiento del FIFO SZ.
      GTE.SZ0 := GTE.SZ1;
      GTE.SZ1 := GTE.SZ2;
      GTE.SZ2 := GTE.SZ3;

      SZ3_Value := SAR (MAC3_Raw, 12);

      GTE.SZ3 := Saturate_SZ3 (GTE, SZ3_Value);

      SZ3_Value := Long_Long_Integer (GTE.SZ3 and 16#0000_FFFF#);

      Perspective := Divide_Perspective (GTE, H_Value, SZ3_Value);

      --  FIFO SXY.
      GTE.SX0 := GTE.SX1;
      GTE.SY0 := GTE.SY1;

      GTE.SX1 := GTE.SX2;
      GTE.SY1 := GTE.SY2;

      MAC0 := Perspective * Signed_16 (GTE.IR1) + OFX_Value;

      GTE.MAC0 := To_Word32 (MAC0);

      GTE.SX2 := Saturate_Screen (GTE, SAR (MAC0, 16), 14);

      MAC0 := Perspective * Signed_16 (GTE.IR2) + OFY_Value;

      GTE.MAC0 := To_Word32 (MAC0);

      GTE.SY2 := Saturate_Screen (GTE, SAR (MAC0, 16), 13);

      MAC0 := Perspective * DQA_Value + DQB_Value;

      GTE.MAC0 := To_Word32 (MAC0);

      GTE.IR0 :=
        To_Word32
          (Long_Long_Integer'Min
             (16#1000#, Long_Long_Integer'Max (0, SAR (MAC0, 12))));

      if SAR (MAC0, 12) < 0 or else SAR (MAC0, 12) > 16#1000# then
         Set_Flag (GTE, 12);
      end if;
   end Transform_Vertex;

   procedure Execute_RTPT
     (GTE : in out PSX.GTE.GTE_State; Inst : PSX.GTE.Instruction.Instruction)
   is

      LM : constant Boolean := PSX.GTE.Instruction.Lm (Inst) /= 0;

      SF : constant Natural := Natural (PSX.GTE.Instruction.Sf (Inst));

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
     (GTE : in out PSX.GTE.GTE_State; Inst : PSX.GTE.Instruction.Instruction)
   is

      LM : constant Boolean := PSX.GTE.Instruction.Lm (Inst) /= 0;

      SF : constant Natural := Natural (PSX.GTE.Instruction.Sf (Inst));

      VX : constant Long_Long_Integer := Signed_16 (GTE.V0_X);

      VY : constant Long_Long_Integer := Signed_16 (GTE.V0_Y);

      VZ : constant Long_Long_Integer := Signed_16 (GTE.V0_Z);

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

      H_Value : constant Long_Long_Integer :=
        Long_Long_Integer (GTE.H and 16#0000_FFFF#);

      OFX_Value : constant Long_Long_Integer := Signed_32 (GTE.OFX);

      OFY_Value : constant Long_Long_Integer := Signed_32 (GTE.OFY);

      DQA_Value : constant Long_Long_Integer := Signed_16 (GTE.DQA);

      DQB_Value : constant Long_Long_Integer := Signed_32 (GTE.DQB);

      Perspective : Long_Long_Integer;

      MAC0 : Long_Long_Integer;

   begin

      --  A new GTE command clears the calculation flags.
      GTE.FLAG := 0;

      --  -------------------------------------------------------
      --  Rotation + translation
      --  -------------------------------------------------------

      MAC1_Raw := TRX * 16#1000# + RT11 * VX + RT12 * VY + RT13 * VZ;

      MAC2_Raw := TRY * 16#1000# + RT21 * VX + RT22 * VY + RT23 * VZ;

      MAC3_Raw := TRZ * 16#1000# + RT31 * VX + RT32 * VY + RT33 * VZ;

      -- MAC1..MAC3 overflow detection.
      if MAC1_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 30);
      elsif MAC1_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 27);
      end if;

      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      elsif MAC2_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 26);
      end if;

      if MAC3_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 28);
      elsif MAC3_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 25);
      end if;

      -- -------------------------------------------------------
      -- MAC registers
      -- -------------------------------------------------------

      MAC1 := SAR (MAC1_Raw, SF * 12);
      MAC2 := SAR (MAC2_Raw, SF * 12);
      MAC3 := SAR (MAC3_Raw, SF * 12);

      GTE.MAC1 := To_Word32 (MAC1);
      GTE.MAC2 := To_Word32 (MAC2);
      GTE.MAC3 := To_Word32 (MAC3);

      --  -------------------------------------------------------
      --  IR registers
      --  -------------------------------------------------------

      GTE.IR1 := Saturate_IR (GTE, Signed_32 (To_Word32 (MAC1)), 24, LM);

      GTE.IR2 := Saturate_IR (GTE, Signed_32 (To_Word32 (MAC2)), 23, LM);

      GTE.IR3 :=
        Saturate_IR_RTPS_IR3
          (GTE,
           Signed_32 (To_Word32 (MAC3)),
           (if SF = 0
            then SAR (MAC3_Raw, 12)
            else Signed_32 (To_Word32 (MAC3))),
           22,
           LM);

      --  -------------------------------------------------------
      --  SZ FIFO
      --  -------------------------------------------------------

      if SF = 0 then
         SZ3_Value := SAR (MAC3_Raw, 12);
      else
         SZ3_Value := Signed_32 (To_Word32 (MAC3));
      end if;

      GTE.SZ0 := GTE.SZ1;
      GTE.SZ1 := GTE.SZ2;
      GTE.SZ2 := GTE.SZ3;

      GTE.SZ3 := Saturate_SZ3 (GTE, SZ3_Value);

      SZ3_Value := Long_Long_Integer (GTE.SZ3 and 16#0000_FFFF#);

      --  -------------------------------------------------------
      --  Perspective division
      --  -------------------------------------------------------

      Perspective := Divide_Perspective (GTE, H_Value, SZ3_Value);

      --  -------------------------------------------------------
      --  SX2
      --  -------------------------------------------------------

      MAC0 := Perspective * Signed_16 (GTE.IR1) + OFX_Value;

      if MAC0 > 2_147_483_647 then
         Set_Flag (GTE, 16);
      elsif MAC0 < -2_147_483_648 then
         Set_Flag (GTE, 15);
      end if;

      GTE.MAC0 := To_Word32 (MAC0);

      GTE.SX0 := GTE.SX1;
      GTE.SY0 := GTE.SY1;
      GTE.SX1 := GTE.SX2;
      GTE.SY1 := GTE.SY2;

      GTE.SX2 := Saturate_Screen (GTE, SAR (MAC0, 16), 14);

      --  -------------------------------------------------------
      --  SY2
      --  -------------------------------------------------------

      MAC0 := Perspective * Signed_16 (GTE.IR2) + OFY_Value;

      if MAC0 > 2_147_483_647 then
         Set_Flag (GTE, 16);
      elsif MAC0 < -2_147_483_648 then
         Set_Flag (GTE, 15);
      end if;

      GTE.MAC0 := To_Word32 (MAC0);

      GTE.SY2 := Saturate_Screen (GTE, SAR (MAC0, 16), 13);

      --  -------------------------------------------------------
      --  Depth cue
      --  -------------------------------------------------------

      MAC0 := Perspective * DQA_Value + DQB_Value;

      if MAC0 > 2_147_483_647 then
         Set_Flag (GTE, 16);
      elsif MAC0 < -2_147_483_648 then
         Set_Flag (GTE, 15);
      end if;

      GTE.MAC0 := To_Word32 (MAC0);

      GTE.IR0 :=
        To_Word32
          (Long_Long_Integer'Min
             (16#1000#, Long_Long_Integer'Max (0, SAR (MAC0, 12))));

      if SAR (MAC0, 12) < 0 or else SAR (MAC0, 12) > 16#1000# then
         Set_Flag (GTE, 12);
      end if;

      --  -------------------------------------------------------
      --  FLAG global
      --  -------------------------------------------------------

      if (GTE.FLAG and 16#7F87_E000#) /= 0 then
         GTE.FLAG := GTE.FLAG or 16#8000_0000#;
      end if;

   end Execute_RTPS;

   procedure Execute_MVMVA
     (GTE : in out PSX.GTE.GTE_State; Inst : PSX.GTE.Instruction.Instruction)
   is
      SF : constant Boolean := PSX.GTE.Instruction.Sf (Inst) /= 0;

      LM : constant Boolean := PSX.GTE.Instruction.Lm (Inst) /= 0;

      VX : Long_Long_Integer;
      VY : Long_Long_Integer;
      VZ : Long_Long_Integer;

      MAC1_Raw : Long_Long_Integer;
      MAC2_Raw : Long_Long_Integer;
      MAC3_Raw : Long_Long_Integer;

      MAC1 : Long_Long_Integer;
      MAC2 : Long_Long_Integer;
      MAC3 : Long_Long_Integer;

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
      GTE.FLAG := 0;

      --  ----------------------------------------------------
      --  Matriz RT
      --  ----------------------------------------------------

      case PSX.GTE.Instruction.Mx (Inst) is

         when 0      =>
            -- Rotation matrix
            Matrix_11 := Signed_16 (GTE.RT11);
            Matrix_12 := Signed_16 (GTE.RT12);
            Matrix_13 := Signed_16 (GTE.RT13);
            Matrix_21 := Signed_16 (GTE.RT21);
            Matrix_22 := Signed_16 (GTE.RT22);
            Matrix_23 := Signed_16 (GTE.RT23);
            Matrix_31 := Signed_16 (GTE.RT31);
            Matrix_32 := Signed_16 (GTE.RT32);
            Matrix_33 := Signed_16 (GTE.RT33);

         when 1      =>
            -- Light matrix
            Matrix_11 := Signed_16 (GTE.L11);
            Matrix_12 := Signed_16 (GTE.L12);
            Matrix_13 := Signed_16 (GTE.L13);
            Matrix_21 := Signed_16 (GTE.L21);
            Matrix_22 := Signed_16 (GTE.L22);
            Matrix_23 := Signed_16 (GTE.L23);
            Matrix_31 := Signed_16 (GTE.L31);
            Matrix_32 := Signed_16 (GTE.L32);
            Matrix_33 := Signed_16 (GTE.L33);

         when 2      =>
            -- Color matrix
            Matrix_11 := Signed_16 (GTE.LR1);
            Matrix_12 := Signed_16 (GTE.LR2);
            Matrix_13 := Signed_16 (GTE.LR3);
            Matrix_21 := Signed_16 (GTE.LG1);
            Matrix_22 := Signed_16 (GTE.LG2);
            Matrix_23 := Signed_16 (GTE.LG3);
            Matrix_31 := Signed_16 (GTE.LB1);
            Matrix_32 := Signed_16 (GTE.LB2);
            Matrix_33 := Signed_16 (GTE.LB3);

         when others =>
            -- Color matrix
            Matrix_11 := Signed_16 (GTE.LR1);
            Matrix_12 := Signed_16 (GTE.LR2);
            Matrix_13 := Signed_16 (GTE.LR3);
            Matrix_21 := Signed_16 (GTE.LG1);
            Matrix_22 := Signed_16 (GTE.LG2);
            Matrix_23 := Signed_16 (GTE.LG3);
            Matrix_31 := Signed_16 (GTE.LB1);
            Matrix_32 := Signed_16 (GTE.LB2);
            Matrix_33 := Signed_16 (GTE.LB3);

      end case;

      --  ----------------------------------------------------
      --  Selección del vector
      --  V=0 -> V0
      --  V=1 -> V1
      --  V=2 -> V2
      --  ----------------------------------------------------

      case PSX.GTE.Instruction.V (Inst) is

         when 0      =>
            -- V=0 -> V0
            VX := Signed_16 (GTE.V0_X);
            VY := Signed_16 (GTE.V0_Y);
            VZ := Signed_16 (GTE.V0_Z);

         when 1      =>
            -- V=1 -> V1
            VX := Signed_16 (GTE.V1_X);
            VY := Signed_16 (GTE.V1_Y);
            VZ := Signed_16 (GTE.V1_Z);

         when 2      =>
            -- V=2 -> V2
            VX := Signed_16 (GTE.V2_X);
            VY := Signed_16 (GTE.V2_Y);
            VZ := Signed_16 (GTE.V2_Z);

         when 3      =>
            -- V=3 -> IR vector
            VX := Signed_16 (GTE.IR1);
            VY := Signed_16 (GTE.IR2);
            VZ := Signed_16 (GTE.IR3);

         when others =>
            VX := 0;
            VY := 0;
            VZ := 0;

      end case;

      --  ----------------------------------------------------
      --  Selección del vector de traslación
      --  CV=0 -> TR
      --  CV=1 -> BK
      --  ----------------------------------------------------

      case PSX.GTE.Instruction.Cv (Inst) is

         when 0      =>
            -- Translation vector
            TX := Signed_32 (GTE.TRX);
            TY := Signed_32 (GTE.TRY);
            TZ := Signed_32 (GTE.TRZ);

         when 1      =>
            -- Background color vector
            TX := Signed_32 (GTE.RBK);
            TY := Signed_32 (GTE.GBK);
            TZ := Signed_32 (GTE.BBK);

         when 2      =>
            -- Far color vector
            TX := Signed_32 (GTE.RFC);
            TY := Signed_32 (GTE.GFC);
            TZ := Signed_32 (GTE.BFC);

         when 3      =>
            -- No translation vector
            TX := 0;
            TY := 0;
            TZ := 0;

         when others =>
            TX := 0;
            TY := 0;
            TZ := 0;

      end case;

      --  ----------------------------------------------------
      --  Multiplicación matriz * vector
      --  ----------------------------------------------------

      MAC1_Raw :=
        TX * 16#1000# + Matrix_11 * VX + Matrix_12 * VY + Matrix_13 * VZ;

      MAC2_Raw :=
        TY * 16#1000# + Matrix_21 * VX + Matrix_22 * VY + Matrix_23 * VZ;

      MAC3_Raw :=
        TZ * 16#1000# + Matrix_31 * VX + Matrix_32 * VY + Matrix_33 * VZ;

      if MAC1_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 30);
      elsif MAC1_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 27);
      end if;

      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      elsif MAC2_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 26);
      end if;

      if MAC3_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 28);
      elsif MAC3_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 28);
      end if;

      --  ----------------------------------------------------
      --  SF
      --  SF=0 -> sin desplazamiento
      --  SF=1 -> desplazamiento de 12 bits
      --  ----------------------------------------------------

      if SF then
         MAC1 := SAR (MAC1_Raw, 12);
         MAC2 := SAR (MAC2_Raw, 12);
         MAC3 := SAR (MAC3_Raw, 12);
      else
         MAC1 := MAC1_Raw;
         MAC2 := MAC2_Raw;
         MAC3 := MAC3_Raw;
      end if;

      --  ----------------------------------------------------
      --  MAC
      --  ----------------------------------------------------

      GTE.MAC1 := To_Word32 (MAC1);
      GTE.MAC2 := To_Word32 (MAC2);
      GTE.MAC3 := To_Word32 (MAC3);

      --  ----------------------------------------------------
      --  IR
      --  ----------------------------------------------------

      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);

      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);

      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);

   end Execute_MVMVA;

   procedure Execute_NCLIP (GTE : in out PSX.GTE.GTE_State) is
      -- Convertimos los registros SX y SY a enteros estándar de 32 bits con signo
      X0 : constant Interfaces.Integer_32 :=
        Interfaces.Integer_32 (Signed_16 (GTE.SX0));
      Y0 : constant Interfaces.Integer_32 :=
        Interfaces.Integer_32 (Signed_16 (GTE.SY0));

      X1 : constant Interfaces.Integer_32 :=
        Interfaces.Integer_32 (Signed_16 (GTE.SX1));
      Y1 : constant Interfaces.Integer_32 :=
        Interfaces.Integer_32 (Signed_16 (GTE.SY1));

      X2 : constant Interfaces.Integer_32 :=
        Interfaces.Integer_32 (Signed_16 (GTE.SX2));
      Y2 : constant Interfaces.Integer_32 :=
        Interfaces.Integer_32 (Signed_16 (GTE.SY2));

      -- Usamos un entero de 64 bits para calcular el área intermedia sin perder datos
      MAC0_Raw : Interfaces.Integer_64;
   begin
      -- 🌟 SOLUCIÓN: Limpiamos el FLAG al entrar (Quitamos el valor estático)
      GTE.FLAG := 0;

      -- Fórmula matemática nativa LLE de la PS1 para el producto cruzado 2D
      MAC0_Raw :=
        Interfaces.Integer_64 (X0) * Interfaces.Integer_64 (Y1)
        + Interfaces.Integer_64 (X1) * Interfaces.Integer_64 (Y2)
        + Interfaces.Integer_64 (X2) * Interfaces.Integer_64 (Y0)
        - Interfaces.Integer_64 (X0) * Interfaces.Integer_64 (Y2)
        - Interfaces.Integer_64 (X1) * Interfaces.Integer_64 (Y0)
        - Interfaces.Integer_64 (X2) * Interfaces.Integer_64 (Y1);

      -- NCLIP almacena los 32 bits bajos del resultado en MAC0.
      GTE.MAC0 := To_Word32 (Long_Long_Integer (MAC0_Raw));

      -- 🌟 EVALUACIÓN DE BANDERAS DINÁMICAS (Solo si el hardware real desborda):
      -- Si el área calculada supera los límites físicos de 32 bits con signo,
      -- entonces activamos los bits correspondientes en el FLAG de la PS1.
      if MAC0_Raw > 2147483647 then
         Set_Flag (GTE, 16); -- Bit 16: MAC0 Positive Overflow
      elsif MAC0_Raw < -2147483648 then
         Set_Flag (GTE, 15); -- Bit 15: MAC0 Negative Overflow
      end if;

      -- Si se levantó un error de desbordamiento, encendemos el bit 31 global
      if GTE.FLAG /= 0 then
         GTE.FLAG := GTE.FLAG or 16#8000_0000#;
      end if;

   end Execute_NCLIP;

   procedure Execute_AVSZ3 (GTE : in out PSX.GTE.GTE_State) is
      SZ1 : constant Long_Long_Integer :=
        Long_Long_Integer (GTE.SZ1 and 16#0000_FFFF#);

      SZ2 : constant Long_Long_Integer :=
        Long_Long_Integer (GTE.SZ2 and 16#0000_FFFF#);

      SZ3 : constant Long_Long_Integer :=
        Long_Long_Integer (GTE.SZ3 and 16#0000_FFFF#);

      ZSF3 : constant Long_Long_Integer := Signed_16 (GTE.ZSF3);

      Sum       : Long_Long_Integer;
      MAC0_Raw  : Long_Long_Integer;
      OTZ_Value : Long_Long_Integer;

   begin
      GTE.FLAG := 0;

      Sum := SZ1 + SZ2 + SZ3;

      MAC0_Raw := ZSF3 * Sum;

      -- MAC0 overflow
      if MAC0_Raw > 2_147_483_647 then
         Set_Flag (GTE, 16);
      elsif MAC0_Raw < -2_147_483_648 then
         Set_Flag (GTE, 15);
      end if;

      GTE.MAC0 := To_Word32 (MAC0_Raw);

      OTZ_Value := SAR (MAC0_Raw, 12);

      if OTZ_Value < 0 then
         OTZ_Value := 0;
         Set_Flag (GTE, 18);

      elsif OTZ_Value > 16#FFFF# then
         OTZ_Value := 16#FFFF#;
         Set_Flag (GTE, 18);
      end if;

      GTE.OTZ := To_Word32 (OTZ_Value);

   end Execute_AVSZ3;

   procedure Execute_AVSZ4 (GTE : in out PSX.GTE.GTE_State) is
      SZ0 : constant Long_Long_Integer :=
        Long_Long_Integer (GTE.SZ0 and 16#0000_FFFF#);

      SZ1 : constant Long_Long_Integer :=
        Long_Long_Integer (GTE.SZ1 and 16#0000_FFFF#);

      SZ2 : constant Long_Long_Integer :=
        Long_Long_Integer (GTE.SZ2 and 16#0000_FFFF#);

      SZ3 : constant Long_Long_Integer :=
        Long_Long_Integer (GTE.SZ3 and 16#0000_FFFF#);

      ZSF4 : constant Long_Long_Integer := Signed_16 (GTE.ZSF4);

      Sum       : Long_Long_Integer;
      MAC0_Raw  : Long_Long_Integer;
      OTZ_Value : Long_Long_Integer;

   begin
      GTE.FLAG := 0;

      Sum := SZ0 + SZ1 + SZ2 + SZ3;

      MAC0_Raw := ZSF4 * Sum;

      GTE.MAC0 := To_Word32 (MAC0_Raw);

      OTZ_Value := SAR (MAC0_Raw, 12);

      if OTZ_Value < 0 then
         OTZ_Value := 0;
         Set_Flag (GTE, 18);

      elsif OTZ_Value > 16#FFFF# then
         OTZ_Value := 16#FFFF#;
         Set_Flag (GTE, 18);
      end if;

      GTE.OTZ := To_Word32 (OTZ_Value);

   end Execute_AVSZ4;

   procedure Execute_OP
     (GTE : in out PSX.GTE.GTE_State; Inst : PSX.GTE.Instruction.Instruction)
   is
      SF : constant Boolean := PSX.GTE.Instruction.Sf (Inst) /= 0;

      LM : constant Boolean := PSX.GTE.Instruction.Lm (Inst) /= 0;

      IR1 : constant Long_Long_Integer := Signed_16 (GTE.IR1);

      IR2 : constant Long_Long_Integer := Signed_16 (GTE.IR2);

      IR3 : constant Long_Long_Integer := Signed_16 (GTE.IR3);

      RT11 : constant Long_Long_Integer := Signed_16 (GTE.RT11);
      RT22 : constant Long_Long_Integer := Signed_16 (GTE.RT22);
      RT33 : constant Long_Long_Integer := Signed_16 (GTE.RT33);

      MAC1_Raw : Long_Long_Integer;
      MAC2_Raw : Long_Long_Integer;
      MAC3_Raw : Long_Long_Integer;

      MAC1 : Long_Long_Integer;
      MAC2 : Long_Long_Integer;
      MAC3 : Long_Long_Integer;

   begin
      GTE.FLAG := 0;

      MAC1_Raw := RT33 * IR2 - RT22 * IR3;
      MAC2_Raw := RT11 * IR3 - RT33 * IR1;
      MAC3_Raw := RT22 * IR1 - RT11 * IR2;

      if MAC1_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 30);
      elsif MAC1_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 27);
      end if;

      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      elsif MAC2_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 26);
      end if;

      if MAC3_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 28);
      elsif MAC3_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 25);
      end if;

      if SF then
         MAC1 := SAR (MAC1_Raw, 12);
         MAC2 := SAR (MAC2_Raw, 12);
         MAC3 := SAR (MAC3_Raw, 12);
      else
         MAC1 := MAC1_Raw;
         MAC2 := MAC2_Raw;
         MAC3 := MAC3_Raw;
      end if;

      GTE.MAC1 := To_Word32 (MAC1);
      GTE.MAC2 := To_Word32 (MAC2);
      GTE.MAC3 := To_Word32 (MAC3);

      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);

   end Execute_OP;

   procedure Execute_DPCS
     (GTE : in out PSX.GTE.GTE_State; Inst : PSX.GTE.Instruction.Instruction)
   is
      SF : constant Boolean := PSX.GTE.Instruction.Sf (Inst) /= 0;

      LM : constant Boolean := PSX.GTE.Instruction.Lm (Inst) /= 0;

      IR0 : constant Long_Long_Integer := Signed_16 (GTE.IR0);

      R : constant Long_Long_Integer :=
        Long_Long_Integer (GTE.RGBC and 16#0000_00FF#);

      G : constant Long_Long_Integer :=
        Long_Long_Integer
          (Interfaces.Shift_Right (GTE.RGBC, 8) and 16#0000_00FF#);

      B : constant Long_Long_Integer :=
        Long_Long_Integer
          (Interfaces.Shift_Right (GTE.RGBC, 16) and 16#0000_00FF#);

      CODE : constant Word32 := Interfaces.Shift_Right (GTE.RGBC, 24);

      FC_R : constant Long_Long_Integer := Signed_32 (GTE.RFC);

      FC_G : constant Long_Long_Integer := Signed_32 (GTE.GFC);

      FC_B : constant Long_Long_Integer := Signed_32 (GTE.BFC);

      MAC1_Base : constant Long_Long_Integer := R * 16#1_0000#;

      MAC2_Base : constant Long_Long_Integer := G * 16#1_0000#;

      MAC3_Base : constant Long_Long_Integer := B * 16#1_0000#;

      Delta_Raw : Long_Long_Integer;
      Delta_Gaw : Long_Long_Integer;
      Delta_Baw : Long_Long_Integer;

      Delta_R : Long_Long_Integer;
      Delta_G : Long_Long_Integer;
      Delta_B : Long_Long_Integer;

      MAC1_Raw : Long_Long_Integer;
      MAC2_Raw : Long_Long_Integer;
      MAC3_Raw : Long_Long_Integer;

      MAC1 : Long_Long_Integer;
      MAC2 : Long_Long_Integer;
      MAC3 : Long_Long_Integer;

      RGB_Raw : Long_Long_Integer;
      RGB_Gaw : Long_Long_Integer;
      RGB_Baw : Long_Long_Integer;

      RGB_R : Long_Long_Integer;
      RGB_G : Long_Long_Integer;
      RGB_B : Long_Long_Integer;

      New_RGB2 : Word32;

   begin
      GTE.FLAG := 0;

      Delta_Raw := (FC_R * 16#1000#) - MAC1_Base;

      Delta_Gaw := (FC_G * 16#1000#) - MAC2_Base;

      Delta_Baw := (FC_B * 16#1000#) - MAC3_Base;

      if Delta_Raw > 32767 then
         Delta_R := 32767;
      elsif Delta_Raw < -32768 then
         Delta_R := -32768;
      else
         Delta_R := Delta_Raw;
      end if;

      if Delta_Gaw > 32767 then
         Delta_G := 32767;
      elsif Delta_Gaw < -32768 then
         Delta_G := -32768;
      else
         Delta_G := Delta_Gaw;
      end if;

      if Delta_Baw > 32767 then
         Delta_B := 32767;
      elsif Delta_Baw < -32768 then
         Delta_B := -32768;
      else
         Delta_B := Delta_Baw;
      end if;

      MAC1_Raw := MAC1_Base + Delta_R * IR0;

      MAC2_Raw := MAC2_Base + Delta_G * IR0;

      MAC3_Raw := MAC3_Base + Delta_B * IR0;

      if MAC1_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 30);
      elsif MAC1_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 27);
      end if;

      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      elsif MAC2_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 26);
      end if;

      if MAC3_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 28);
      elsif MAC3_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 25);
      end if;

      if SF then
         MAC1 := SAR (MAC1_Raw, 12);
         MAC2 := SAR (MAC2_Raw, 12);
         MAC3 := SAR (MAC3_Raw, 12);
      else
         MAC1 := MAC1_Raw;
         MAC2 := MAC2_Raw;
         MAC3 := MAC3_Raw;
      end if;

      GTE.MAC1 := To_Word32 (MAC1);
      GTE.MAC2 := To_Word32 (MAC2);
      GTE.MAC3 := To_Word32 (MAC3);

      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);

      RGB_Raw := SAR (MAC1, 4);
      RGB_Gaw := SAR (MAC2, 4);
      RGB_Baw := SAR (MAC3, 4);

      if RGB_Raw < 0 then
         RGB_R := 0;
         Set_Flag (GTE, 21);
      elsif RGB_Raw > 255 then
         RGB_R := 255;
         Set_Flag (GTE, 21);
      else
         RGB_R := RGB_Raw;
      end if;

      if RGB_Gaw < 0 then
         RGB_G := 0;
         Set_Flag (GTE, 20);
      elsif RGB_Gaw > 255 then
         RGB_G := 255;
         Set_Flag (GTE, 20);
      else
         RGB_G := RGB_Gaw;
      end if;

      if RGB_Baw < 0 then
         RGB_B := 0;
         Set_Flag (GTE, 19);
      elsif RGB_Baw > 255 then
         RGB_B := 255;
         Set_Flag (GTE, 19);
      else
         RGB_B := RGB_Baw;
      end if;

      GTE.RGB0 := GTE.RGB1;
      GTE.RGB1 := GTE.RGB2;

      New_RGB2 :=
        Word32 (RGB_R)
        or Interfaces.Shift_Left (Word32 (RGB_G), 8)
        or Interfaces.Shift_Left (Word32 (RGB_B), 16)
        or Interfaces.Shift_Left (CODE, 24);

      GTE.RGB2 := New_RGB2;

   end Execute_DPCS;

   procedure Execute_INTPL
     (GTE : in out PSX.GTE.GTE_State; Inst : PSX.GTE.Instruction.Instruction)
   is
      SF : constant Boolean := PSX.GTE.Instruction.Sf (Inst) /= 0;

      LM : constant Boolean := PSX.GTE.Instruction.Lm (Inst) /= 0;

      IR0 : constant Long_Long_Integer := Signed_16 (GTE.IR0);

      IR1 : constant Long_Long_Integer := Signed_16 (GTE.IR1);

      IR2 : constant Long_Long_Integer := Signed_16 (GTE.IR2);

      IR3 : constant Long_Long_Integer := Signed_16 (GTE.IR3);

      FC_R : constant Long_Long_Integer := Signed_32 (GTE.RFC);

      FC_G : constant Long_Long_Integer := Signed_32 (GTE.GFC);

      FC_B : constant Long_Long_Integer := Signed_32 (GTE.BFC);

      Base_R : constant Long_Long_Integer := IR1 * 16#1000#;

      Base_G : constant Long_Long_Integer := IR2 * 16#1000#;

      Base_B : constant Long_Long_Integer := IR3 * 16#1000#;

      Delta_Raw : Long_Long_Integer;
      Delta_Gaw : Long_Long_Integer;
      Delta_Baw : Long_Long_Integer;

      Delta_R : Long_Long_Integer;
      Delta_G : Long_Long_Integer;
      Delta_B : Long_Long_Integer;

      MAC1_Raw : Long_Long_Integer;
      MAC2_Raw : Long_Long_Integer;
      MAC3_Raw : Long_Long_Integer;

      MAC1 : Long_Long_Integer;
      MAC2 : Long_Long_Integer;
      MAC3 : Long_Long_Integer;

      RGB_Raw : Long_Long_Integer;
      RGB_Gaw : Long_Long_Integer;
      RGB_Baw : Long_Long_Integer;

      RGB_R : Long_Long_Integer;
      RGB_G : Long_Long_Integer;
      RGB_B : Long_Long_Integer;

      New_RGB2 : Word32;

   begin
      GTE.FLAG := 0;

      Delta_Raw := (FC_R * 16#1000#) - Base_R;

      Delta_Gaw := (FC_G * 16#1000#) - Base_G;

      Delta_Baw := (FC_B * 16#1000#) - Base_B;

      if SF then
         Delta_R := SAR (Delta_Raw, 12);
         Delta_G := SAR (Delta_Gaw, 12);
         Delta_B := SAR (Delta_Baw, 12);
      else
         Delta_R := Delta_Raw;
         Delta_G := Delta_Gaw;
         Delta_B := Delta_Baw;
      end if;

      if Delta_R > 32767 then
         Delta_R := 32767;
         Set_Flag (GTE, 30);
      elsif Delta_R < -32768 then
         Delta_R := -32768;
         Set_Flag (GTE, 27);
      end if;

      if Delta_G > 32767 then
         Delta_G := 32767;
         Set_Flag (GTE, 29);
      elsif Delta_G < -32768 then
         Delta_G := -32768;
         Set_Flag (GTE, 26);
      end if;

      if Delta_B > 32767 then
         Delta_B := 32767;
         Set_Flag (GTE, 28);
      elsif Delta_B < -32768 then
         Delta_B := -32768;
         Set_Flag (GTE, 25);
      end if;

      MAC1_Raw := Base_R + IR0 * Delta_R;

      MAC2_Raw := Base_G + IR0 * Delta_G;

      MAC3_Raw := Base_B + IR0 * Delta_B;

      if SF then
         MAC1 := SAR (MAC1_Raw, 12);
         MAC2 := SAR (MAC2_Raw, 12);
         MAC3 := SAR (MAC3_Raw, 12);
      else
         MAC1 := MAC1_Raw;
         MAC2 := MAC2_Raw;
         MAC3 := MAC3_Raw;
      end if;

      GTE.MAC1 := To_Word32 (MAC1);
      GTE.MAC2 := To_Word32 (MAC2);
      GTE.MAC3 := To_Word32 (MAC3);

      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);

      RGB_Raw := SAR (MAC1, 4);
      RGB_Gaw := SAR (MAC2, 4);
      RGB_Baw := SAR (MAC3, 4);

      if RGB_Raw < 0 then
         RGB_R := 0;
         Set_Flag (GTE, 21);
      elsif RGB_Raw > 255 then
         RGB_R := 255;
         Set_Flag (GTE, 21);
      else
         RGB_R := RGB_Raw;
      end if;

      if RGB_Gaw < 0 then
         RGB_G := 0;
         Set_Flag (GTE, 20);
      elsif RGB_Gaw > 255 then
         RGB_G := 255;
         Set_Flag (GTE, 20);
      else
         RGB_G := RGB_Gaw;
      end if;

      if RGB_Baw < 0 then
         RGB_B := 0;
         Set_Flag (GTE, 19);
      elsif RGB_Baw > 255 then
         RGB_B := 255;
         Set_Flag (GTE, 19);
      else
         RGB_B := RGB_Baw;
      end if;

      GTE.RGB0 := GTE.RGB1;
      GTE.RGB1 := GTE.RGB2;

      New_RGB2 :=
        Word32 (RGB_R)
        or Interfaces.Shift_Left (Word32 (RGB_G), 8)
        or Interfaces.Shift_Left (Word32 (RGB_B), 16)
        or Interfaces.Shift_Left (Interfaces.Shift_Right (GTE.RGBC, 24), 24);

      GTE.RGB2 := New_RGB2;

   end Execute_INTPL;

   procedure Execute_NCDS
     (GTE : in out PSX.GTE.GTE_State; Inst : PSX.GTE.Instruction.Instruction)
   is
      SF : constant Boolean := PSX.GTE.Instruction.Sf (Inst) /= 0;

      LM : constant Boolean := PSX.GTE.Instruction.Lm (Inst) /= 0;

      VX : constant Long_Long_Integer := Signed_16 (GTE.V0_X);

      VY : constant Long_Long_Integer := Signed_16 (GTE.V0_Y);

      VZ : constant Long_Long_Integer := Signed_16 (GTE.V0_Z);

      IR0 : constant Long_Long_Integer := Signed_16 (GTE.IR0);

      R : constant Long_Long_Integer :=
        Long_Long_Integer (GTE.RGBC and 16#0000_00FF#);

      G : constant Long_Long_Integer :=
        Long_Long_Integer
          (Interfaces.Shift_Right (GTE.RGBC, 8) and 16#0000_00FF#);

      B : constant Long_Long_Integer :=
        Long_Long_Integer
          (Interfaces.Shift_Right (GTE.RGBC, 16) and 16#0000_00FF#);

      CODE : constant Word32 := Interfaces.Shift_Right (GTE.RGBC, 24);

      L11 : constant Long_Long_Integer := Signed_16 (GTE.L11);
      L12 : constant Long_Long_Integer := Signed_16 (GTE.L12);
      L13 : constant Long_Long_Integer := Signed_16 (GTE.L13);

      L21 : constant Long_Long_Integer := Signed_16 (GTE.L21);
      L22 : constant Long_Long_Integer := Signed_16 (GTE.L22);
      L23 : constant Long_Long_Integer := Signed_16 (GTE.L23);

      L31 : constant Long_Long_Integer := Signed_16 (GTE.L31);
      L32 : constant Long_Long_Integer := Signed_16 (GTE.L32);
      L33 : constant Long_Long_Integer := Signed_16 (GTE.L33);

      RBK : constant Long_Long_Integer := Signed_32 (GTE.RBK);
      GBK : constant Long_Long_Integer := Signed_32 (GTE.GBK);
      BBK : constant Long_Long_Integer := Signed_32 (GTE.BBK);

      LR1 : constant Long_Long_Integer := Signed_16 (GTE.LR1);
      LR2 : constant Long_Long_Integer := Signed_16 (GTE.LR2);
      LR3 : constant Long_Long_Integer := Signed_16 (GTE.LR3);

      LG1 : constant Long_Long_Integer := Signed_16 (GTE.LG1);
      LG2 : constant Long_Long_Integer := Signed_16 (GTE.LG2);
      LG3 : constant Long_Long_Integer := Signed_16 (GTE.LG3);

      LB1 : constant Long_Long_Integer := Signed_16 (GTE.LB1);
      LB2 : constant Long_Long_Integer := Signed_16 (GTE.LB2);
      LB3 : constant Long_Long_Integer := Signed_16 (GTE.LB3);

      RFC : constant Long_Long_Integer := Signed_32 (GTE.RFC);
      GFC : constant Long_Long_Integer := Signed_32 (GTE.GFC);
      BFC : constant Long_Long_Integer := Signed_32 (GTE.BFC);

      MAC1_Raw : Long_Long_Integer;
      MAC2_Raw : Long_Long_Integer;
      MAC3_Raw : Long_Long_Integer;

      MAC1 : Long_Long_Integer;
      MAC2 : Long_Long_Integer;
      MAC3 : Long_Long_Integer;

      Color1_Raw : Long_Long_Integer;
      Color2_Raw : Long_Long_Integer;
      Color3_Raw : Long_Long_Integer;

      Delta1_Raw : Long_Long_Integer;
      Delta2_Raw : Long_Long_Integer;
      Delta3_Raw : Long_Long_Integer;

      Delta1 : Long_Long_Integer;
      Delta2 : Long_Long_Integer;
      Delta3 : Long_Long_Integer;

      RGB1 : Long_Long_Integer;
      RGB2 : Long_Long_Integer;
      RGB3 : Long_Long_Integer;

      New_RGB2 : Word32;

   begin
      GTE.FLAG := 0;

      -- First stage: Light matrix * V0.
      MAC1_Raw := L11 * VX + L12 * VY + L13 * VZ;

      MAC2_Raw := L21 * VX + L22 * VY + L23 * VZ;

      MAC3_Raw := L31 * VX + L32 * VY + L33 * VZ;

      if MAC1_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 30);
      elsif MAC1_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 27);
      end if;

      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      elsif MAC2_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 26);
      end if;

      if MAC3_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 28);
      elsif MAC3_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 25);
      end if;

      if SF then
         MAC1 := SAR (MAC1_Raw, 12);
         MAC2 := SAR (MAC2_Raw, 12);
         MAC3 := SAR (MAC3_Raw, 12);
      else
         MAC1 := MAC1_Raw;
         MAC2 := MAC2_Raw;
         MAC3 := MAC3_Raw;
      end if;

      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);

      -- Second stage: Background color + Color matrix * IR.
      MAC1_Raw :=
        RBK * 16#1000# + LR1 * Signed_16 (GTE.IR1) + LR2 * Signed_16 (GTE.IR2)
        + LR3 * Signed_16 (GTE.IR3);

      MAC2_Raw :=
        GBK * 16#1000# + LG1 * Signed_16 (GTE.IR1) + LG2 * Signed_16 (GTE.IR2)
        + LG3 * Signed_16 (GTE.IR3);

      MAC3_Raw :=
        BBK * 16#1000# + LB1 * Signed_16 (GTE.IR1) + LB2 * Signed_16 (GTE.IR2)
        + LB3 * Signed_16 (GTE.IR3);

      if MAC1_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 30);
      elsif MAC1_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 27);
      end if;

      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      elsif MAC2_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 26);
      end if;

      if MAC3_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 28);
      elsif MAC3_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 25);
      end if;

      if SF then
         MAC1 := SAR (MAC1_Raw, 12);
         MAC2 := SAR (MAC2_Raw, 12);
         MAC3 := SAR (MAC3_Raw, 12);
      else
         MAC1 := MAC1_Raw;
         MAC2 := MAC2_Raw;
         MAC3 := MAC3_Raw;
      end if;

      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);

      -- Primary color multiplication.
      MAC1_Raw := R * Signed_16 (GTE.IR1) * 16;
      MAC2_Raw := G * Signed_16 (GTE.IR2) * 16;
      MAC3_Raw := B * Signed_16 (GTE.IR3) * 16;

      -- Depth-cue delta.
      Delta1_Raw := SAR (RFC * 16#1000# - MAC1_Raw, (if SF then 12 else 0));

      Delta2_Raw := SAR (GFC * 16#1000# - MAC2_Raw, (if SF then 12 else 0));

      Delta3_Raw := SAR (BFC * 16#1000# - MAC3_Raw, (if SF then 12 else 0));

      -- The FC-MAC intermediate result saturates as if LM=0.
      if Delta1_Raw > 32767 then
         Delta1 := 32767;
      elsif Delta1_Raw < -32768 then
         Delta1 := -32768;
      else
         Delta1 := Delta1_Raw;
      end if;

      if Delta2_Raw > 32767 then
         Delta2 := 32767;
      elsif Delta2_Raw < -32768 then
         Delta2 := -32768;
      else
         Delta2 := Delta2_Raw;
      end if;

      if Delta3_Raw > 32767 then
         Delta3 := 32767;
      elsif Delta3_Raw < -32768 then
         Delta3 := -32768;
      else
         Delta3 := Delta3_Raw;
      end if;

      -- Depth cue interpolation.
      MAC1_Raw := MAC1_Raw + Delta1 * IR0;
      MAC2_Raw := MAC2_Raw + Delta2 * IR0;
      MAC3_Raw := MAC3_Raw + Delta3 * IR0;

      if MAC1_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 30);
      elsif MAC1_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 27);
      end if;

      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      elsif MAC2_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 26);
      end if;

      if MAC3_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 28);
      elsif MAC3_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 25);
      end if;

      if SF then
         MAC1 := SAR (MAC1_Raw, 12);
         MAC2 := SAR (MAC2_Raw, 12);
         MAC3 := SAR (MAC3_Raw, 12);
      else
         MAC1 := MAC1_Raw;
         MAC2 := MAC2_Raw;
         MAC3 := MAC3_Raw;
      end if;

      GTE.MAC1 := To_Word32 (MAC1);
      GTE.MAC2 := To_Word32 (MAC2);
      GTE.MAC3 := To_Word32 (MAC3);

      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);

      -- Color FIFO: MAC / 16, saturated to 0..255.
      RGB1 := SAR (MAC1, 4);
      RGB2 := SAR (MAC2, 4);
      RGB3 := SAR (MAC3, 4);

      if RGB1 < 0 then
         RGB1 := 0;
         Set_Flag (GTE, 21);
      elsif RGB1 > 255 then
         RGB1 := 255;
         Set_Flag (GTE, 21);
      end if;

      if RGB2 < 0 then
         RGB2 := 0;
         Set_Flag (GTE, 20);
      elsif RGB2 > 255 then
         RGB2 := 255;
         Set_Flag (GTE, 20);
      end if;

      if RGB3 < 0 then
         RGB3 := 0;
         Set_Flag (GTE, 19);
      elsif RGB3 > 255 then
         RGB3 := 255;
         Set_Flag (GTE, 19);
      end if;

      GTE.RGB0 := GTE.RGB1;
      GTE.RGB1 := GTE.RGB2;

      New_RGB2 :=
        Word32 (RGB1)
        or Interfaces.Shift_Left (Word32 (RGB2), 8)
        or Interfaces.Shift_Left (Word32 (RGB3), 16)
        or Interfaces.Shift_Left (CODE, 24);

      GTE.RGB2 := New_RGB2;

   end Execute_NCDS;

   procedure Execute_CDP
     (GTE : in out PSX.GTE.GTE_State; Inst : PSX.GTE.Instruction.Instruction)
   is
      SF : constant Boolean := PSX.GTE.Instruction.Sf (Inst) /= 0;

      LM : constant Boolean := PSX.GTE.Instruction.Lm (Inst) /= 0;

      IR0 : constant Long_Long_Integer := Signed_16 (GTE.IR0);

      IR1 : constant Long_Long_Integer := Signed_16 (GTE.IR1);

      IR2 : constant Long_Long_Integer := Signed_16 (GTE.IR2);

      IR3 : constant Long_Long_Integer := Signed_16 (GTE.IR3);

      R : constant Long_Long_Integer :=
        Long_Long_Integer (GTE.RGBC and 16#0000_00FF#);

      G : constant Long_Long_Integer :=
        Long_Long_Integer
          (Interfaces.Shift_Right (GTE.RGBC, 8) and 16#0000_00FF#);

      B : constant Long_Long_Integer :=
        Long_Long_Integer
          (Interfaces.Shift_Right (GTE.RGBC, 16) and 16#0000_00FF#);

      CODE : constant Word32 := Interfaces.Shift_Right (GTE.RGBC, 24);

      LR1 : constant Long_Long_Integer := Signed_16 (GTE.LR1);
      LR2 : constant Long_Long_Integer := Signed_16 (GTE.LR2);
      LR3 : constant Long_Long_Integer := Signed_16 (GTE.LR3);

      LG1 : constant Long_Long_Integer := Signed_16 (GTE.LG1);
      LG2 : constant Long_Long_Integer := Signed_16 (GTE.LG2);
      LG3 : constant Long_Long_Integer := Signed_16 (GTE.LG3);

      LB1 : constant Long_Long_Integer := Signed_16 (GTE.LB1);
      LB2 : constant Long_Long_Integer := Signed_16 (GTE.LB2);
      LB3 : constant Long_Long_Integer := Signed_16 (GTE.LB3);

      RBK : constant Long_Long_Integer := Signed_32 (GTE.RBK);
      GBK : constant Long_Long_Integer := Signed_32 (GTE.GBK);
      BBK : constant Long_Long_Integer := Signed_32 (GTE.BBK);

      RFC : constant Long_Long_Integer := Signed_32 (GTE.RFC);
      GFC : constant Long_Long_Integer := Signed_32 (GTE.GFC);
      BFC : constant Long_Long_Integer := Signed_32 (GTE.BFC);

      MAC1_Raw : Long_Long_Integer;
      MAC2_Raw : Long_Long_Integer;
      MAC3_Raw : Long_Long_Integer;

      MAC1 : Long_Long_Integer;
      MAC2 : Long_Long_Integer;
      MAC3 : Long_Long_Integer;

      Delta1_Raw : Long_Long_Integer;
      Delta2_Raw : Long_Long_Integer;
      Delta3_Raw : Long_Long_Integer;

      Delta1 : Long_Long_Integer;
      Delta2 : Long_Long_Integer;
      Delta3 : Long_Long_Integer;

      RGB_Raw : Long_Long_Integer;
      RGB_Gaw : Long_Long_Integer;
      RGB_Baw : Long_Long_Integer;

      RGB_R : Long_Long_Integer;
      RGB_G : Long_Long_Integer;
      RGB_B : Long_Long_Integer;

      New_RGB2 : Word32;

   begin
      GTE.FLAG := 0;

      -- Color matrix * IR + background color.
      MAC1_Raw := RBK * 16#1000# + LR1 * IR1 + LR2 * IR2 + LR3 * IR3;

      MAC2_Raw := GBK * 16#1000# + LG1 * IR1 + LG2 * IR2 + LG3 * IR3;

      MAC3_Raw := BBK * 16#1000# + LB1 * IR1 + LB2 * IR2 + LB3 * IR3;

      if MAC1_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 30);
      elsif MAC1_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 27);
      end if;

      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      elsif MAC2_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 26);
      end if;

      if MAC3_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 28);
      elsif MAC3_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 25);
      end if;

      if SF then
         MAC1 := SAR (MAC1_Raw, 12);
         MAC2 := SAR (MAC2_Raw, 12);
         MAC3 := SAR (MAC3_Raw, 12);
      else
         MAC1 := MAC1_Raw;
         MAC2 := MAC2_Raw;
         MAC3 := MAC3_Raw;
      end if;

      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);

      -- Color multiplication.
      MAC1_Raw := R * Signed_16 (GTE.IR1) * 16;
      MAC2_Raw := G * Signed_16 (GTE.IR2) * 16;
      MAC3_Raw := B * Signed_16 (GTE.IR3) * 16;

      -- Difference between far color and current color.
      Delta1_Raw := RFC * 16#1000# - MAC1_Raw;

      Delta2_Raw := GFC * 16#1000# - MAC2_Raw;

      Delta3_Raw := BFC * 16#1000# - MAC3_Raw;

      if SF then
         Delta1 := SAR (Delta1_Raw, 12);
         Delta2 := SAR (Delta2_Raw, 12);
         Delta3 := SAR (Delta3_Raw, 12);
      else
         Delta1 := Delta1_Raw;
         Delta2 := Delta2_Raw;
         Delta3 := Delta3_Raw;
      end if;

      if Delta1 > 32767 then
         Delta1 := 32767;
      elsif Delta1 < -32768 then
         Delta1 := -32768;
      end if;

      if Delta2 > 32767 then
         Delta2 := 32767;
      elsif Delta2 < -32768 then
         Delta2 := -32768;
      end if;

      if Delta3 > 32767 then
         Delta3 := 32767;
      elsif Delta3 < -32768 then
         Delta3 := -32768;
      end if;

      MAC1_Raw := MAC1_Raw + Delta1 * IR0;
      MAC2_Raw := MAC2_Raw + Delta2 * IR0;
      MAC3_Raw := MAC3_Raw + Delta3 * IR0;

      if MAC1_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 30);
      elsif MAC1_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 27);
      end if;

      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      elsif MAC2_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 26);
      end if;

      if MAC3_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 28);
      elsif MAC3_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 25);
      end if;

      if SF then
         MAC1 := SAR (MAC1_Raw, 12);
         MAC2 := SAR (MAC2_Raw, 12);
         MAC3 := SAR (MAC3_Raw, 12);
      else
         MAC1 := MAC1_Raw;
         MAC2 := MAC2_Raw;
         MAC3 := MAC3_Raw;
      end if;

      GTE.MAC1 := To_Word32 (MAC1);
      GTE.MAC2 := To_Word32 (MAC2);
      GTE.MAC3 := To_Word32 (MAC3);

      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);

      RGB_Raw := SAR (MAC1, 4);
      RGB_Gaw := SAR (MAC2, 4);
      RGB_Baw := SAR (MAC3, 4);

      if RGB_Raw < 0 then
         RGB_R := 0;
         Set_Flag (GTE, 21);
      elsif RGB_Raw > 255 then
         RGB_R := 255;
         Set_Flag (GTE, 21);
      else
         RGB_R := RGB_Raw;
      end if;

      if RGB_Gaw < 0 then
         RGB_G := 0;
         Set_Flag (GTE, 20);
      elsif RGB_Gaw > 255 then
         RGB_G := 255;
         Set_Flag (GTE, 20);
      else
         RGB_G := RGB_Gaw;
      end if;

      if RGB_Baw < 0 then
         RGB_B := 0;
         Set_Flag (GTE, 19);
      elsif RGB_Baw > 255 then
         RGB_B := 255;
         Set_Flag (GTE, 19);
      else
         RGB_B := RGB_Baw;
      end if;

      GTE.RGB0 := GTE.RGB1;
      GTE.RGB1 := GTE.RGB2;

      New_RGB2 :=
        Word32 (RGB_R)
        or Interfaces.Shift_Left (Word32 (RGB_G), 8)
        or Interfaces.Shift_Left (Word32 (RGB_B), 16)
        or Interfaces.Shift_Left (CODE, 24);

      GTE.RGB2 := New_RGB2;

   end Execute_CDP;

   procedure Execute_NCDT
     (GTE : in out PSX.GTE.GTE_State; Inst : PSX.GTE.Instruction.Instruction)
   is
      Original_V0_X : constant Word32 := GTE.V0_X;
      Original_V0_Y : constant Word32 := GTE.V0_Y;
      Original_V0_Z : constant Word32 := GTE.V0_Z;

      Saved_Flag : Word32 := 0;

   begin
      GTE.FLAG := 0;

      -- Vertex V0.
      Execute_NCDS (GTE, Inst);
      Saved_Flag := GTE.FLAG;

      -- Vertex V1.
      GTE.V0_X := GTE.V1_X;
      GTE.V0_Y := GTE.V1_Y;
      GTE.V0_Z := GTE.V1_Z;

      Execute_NCDS (GTE, Inst);
      Saved_Flag := Saved_Flag or GTE.FLAG;

      -- Vertex V2.
      GTE.V0_X := GTE.V2_X;
      GTE.V0_Y := GTE.V2_Y;
      GTE.V0_Z := GTE.V2_Z;

      Execute_NCDS (GTE, Inst);
      Saved_Flag := Saved_Flag or GTE.FLAG;

      -- NCDT does not modify the vertex registers.
      GTE.V0_X := Original_V0_X;
      GTE.V0_Y := Original_V0_Y;
      GTE.V0_Z := Original_V0_Z;

      GTE.FLAG := Saved_Flag;

   end Execute_NCDT;

   procedure Execute_NCCS
     (GTE : in out PSX.GTE.GTE_State; Inst : PSX.GTE.Instruction.Instruction)
   is
      SF : constant Boolean := PSX.GTE.Instruction.Sf (Inst) /= 0;

      LM : constant Boolean := PSX.GTE.Instruction.Lm (Inst) /= 0;

      VX : constant Long_Long_Integer := Signed_16 (GTE.V0_X);

      VY : constant Long_Long_Integer := Signed_16 (GTE.V0_Y);

      VZ : constant Long_Long_Integer := Signed_16 (GTE.V0_Z);

      R : constant Long_Long_Integer :=
        Long_Long_Integer (GTE.RGBC and 16#0000_00FF#);

      G : constant Long_Long_Integer :=
        Long_Long_Integer
          (Interfaces.Shift_Right (GTE.RGBC, 8) and 16#0000_00FF#);

      B : constant Long_Long_Integer :=
        Long_Long_Integer
          (Interfaces.Shift_Right (GTE.RGBC, 16) and 16#0000_00FF#);

      CODE : constant Word32 := Interfaces.Shift_Right (GTE.RGBC, 24);

      L11 : constant Long_Long_Integer := Signed_16 (GTE.L11);
      L12 : constant Long_Long_Integer := Signed_16 (GTE.L12);
      L13 : constant Long_Long_Integer := Signed_16 (GTE.L13);

      L21 : constant Long_Long_Integer := Signed_16 (GTE.L21);
      L22 : constant Long_Long_Integer := Signed_16 (GTE.L22);
      L23 : constant Long_Long_Integer := Signed_16 (GTE.L23);

      L31 : constant Long_Long_Integer := Signed_16 (GTE.L31);
      L32 : constant Long_Long_Integer := Signed_16 (GTE.L32);
      L33 : constant Long_Long_Integer := Signed_16 (GTE.L33);

      LR1 : constant Long_Long_Integer := Signed_16 (GTE.LR1);
      LR2 : constant Long_Long_Integer := Signed_16 (GTE.LR2);
      LR3 : constant Long_Long_Integer := Signed_16 (GTE.LR3);

      LG1 : constant Long_Long_Integer := Signed_16 (GTE.LG1);
      LG2 : constant Long_Long_Integer := Signed_16 (GTE.LG2);
      LG3 : constant Long_Long_Integer := Signed_16 (GTE.LG3);

      LB1 : constant Long_Long_Integer := Signed_16 (GTE.LB1);
      LB2 : constant Long_Long_Integer := Signed_16 (GTE.LB2);
      LB3 : constant Long_Long_Integer := Signed_16 (GTE.LB3);

      RBK : constant Long_Long_Integer := Signed_32 (GTE.RBK);
      GBK : constant Long_Long_Integer := Signed_32 (GTE.GBK);
      BBK : constant Long_Long_Integer := Signed_32 (GTE.BBK);

      MAC1_Raw : Long_Long_Integer;
      MAC2_Raw : Long_Long_Integer;
      MAC3_Raw : Long_Long_Integer;

      MAC1 : Long_Long_Integer;
      MAC2 : Long_Long_Integer;
      MAC3 : Long_Long_Integer;

      RGB_Raw : Long_Long_Integer;
      RGB_Gaw : Long_Long_Integer;
      RGB_Baw : Long_Long_Integer;

      RGB_R : Long_Long_Integer;
      RGB_G : Long_Long_Integer;
      RGB_B : Long_Long_Integer;

      New_RGB2 : Word32;

   begin
      GTE.FLAG := 0;

      -- Light matrix * V0.
      MAC1_Raw := L11 * VX + L12 * VY + L13 * VZ;

      MAC2_Raw := L21 * VX + L22 * VY + L23 * VZ;

      MAC3_Raw := L31 * VX + L32 * VY + L33 * VZ;

      if MAC1_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 30);
      elsif MAC1_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 27);
      end if;

      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      elsif MAC2_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 26);
      end if;

      if MAC3_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 28);
      elsif MAC3_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 25);
      end if;

      if SF then
         MAC1 := SAR (MAC1_Raw, 12);
         MAC2 := SAR (MAC2_Raw, 12);
         MAC3 := SAR (MAC3_Raw, 12);
      else
         MAC1 := MAC1_Raw;
         MAC2 := MAC2_Raw;
         MAC3 := MAC3_Raw;
      end if;

      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);

      -- Background color + color matrix * IR.
      MAC1_Raw :=
        RBK * 16#1000# + LR1 * Signed_16 (GTE.IR1) + LR2 * Signed_16 (GTE.IR2)
        + LR3 * Signed_16 (GTE.IR3);
      MAC2_Raw :=
        GBK * 16#1000# + LG1 * Signed_16 (GTE.IR1) + LG2 * Signed_16 (GTE.IR2)
        + LG3 * Signed_16 (GTE.IR3);
      MAC3_Raw :=
        BBK * 16#1000# + LB1 * Signed_16 (GTE.IR1) + LB2 * Signed_16 (GTE.IR2)
        + LB3 * Signed_16 (GTE.IR3);
      if MAC1_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 30);
      elsif MAC1_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 27);
      end if;
      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      elsif MAC2_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 26);
      end if;
      if MAC3_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 28);
      elsif MAC3_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 25);
      end if;
      if SF then
         MAC1 := SAR (MAC1_Raw, 12);
         MAC2 := SAR (MAC2_Raw, 12);
         MAC3 := SAR (MAC3_Raw, 12);
      else
         MAC1 := MAC1_Raw;
         MAC2 := MAC2_Raw;
         MAC3 := MAC3_Raw;
      end if;
      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);
      -- Primary color * IR, shifted left by 4.
      MAC1_Raw := R * Signed_16 (GTE.IR1) * 16;
      MAC2_Raw := G * Signed_16 (GTE.IR2) * 16;
      MAC3_Raw := B * Signed_16 (GTE.IR3) * 16;
      if MAC1_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 30);
      elsif MAC1_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 27);
      end if;
      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      elsif MAC2_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 26);
      end if;
      if MAC3_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 28);
      elsif MAC3_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 25);
      end if;
      if SF then
         MAC1 := SAR (MAC1_Raw, 12);
         MAC2 := SAR (MAC2_Raw, 12);
         MAC3 := SAR (MAC3_Raw, 12);
      else
         MAC1 := MAC1_Raw;
         MAC2 := MAC2_Raw;
         MAC3 := MAC3_Raw;
      end if;
      GTE.MAC1 := To_Word32 (MAC1);
      GTE.MAC2 := To_Word32 (MAC2);
      GTE.MAC3 := To_Word32 (MAC3);
      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);
      -- Color FIFO.
      RGB_Raw := SAR (MAC1, 4);
      RGB_Gaw := SAR (MAC2, 4);
      RGB_Baw := SAR (MAC3, 4);
      if RGB_Raw < 0 then
         RGB_R := 0;
         Set_Flag (GTE, 21);
      elsif RGB_Raw > 255 then
         RGB_R := 255;
         Set_Flag (GTE, 21);
      else
         RGB_R := RGB_Raw;
      end if;
      if RGB_Gaw < 0 then
         RGB_G := 0;
         Set_Flag (GTE, 20);
      elsif RGB_Gaw > 255 then
         RGB_G := 255;
         Set_Flag (GTE, 20);
      else
         RGB_G := RGB_Gaw;
      end if;
      if RGB_Baw < 0 then
         RGB_B := 0;
         Set_Flag (GTE, 19);
      elsif RGB_Baw > 255 then
         RGB_B := 255;
         Set_Flag (GTE, 19);
      else
         RGB_B := RGB_Baw;
      end if;
      GTE.RGB0 := GTE.RGB1;
      GTE.RGB1 := GTE.RGB2;
      New_RGB2 :=
        Word32 (RGB_R)
        or Interfaces.Shift_Left (Word32 (RGB_G), 8)
        or Interfaces.Shift_Left (Word32 (RGB_B), 16)
        or Interfaces.Shift_Left (CODE, 24);
      GTE.RGB2 := New_RGB2;
   end Execute_NCCS;

   procedure Execute_CC
     (GTE : in out PSX.GTE.GTE_State; Inst : PSX.GTE.Instruction.Instruction)
   is
      SF       : constant Boolean := PSX.GTE.Instruction.Sf (Inst) /= 0;
      LM       : constant Boolean := PSX.GTE.Instruction.Lm (Inst) /= 0;
      IR1      : constant Long_Long_Integer := Signed_16 (GTE.IR1);
      IR2      : constant Long_Long_Integer := Signed_16 (GTE.IR2);
      IR3      : constant Long_Long_Integer := Signed_16 (GTE.IR3);
      R        : constant Long_Long_Integer :=
        Long_Long_Integer (GTE.RGBC and 16#0000_00FF#);
      G        : constant Long_Long_Integer :=
        Long_Long_Integer
          (Interfaces.Shift_Right (GTE.RGBC, 8) and 16#0000_00FF#);
      B        : constant Long_Long_Integer :=
        Long_Long_Integer
          (Interfaces.Shift_Right (GTE.RGBC, 16) and 16#0000_00FF#);
      CODE     : constant Word32 := Interfaces.Shift_Right (GTE.RGBC, 24);
      LR1      : constant Long_Long_Integer := Signed_16 (GTE.LR1);
      LR2      : constant Long_Long_Integer := Signed_16 (GTE.LR2);
      LR3      : constant Long_Long_Integer := Signed_16 (GTE.LR3);
      LG1      : constant Long_Long_Integer := Signed_16 (GTE.LG1);
      LG2      : constant Long_Long_Integer := Signed_16 (GTE.LG2);
      LG3      : constant Long_Long_Integer := Signed_16 (GTE.LG3);
      LB1      : constant Long_Long_Integer := Signed_16 (GTE.LB1);
      LB2      : constant Long_Long_Integer := Signed_16 (GTE.LB2);
      LB3      : constant Long_Long_Integer := Signed_16 (GTE.LB3);
      RBK      : constant Long_Long_Integer := Signed_32 (GTE.RBK);
      GBK      : constant Long_Long_Integer := Signed_32 (GTE.GBK);
      BBK      : constant Long_Long_Integer := Signed_32 (GTE.BBK);
      MAC1_Raw : Long_Long_Integer;
      MAC2_Raw : Long_Long_Integer;
      MAC3_Raw : Long_Long_Integer;
      MAC1     : Long_Long_Integer;
      MAC2     : Long_Long_Integer;
      MAC3     : Long_Long_Integer;
      RGB_Raw  : Long_Long_Integer;
      RGB_Gaw  : Long_Long_Integer;
      RGB_Baw  : Long_Long_Integer;
      RGB_R    : Long_Long_Integer;
      RGB_G    : Long_Long_Integer;
      RGB_B    : Long_Long_Integer;
      New_RGB2 : Word32;
   begin
      GTE.FLAG := 0;
      MAC1_Raw := RBK * 16#1000# + LR1 * IR1 + LR2 * IR2 + LR3 * IR3;
      MAC2_Raw := GBK * 16#1000# + LG1 * IR1 + LG2 * IR2 + LG3 * IR3;
      MAC3_Raw := BBK * 16#1000# + LB1 * IR1 + LB2 * IR2 + LB3 * IR3;
      if MAC1_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 30);
      elsif MAC1_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 27);
      end if;
      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      elsif MAC2_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 26);
      end if;
      if MAC3_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 28);
      elsif MAC3_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 25);
      end if;
      if SF then
         MAC1 := SAR (MAC1_Raw, 12);
         MAC2 := SAR (MAC2_Raw, 12);
         MAC3 := SAR (MAC3_Raw, 12);
      else
         MAC1 := MAC1_Raw;
         MAC2 := MAC2_Raw;
         MAC3 := MAC3_Raw;
      end if;
      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);
      MAC1_Raw := R * Signed_16 (GTE.IR1) * 16;
      MAC2_Raw := G * Signed_16 (GTE.IR2) * 16;
      MAC3_Raw := B * Signed_16 (GTE.IR3) * 16;
      if MAC1_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 30);
      elsif MAC1_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 27);
      end if;
      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      elsif MAC2_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 26);
      end if;
      if MAC3_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 28);
      elsif MAC3_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 25);
      end if;
      if SF then
         MAC1 := SAR (MAC1_Raw, 12);
         MAC2 := SAR (MAC2_Raw, 12);
         MAC3 := SAR (MAC3_Raw, 12);
      else
         MAC1 := MAC1_Raw;
         MAC2 := MAC2_Raw;
         MAC3 := MAC3_Raw;
      end if;
      GTE.MAC1 := To_Word32 (MAC1);
      GTE.MAC2 := To_Word32 (MAC2);
      GTE.MAC3 := To_Word32 (MAC3);
      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);
      RGB_Raw := SAR (MAC1, 4);
      RGB_Gaw := SAR (MAC2, 4);
      RGB_Baw := SAR (MAC3, 4);
      if RGB_Raw < 0 then
         RGB_R := 0;
         Set_Flag (GTE, 21);
      elsif RGB_Raw > 255 then
         RGB_R := 255;
         Set_Flag (GTE, 21);
      else
         RGB_R := RGB_Raw;
      end if;
      if RGB_Gaw < 0 then
         RGB_G := 0;
         Set_Flag (GTE, 20);
      elsif RGB_Gaw > 255 then
         RGB_G := 255;
         Set_Flag (GTE, 20);
      else
         RGB_G := RGB_Gaw;
      end if;
      if RGB_Baw < 0 then
         RGB_B := 0;
         Set_Flag (GTE, 19);
      elsif RGB_Baw > 255 then
         RGB_B := 255;
      else
         RGB_B := RGB_Baw;
      end if;
      GTE.RGB0 := GTE.RGB1;
      GTE.RGB1 := GTE.RGB2;
      New_RGB2 :=
        Word32 (RGB_R)
        or Interfaces.Shift_Left (Word32 (RGB_G), 8)
        or Interfaces.Shift_Left (Word32 (RGB_B), 16)
        or Interfaces.Shift_Left (CODE, 24);
      GTE.RGB2 := New_RGB2;
   end Execute_CC;

   procedure Execute_NCS
     (GTE : in out PSX.GTE.GTE_State; Inst : PSX.GTE.Instruction.Instruction)
   is
      SF       : constant Boolean := PSX.GTE.Instruction.Sf (Inst) /= 0;
      LM       : constant Boolean := PSX.GTE.Instruction.Lm (Inst) /= 0;
      VX       : constant Long_Long_Integer := Signed_16 (GTE.V0_X);
      VY       : constant Long_Long_Integer := Signed_16 (GTE.V0_Y);
      VZ       : constant Long_Long_Integer := Signed_16 (GTE.V0_Z);
      L11      : constant Long_Long_Integer := Signed_16 (GTE.L11);
      L12      : constant Long_Long_Integer := Signed_16 (GTE.L12);
      L13      : constant Long_Long_Integer := Signed_16 (GTE.L13);
      L21      : constant Long_Long_Integer := Signed_16 (GTE.L21);
      L22      : constant Long_Long_Integer := Signed_16 (GTE.L22);
      L23      : constant Long_Long_Integer := Signed_16 (GTE.L23);
      L31      : constant Long_Long_Integer := Signed_16 (GTE.L31);
      L32      : constant Long_Long_Integer := Signed_16 (GTE.L32);
      L33      : constant Long_Long_Integer := Signed_16 (GTE.L33);
      LR1      : constant Long_Long_Integer := Signed_16 (GTE.LR1);
      LR2      : constant Long_Long_Integer := Signed_16 (GTE.LR2);
      LR3      : constant Long_Long_Integer := Signed_16 (GTE.LR3);
      LG1      : constant Long_Long_Integer := Signed_16 (GTE.LG1);
      LG2      : constant Long_Long_Integer := Signed_16 (GTE.LG2);
      LG3      : constant Long_Long_Integer := Signed_16 (GTE.LG3);
      LB1      : constant Long_Long_Integer := Signed_16 (GTE.LB1);
      LB2      : constant Long_Long_Integer := Signed_16 (GTE.LB2);
      LB3      : constant Long_Long_Integer := Signed_16 (GTE.LB3);
      RBK      : constant Long_Long_Integer := Signed_32 (GTE.RBK);
      GBK      : constant Long_Long_Integer := Signed_32 (GTE.GBK);
      BBK      : constant Long_Long_Integer := Signed_32 (GTE.BBK);
      CODE     : constant Word32 := Interfaces.Shift_Right (GTE.RGBC, 24);
      MAC1_Raw : Long_Long_Integer;
      MAC2_Raw : Long_Long_Integer;
      MAC3_Raw : Long_Long_Integer;
      MAC1     : Long_Long_Integer;
      MAC2     : Long_Long_Integer;
      MAC3     : Long_Long_Integer;
      RGB_Raw  : Long_Long_Integer;
      RGB_Gaw  : Long_Long_Integer;
      RGB_Baw  : Long_Long_Integer;
      RGB_R    : Long_Long_Integer;
      RGB_G    : Long_Long_Integer;
      RGB_B    : Long_Long_Integer;
      New_RGB2 : Word32;
   begin
      GTE.FLAG := 0;
      -- Light matrix * V0.
      MAC1_Raw := L11 * VX + L12 * VY + L13 * VZ;
      MAC2_Raw := L21 * VX + L22 * VY + L23 * VZ;
      MAC3_Raw := L31 * VX + L32 * VY + L33 * VZ;
      if MAC1_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 30);
      elsif MAC1_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 27);
      end if;
      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      elsif MAC2_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 26);
      end if;
      if MAC3_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 28);
      elsif MAC3_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 25);
      end if;
      if SF then
         MAC1 := SAR (MAC1_Raw, 12);
         MAC2 := SAR (MAC2_Raw, 12);
         MAC3 := SAR (MAC3_Raw, 12);
      else
         MAC1 := MAC1_Raw;
         MAC2 := MAC2_Raw;
         MAC3 := MAC3_Raw;
      end if;
      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);
      -- Background color + color matrix * IR.
      MAC1_Raw :=
        RBK * 16#1000# + LR1 * Signed_16 (GTE.IR1) + LR2 * Signed_16 (GTE.IR2)
        + LR3 * Signed_16 (GTE.IR3);
      MAC2_Raw :=
        GBK * 16#1000# + LG1 * Signed_16 (GTE.IR1) + LG2 * Signed_16 (GTE.IR2)
        + LG3 * Signed_16 (GTE.IR3);
      MAC3_Raw :=
        BBK * 16#1000# + LB1 * Signed_16 (GTE.IR1) + LB2 * Signed_16 (GTE.IR2)
        + LB3 * Signed_16 (GTE.IR3);
      if MAC1_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 30);
      elsif MAC1_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 27);
      end if;
      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      elsif MAC2_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 26);
      end if;
      if MAC3_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 28);
      elsif MAC3_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 25);
      end if;
      if SF then
         MAC1 := SAR (MAC1_Raw, 12);
         MAC2 := SAR (MAC2_Raw, 12);
         MAC3 := SAR (MAC3_Raw, 12);
      else
         MAC1 := MAC1_Raw;
         MAC2 := MAC2_Raw;
         MAC3 := MAC3_Raw;
      end if;
      GTE.MAC1 := To_Word32 (MAC1);
      GTE.MAC2 := To_Word32 (MAC2);
      GTE.MAC3 := To_Word32 (MAC3);
      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);

      -- Color FIFO receives MAC / 16.
      RGB_Raw := SAR (MAC1, 4);
      RGB_Gaw := SAR (MAC2, 4);
      RGB_Baw := SAR (MAC3, 4);
      if RGB_Raw < 0 then
         RGB_R := 0;
         Set_Flag (GTE, 21);
      elsif RGB_Raw > 255 then
         RGB_R := 255;
         Set_Flag (GTE, 21);
      else
         RGB_R := RGB_Raw;
      end if;
      if RGB_Gaw < 0 then
         RGB_G := 0;
         Set_Flag (GTE, 20);
      elsif RGB_Gaw > 255 then
         RGB_G := 255;
         Set_Flag (GTE, 20);
      else
         RGB_G := RGB_Gaw;
      end if;
      if RGB_Baw < 0 then
         RGB_B := 0;
         Set_Flag (GTE, 19);
      elsif RGB_Baw > 255 then
         RGB_B := 255;
         Set_Flag (GTE, 19);
      else
         RGB_B := RGB_Baw;
      end if;
      GTE.RGB0 := GTE.RGB1;
      GTE.RGB1 := GTE.RGB2;
      New_RGB2 :=
        Word32 (RGB_R)
        or Interfaces.Shift_Left (Word32 (RGB_G), 8)
        or Interfaces.Shift_Left (Word32 (RGB_B), 16)
        or Interfaces.Shift_Left (CODE, 24);
      GTE.RGB2 := New_RGB2;
   end Execute_NCS;

   procedure Execute_NCT
     (GTE : in out PSX.GTE.GTE_State; Inst : PSX.GTE.Instruction.Instruction)
   is
      V0_X : constant Word32 := GTE.V0_X;
      V0_Y : constant Word32 := GTE.V0_Y;
      V0_Z : constant Word32 := GTE.V0_Z;

      V1_X : constant Word32 := GTE.V1_X;
      V1_Y : constant Word32 := GTE.V1_Y;
      V1_Z : constant Word32 := GTE.V1_Z;

      V2_X : constant Word32 := GTE.V2_X;
      V2_Y : constant Word32 := GTE.V2_Y;
      V2_Z : constant Word32 := GTE.V2_Z;

      Saved_Flag : Word32 := 0;

   begin
      GTE.FLAG := 0;

      GTE.V0_X := V0_X;
      GTE.V0_Y := V0_Y;
      GTE.V0_Z := V0_Z;

      Execute_NCS (GTE, Inst);
      Saved_Flag := GTE.FLAG;

      GTE.V0_X := V1_X;
      GTE.V0_Y := V1_Y;
      GTE.V0_Z := V1_Z;

      Execute_NCS (GTE, Inst);
      Saved_Flag := Saved_Flag or GTE.FLAG;

      GTE.V0_X := V2_X;
      GTE.V0_Y := V2_Y;
      GTE.V0_Z := V2_Z;

      Execute_NCS (GTE, Inst);
      Saved_Flag := Saved_Flag or GTE.FLAG;

      GTE.V0_X := V0_X;
      GTE.V0_Y := V0_Y;
      GTE.V0_Z := V0_Z;

      GTE.FLAG := Saved_Flag;

   end Execute_NCT;

   procedure Execute_NCCT
     (GTE : in out PSX.GTE.GTE_State; Inst : PSX.GTE.Instruction.Instruction)
   is
      V0_X : constant Word32 := GTE.V0_X;
      V0_Y : constant Word32 := GTE.V0_Y;
      V0_Z : constant Word32 := GTE.V0_Z;

      V1_X : constant Word32 := GTE.V1_X;
      V1_Y : constant Word32 := GTE.V1_Y;
      V1_Z : constant Word32 := GTE.V1_Z;

      V2_X : constant Word32 := GTE.V2_X;
      V2_Y : constant Word32 := GTE.V2_Y;
      V2_Z : constant Word32 := GTE.V2_Z;

      Saved_Flag : Word32 := 0;

   begin
      GTE.FLAG := 0;

      GTE.V0_X := V0_X;
      GTE.V0_Y := V0_Y;
      GTE.V0_Z := V0_Z;

      Execute_NCCS (GTE, Inst);
      Saved_Flag := GTE.FLAG;

      GTE.V0_X := V1_X;
      GTE.V0_Y := V1_Y;
      GTE.V0_Z := V1_Z;

      Execute_NCCS (GTE, Inst);
      Saved_Flag := Saved_Flag or GTE.FLAG;

      GTE.V0_X := V2_X;
      GTE.V0_Y := V2_Y;
      GTE.V0_Z := V2_Z;

      Execute_NCCS (GTE, Inst);
      Saved_Flag := Saved_Flag or GTE.FLAG;

      GTE.V0_X := V0_X;
      GTE.V0_Y := V0_Y;
      GTE.V0_Z := V0_Z;

      GTE.FLAG := Saved_Flag;

   end Execute_NCCT;

   procedure Execute_SQR
     (GTE : in out PSX.GTE.GTE_State; Inst : PSX.GTE.Instruction.Instruction)
   is
      SF       : constant Boolean := PSX.GTE.Instruction.Sf (Inst) /= 0;
      LM       : constant Boolean := PSX.GTE.Instruction.Lm (Inst) /= 0;
      IR1      : constant Long_Long_Integer := Signed_16 (GTE.IR1);
      IR2      : constant Long_Long_Integer := Signed_16 (GTE.IR2);
      IR3      : constant Long_Long_Integer := Signed_16 (GTE.IR3);
      MAC1_Raw : Long_Long_Integer;
      MAC2_Raw : Long_Long_Integer;
      MAC3_Raw : Long_Long_Integer;
      MAC1     : Long_Long_Integer;
      MAC2     : Long_Long_Integer;
      MAC3     : Long_Long_Integer;
   begin
      GTE.FLAG := 0;
      MAC1_Raw := IR1 * IR1;
      MAC2_Raw := IR2 * IR2;
      MAC3_Raw := IR3 * IR3;
      if MAC1_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 30);
      end if;
      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      end if;
      if MAC3_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 28);
      end if;
      if SF then
         MAC1 := SAR (MAC1_Raw, 12);
         MAC2 := SAR (MAC2_Raw, 12);
         MAC3 := SAR (MAC3_Raw, 12);
      else
         MAC1 := MAC1_Raw;
         MAC2 := MAC2_Raw;
         MAC3 := MAC3_Raw;
      end if;
      GTE.MAC1 := To_Word32 (MAC1);
      GTE.MAC2 := To_Word32 (MAC2);
      GTE.MAC3 := To_Word32 (MAC3);
      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);
   end Execute_SQR;

   procedure Execute_DCPL
     (GTE : in out PSX.GTE.GTE_State; Inst : PSX.GTE.Instruction.Instruction)
   is
      SF : constant Boolean := PSX.GTE.Instruction.Sf (Inst) /= 0;

      LM : constant Boolean := PSX.GTE.Instruction.Lm (Inst) /= 0;

      IR0 : constant Long_Long_Integer := Signed_16 (GTE.IR0);

      IR1 : constant Long_Long_Integer := Signed_16 (GTE.IR1);

      IR2 : constant Long_Long_Integer := Signed_16 (GTE.IR2);

      IR3 : constant Long_Long_Integer := Signed_16 (GTE.IR3);

      R : constant Long_Long_Integer :=
        Long_Long_Integer (GTE.RGBC and 16#0000_00FF#);

      G : constant Long_Long_Integer :=
        Long_Long_Integer ((GTE.RGBC / 16#100#) and 16#0000_00FF#);

      B : constant Long_Long_Integer :=
        Long_Long_Integer ((GTE.RGBC / 16#10_000#) and 16#0000_00FF#);

      Code : constant Word32 := GTE.RGBC and 16#FF00_0000#;

      RFC : constant Long_Long_Integer := Signed_32 (GTE.RFC);

      GFC : constant Long_Long_Integer := Signed_32 (GTE.GFC);

      BFC : constant Long_Long_Integer := Signed_32 (GTE.BFC);

      Base1 : Long_Long_Integer;
      Base2 : Long_Long_Integer;
      Base3 : Long_Long_Integer;

      Delta1 : Long_Long_Integer;
      Delta2 : Long_Long_Integer;
      Delta3 : Long_Long_Integer;

      MAC1_Raw : Long_Long_Integer;
      MAC2_Raw : Long_Long_Integer;
      MAC3_Raw : Long_Long_Integer;

      MAC1 : Long_Long_Integer;
      MAC2 : Long_Long_Integer;
      MAC3 : Long_Long_Integer;

      RGB_R : Long_Long_Integer;
      RGB_G : Long_Long_Integer;
      RGB_B : Long_Long_Integer;

   begin
      GTE.FLAG := 0;

      -- RGB * IR << 4
      Base1 := R * IR1 * 16;
      Base2 := G * IR2 * 16;
      Base3 := B * IR3 * 16;

      -- FC * 1000h - MAC
      Delta1 := RFC * 16#1000# - Base1;
      Delta2 := GFC * 16#1000# - Base2;
      Delta3 := BFC * 16#1000# - Base3;

      -- The depth-cue interpolation operand is saturated
      -- to signed 16 bits before multiplication by IR0.
      if Delta1 > 32767 then
         Delta1 := 32767;
         Set_Flag (GTE, 30);
      elsif Delta1 < -32768 then
         Delta1 := -32768;
         Set_Flag (GTE, 27);
      end if;

      if Delta2 > 32767 then
         Delta2 := 32767;
         Set_Flag (GTE, 29);
      elsif Delta2 < -32768 then
         Delta2 := -32768;
         Set_Flag (GTE, 26);
      end if;

      if Delta3 > 32767 then
         Delta3 := 32767;
         Set_Flag (GTE, 28);
      elsif Delta3 < -32768 then
         Delta3 := -32768;
         Set_Flag (GTE, 25);
      end if;

      MAC1_Raw := Base1 + Delta1 * IR0;
      MAC2_Raw := Base2 + Delta2 * IR0;
      MAC3_Raw := Base3 + Delta3 * IR0;

      if SF then
         MAC1 := SAR (MAC1_Raw, 12);
         MAC2 := SAR (MAC2_Raw, 12);
         MAC3 := SAR (MAC3_Raw, 12);
      else
         MAC1 := MAC1_Raw;
         MAC2 := MAC2_Raw;
         MAC3 := MAC3_Raw;
      end if;

      GTE.MAC1 := To_Word32 (MAC1);
      GTE.MAC2 := To_Word32 (MAC2);
      GTE.MAC3 := To_Word32 (MAC3);

      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);

      -- Color FIFO receives MAC / 16.
      RGB_R := MAC1 / 16;
      RGB_G := MAC2 / 16;
      RGB_B := MAC3 / 16;

      if RGB_R < 0 then
         RGB_R := 0;
         Set_Flag (GTE, 21);
      elsif RGB_R > 255 then
         RGB_R := 255;
         Set_Flag (GTE, 21);
      end if;

      if RGB_G < 0 then
         RGB_G := 0;
         Set_Flag (GTE, 20);
      elsif RGB_G > 255 then
         RGB_G := 255;
         Set_Flag (GTE, 20);
      end if;

      if RGB_B < 0 then
         RGB_B := 0;
         Set_Flag (GTE, 19);
      elsif RGB_B > 255 then
         RGB_B := 255;
         Set_Flag (GTE, 19);
      end if;

      GTE.RGB0 := GTE.RGB1;
      GTE.RGB1 := GTE.RGB2;

      GTE.RGB2 :=
        Code
        or Word32 (RGB_R)
        or Interfaces.Shift_Left (Word32 (RGB_G), 8)
        or Interfaces.Shift_Left (Word32 (RGB_B), 16);

   end Execute_DCPL;

   procedure Execute_DPCT
     (GTE : in out PSX.GTE.GTE_State; Inst : PSX.GTE.Instruction.Instruction)
   is
      SF : constant Boolean := PSX.GTE.Instruction.Sf (Inst) /= 0;

      LM : constant Boolean := PSX.GTE.Instruction.Lm (Inst) /= 0;

      IR0 : constant Long_Long_Integer := Signed_16 (GTE.IR0);

      RFC : constant Long_Long_Integer := Signed_32 (GTE.RFC);

      GFC : constant Long_Long_Integer := Signed_32 (GTE.GFC);

      BFC : constant Long_Long_Integer := Signed_32 (GTE.BFC);

      Saved_Flag : Word32 := 0;

      procedure Process_Color (RGB : Word32) is
         R : constant Long_Long_Integer :=
           Long_Long_Integer (RGB and 16#0000_00FF#);

         G : constant Long_Long_Integer :=
           Long_Long_Integer ((RGB / 16#100#) and 16#0000_00FF#);

         B : constant Long_Long_Integer :=
           Long_Long_Integer ((RGB / 16#10_000#) and 16#0000_00FF#);

         Code : constant Word32 := RGB and 16#FF00_0000#;

         Base1 : Long_Long_Integer;
         Base2 : Long_Long_Integer;
         Base3 : Long_Long_Integer;

         Delta1 : Long_Long_Integer;
         Delta2 : Long_Long_Integer;
         Delta3 : Long_Long_Integer;

         MAC1_Raw : Long_Long_Integer;
         MAC2_Raw : Long_Long_Integer;
         MAC3_Raw : Long_Long_Integer;

         MAC1 : Long_Long_Integer;
         MAC2 : Long_Long_Integer;
         MAC3 : Long_Long_Integer;

         RGB_R : Long_Long_Integer;
         RGB_G : Long_Long_Integer;
         RGB_B : Long_Long_Integer;

      begin
         Base1 := R * 16#1000#;
         Base2 := G * 16#1000#;
         Base3 := B * 16#1000#;

         Delta1 := RFC * 16#1000# - Base1;
         Delta2 := GFC * 16#1000# - Base2;
         Delta3 := BFC * 16#1000# - Base3;

         if Delta1 > 32767 then
            Delta1 := 32767;
            Set_Flag (GTE, 30);
         elsif Delta1 < -32768 then
            Delta1 := -32768;
            Set_Flag (GTE, 27);
         end if;

         if Delta2 > 32767 then
            Delta2 := 32767;
            Set_Flag (GTE, 29);
         elsif Delta2 < -32768 then
            Delta2 := -32768;
            Set_Flag (GTE, 26);
         end if;

         if Delta3 > 32767 then
            Delta3 := 32767;
            Set_Flag (GTE, 28);
         elsif Delta3 < -32768 then
            Delta3 := -32768;
            Set_Flag (GTE, 25);
         end if;

         MAC1_Raw := Base1 + Delta1 * IR0;
         MAC2_Raw := Base2 + Delta2 * IR0;
         MAC3_Raw := Base3 + Delta3 * IR0;

         if SF then
            MAC1 := SAR (MAC1_Raw, 12);
            MAC2 := SAR (MAC2_Raw, 12);
            MAC3 := SAR (MAC3_Raw, 12);
         else
            MAC1 := MAC1_Raw;
            MAC2 := MAC2_Raw;
            MAC3 := MAC3_Raw;
         end if;

         GTE.MAC1 := To_Word32 (MAC1);
         GTE.MAC2 := To_Word32 (MAC2);
         GTE.MAC3 := To_Word32 (MAC3);

         GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
         GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
         GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);

         RGB_R := MAC1 / 16;
         RGB_G := MAC2 / 16;
         RGB_B := MAC3 / 16;

         if RGB_R < 0 then
            RGB_R := 0;
            Set_Flag (GTE, 21);
         elsif RGB_R > 255 then
            RGB_R := 255;
            Set_Flag (GTE, 21);
         end if;

         if RGB_G < 0 then
            RGB_G := 0;
            Set_Flag (GTE, 20);
         elsif RGB_G > 255 then
            RGB_G := 255;
            Set_Flag (GTE, 20);
         end if;

         if RGB_B < 0 then
            RGB_B := 0;
            Set_Flag (GTE, 19);
         elsif RGB_B > 255 then
            RGB_B := 255;
            Set_Flag (GTE, 19);
         end if;

         GTE.RGB0 := GTE.RGB1;
         GTE.RGB1 := GTE.RGB2;

         GTE.RGB2 :=
           Code
           or Word32 (RGB_R)
           or Interfaces.Shift_Left (Word32 (RGB_G), 8)
           or Interfaces.Shift_Left (Word32 (RGB_B), 16);

      end Process_Color;

   begin
      GTE.FLAG := 0;

      Process_Color (GTE.RGB0);
      Saved_Flag := GTE.FLAG;

      Process_Color (GTE.RGB1);
      Saved_Flag := Saved_Flag or GTE.FLAG;

      Process_Color (GTE.RGB2);
      Saved_Flag := Saved_Flag or GTE.FLAG;

      GTE.FLAG := Saved_Flag;
   end Execute_DPCT;

   procedure Execute_GPL
     (GTE : in out PSX.GTE.GTE_State; Inst : PSX.GTE.Instruction.Instruction)
   is
      SF : constant Boolean := PSX.GTE.Instruction.Sf (Inst) /= 0;

      LM : constant Boolean := PSX.GTE.Instruction.Lm (Inst) /= 0;

      IR0 : constant Long_Long_Integer := Signed_16 (GTE.IR0);

      IR1 : constant Long_Long_Integer := Signed_16 (GTE.IR1);

      IR2 : constant Long_Long_Integer := Signed_16 (GTE.IR2);

      IR3 : constant Long_Long_Integer := Signed_16 (GTE.IR3);

      Previous_MAC1 : constant Long_Long_Integer := Signed_32 (GTE.MAC1);

      Previous_MAC2 : constant Long_Long_Integer := Signed_32 (GTE.MAC2);

      Previous_MAC3 : constant Long_Long_Integer := Signed_32 (GTE.MAC3);

      MAC1_Raw : Long_Long_Integer;
      MAC2_Raw : Long_Long_Integer;
      MAC3_Raw : Long_Long_Integer;

      MAC1 : Long_Long_Integer;
      MAC2 : Long_Long_Integer;
      MAC3 : Long_Long_Integer;

   begin
      GTE.FLAG := 0;

      MAC1_Raw := Previous_MAC1 + IR0 * IR1;
      MAC2_Raw := Previous_MAC2 + IR0 * IR2;
      MAC3_Raw := Previous_MAC3 + IR0 * IR3;

      if MAC1_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 30);
      elsif MAC1_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 27);
      end if;

      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      elsif MAC2_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 26);
      end if;

      if MAC3_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 28);
      elsif MAC3_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 25);
      end if;

      if SF then
         MAC1 := SAR (MAC1_Raw, 12);
         MAC2 := SAR (MAC2_Raw, 12);
         MAC3 := SAR (MAC3_Raw, 12);
      else
         MAC1 := MAC1_Raw;
         MAC2 := MAC2_Raw;
         MAC3 := MAC3_Raw;
      end if;

      GTE.MAC1 := To_Word32 (MAC1);
      GTE.MAC2 := To_Word32 (MAC2);
      GTE.MAC3 := To_Word32 (MAC3);

      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);

   end Execute_GPL;

   procedure Execute_GPF
     (GTE : in out PSX.GTE.GTE_State; Inst : PSX.GTE.Instruction.Instruction)
   is
      SF : constant Boolean := PSX.GTE.Instruction.Sf (Inst) /= 0;

      LM : constant Boolean := PSX.GTE.Instruction.Lm (Inst) /= 0;

      IR0 : constant Long_Long_Integer := Signed_16 (GTE.IR0);

      IR1 : constant Long_Long_Integer := Signed_16 (GTE.IR1);

      IR2 : constant Long_Long_Integer := Signed_16 (GTE.IR2);

      IR3 : constant Long_Long_Integer := Signed_16 (GTE.IR3);

      MAC1_Raw : Long_Long_Integer;
      MAC2_Raw : Long_Long_Integer;
      MAC3_Raw : Long_Long_Integer;

      MAC1 : Long_Long_Integer;
      MAC2 : Long_Long_Integer;
      MAC3 : Long_Long_Integer;

   begin
      GTE.FLAG := 0;

      MAC1_Raw := IR0 * IR1;
      MAC2_Raw := IR0 * IR2;
      MAC3_Raw := IR0 * IR3;

      if MAC1_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 30);
      elsif MAC1_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 27);
      end if;

      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      elsif MAC2_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 26);
      end if;

      if MAC3_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 28);
      elsif MAC3_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 25);
      end if;

      if SF then
         MAC1 := SAR (MAC1_Raw, 12);
         MAC2 := SAR (MAC2_Raw, 12);
         MAC3 := SAR (MAC3_Raw, 12);
      else
         MAC1 := MAC1_Raw;
         MAC2 := MAC2_Raw;
         MAC3 := MAC3_Raw;
      end if;

      GTE.MAC1 := To_Word32 (MAC1);
      GTE.MAC2 := To_Word32 (MAC2);
      GTE.MAC3 := To_Word32 (MAC3);

      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);
      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);
      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);

   end Execute_GPF;

   procedure Execute
     (GTE : in out PSX.GTE.GTE_State; Inst : PSX.GTE.Instruction.Instruction)
   is

      Command : constant Word32 := PSX.GTE.Instruction.Command (Inst);

   begin

      case Command is

         when 0      =>
            Execute_OP (GTE, Inst);

         when 1      =>
            Execute_RTPS (GTE, Inst);

         when 2      =>
            Execute_AVSZ3 (GTE);

         when 3      =>
            Execute_AVSZ4 (GTE);

         when 6      =>
            Execute_NCLIP (GTE);

         when 12     =>
            Execute_MVMVA (GTE, Inst);

         when 16#10# =>
            Execute_DPCS (GTE, Inst);

         when 16#11# =>
            Execute_INTPL (GTE, Inst);

         when 16#13# =>
            Execute_NCDS (GTE, Inst);

         when 16#14# =>
            Execute_CDP (GTE, Inst);

         when 16#16# =>
            Execute_NCDT (GTE, Inst);

         when 16#1B# =>
            Execute_NCCS (GTE, Inst);

         when 16#1C# =>
            Execute_CC (GTE, Inst);

         when 16#1E# =>
            Execute_NCS (GTE, Inst);

         when 16#20# =>
            Execute_NCT (GTE, Inst);

         when 16#28# =>
            Execute_SQR (GTE, Inst);

         when 16#29# =>
            Execute_DCPL (GTE, Inst);

         when 16#2A# =>
            Execute_DPCT (GTE, Inst);

         when 16#30# =>
            Execute_RTPT (GTE, Inst);

         when 16#3D# =>
            Execute_GPF (GTE, Inst);

         when 16#3E# =>
            Execute_GPL (GTE, Inst);

         when 16#3F# =>
            Execute_NCCT (GTE, Inst);

         when others =>
            null;
      end case;

   end Execute;

end PSX.GTE.Execute;
