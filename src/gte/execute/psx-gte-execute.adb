with PSX.Types;
with Interfaces;

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
         return -((-Value) / Divisor);
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

      GTE.IR1 := Saturate_IR (GTE, MAC1, 24, LM);

      GTE.IR2 := Saturate_IR (GTE, MAC2, 23, LM);

      GTE.IR3 := Saturate_IR (GTE, MAC3, 22, LM);

      --  -------------------------------------------------------
      --  SZ FIFO
      --  -------------------------------------------------------

      SZ3_Value := SAR (MAC3_Raw, 12);

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

      GTE.MAC0 := To_Word32 (MAC0);

      GTE.SY2 := Saturate_Screen (GTE, SAR (MAC0, 16), 13);

      --  -------------------------------------------------------
      --  Depth cue
      --  -------------------------------------------------------

      MAC0 := Perspective * DQA_Value + DQB_Value;

      GTE.MAC0 := To_Word32 (MAC0);

      GTE.IR0 :=
        To_Word32
          (Long_Long_Integer'Min
             (16#1000#, Long_Long_Integer'Max (0, SAR (MAC0, 12))));

      if SAR (MAC0, 12) < 0 or else SAR (MAC0, 12) > 16#1000# then
         Set_Flag (GTE, 12);
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
         Set_Flag (GTE, 30);
      end if;

      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      elsif MAC2_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 29);
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
      -- Inicializamos el FLAG en 0 (NCLIP limpia banderas previas de geometría)
      GTE.FLAG := 0;

      -- Fórmula matemática nativa LLE de la PS1 para el producto cruzado 2D
      MAC0_Raw :=
        Interfaces.Integer_64 (X0) * Interfaces.Integer_64 (Y1)
        + Interfaces.Integer_64 (X1) * Interfaces.Integer_64 (Y2)
        + Interfaces.Integer_64 (X2) * Interfaces.Integer_64 (Y0)
        - Interfaces.Integer_64 (X0) * Interfaces.Integer_64 (Y2)
        - Interfaces.Integer_64 (X1) * Interfaces.Integer_64 (Y0)
        - Interfaces.Integer_64 (X2) * Interfaces.Integer_64 (Y1);

      -- Validación matemática estricta de saturación de 32 bits con signo
      if MAC0_Raw > 2147483647 then
         Set_Flag (GTE, 16); -- Activa el bit 16 en el FLAG
         GTE.MAC0 := 16#7FFF_FFFF#;
      elsif MAC0_Raw < -2147483648 then
         Set_Flag (GTE, 16);
         GTE.MAC0 := 16#8000_0000#;
      else
         -- Si no hay desbordamiento, hacemos el cast seguro a Word32
         GTE.MAC0 := To_Word32 (Long_Long_Integer (MAC0_Raw));
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
         Set_Flag (GTE, 30);
      end if;

      if MAC2_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 29);
      elsif MAC2_Raw < -16#800_0000_0000# then
         Set_Flag (GTE, 29);
      end if;

      if MAC3_Raw > 16#7FF_FFFF_FFFF# then
         Set_Flag (GTE, 28);
      elsif MAC3_Raw < -16#800_0000_0000# then
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

         when 16#30# =>
            Execute_RTPT (GTE, Inst);

         when others =>
            null;
      end case;

   end Execute;

end PSX.GTE.Execute;
