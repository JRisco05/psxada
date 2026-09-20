with Ada.Text_IO;
with PSX.GTE;
with PSX.GTE.Execute;
with PSX.GTE.Instruction;
with PSX.Types;
with Interfaces;

procedure PSX_GTE_RTPS_Tests_Complete is

   use type Interfaces.Unsigned_32;

   use Ada.Text_IO;

   GTE : PSX.GTE.GTE_State;

   Inst : PSX.GTE.Instruction.Instruction;

   procedure Check
     (Name : String; Actual : PSX.Types.Word32; Expected : PSX.Types.Word32) is
   begin
      if Actual = Expected then
         Put_Line ("PASS: " & Name);
      else
         Put_Line
           ("FAIL: "
            & Name
            & " expected="
            & PSX.Types.Word32'Image (Expected)
            & " actual="
            & PSX.Types.Word32'Image (Actual));
      end if;
   end Check;

   procedure Setup_Identity is
   begin
      PSX.GTE.Reset (GTE);

      GTE.RT11 := 16#0000_1000#;
      GTE.RT22 := 16#0000_1000#;
      GTE.RT33 := 16#0000_1000#;

      GTE.TRX := 0;
      GTE.TRY := 0;
      GTE.TRZ := 0;

      GTE.OFX := 0;
      GTE.OFY := 0;

      GTE.H := 1000;
      GTE.DQA := 0;
      GTE.DQB := 0;
   end Setup_Identity;

begin

   Put_Line ("Testing PSX GTE RTPS...");
   New_Line;

   PSX.GTE.Reset (GTE);

   --  =========================================================
   --  Identity rotation matrix.
   --  1.0 in GTE fixed point = 0x1000.
   --  =========================================================

   PSX.GTE.Write_Control (GTE, 32, 16#0000_1000#);

   PSX.GTE.Write_Control (GTE, 33, 16#0000_0000#);

   PSX.GTE.Write_Control (GTE, 34, 16#0000_1000#);

   PSX.GTE.Write_Control (GTE, 35, 16#0000_0000#);

   PSX.GTE.Write_Control (GTE, 36, 16#0000_1000#);

   --  Translation = 0.
   PSX.GTE.Write_Control (GTE, 37, 0);

   PSX.GTE.Write_Control (GTE, 38, 0);

   PSX.GTE.Write_Control (GTE, 39, 0);

   --  Screen offset = 0.
   PSX.GTE.Write_Control (GTE, 56, 0);

   PSX.GTE.Write_Control (GTE, 57, 0);

   --  H = 1000.
   PSX.GTE.Write_Control (GTE, 58, 1000);

   --  DQA/DQB = 0.
   PSX.GTE.Write_Control (GTE, 59, 0);

   PSX.GTE.Write_Control (GTE, 60, 0);

   --  Vertex V0 = (100, 200, 1000).
   PSX.GTE.Write_Data (GTE, 0, 16#00C8_0064#);

   PSX.GTE.Write_Data (GTE, 1, 1000);

   --  Preload FIFOs so we can verify the shift.
   PSX.GTE.Write_Data (GTE, 16, 1);

   PSX.GTE.Write_Data (GTE, 17, 2);

   PSX.GTE.Write_Data (GTE, 18, 3);

   PSX.GTE.Write_Data (GTE, 19, 4);

   --  RTPS command:
   --  command = 01h
   --  sf = 1
   --  lm = 0
   Inst.Raw := 16#0008_0001#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   --  =========================================================
   --  Rotation / translation
   --  =========================================================

   Check ("IR1", GTE.IR1, 100);

   Check ("IR2", GTE.IR2, 200);

   Check ("IR3", GTE.IR3, 1000);

   Check ("MAC1", GTE.MAC1, 100);

   Check ("MAC2", GTE.MAC2, 200);

   Check ("MAC3", GTE.MAC3, 1000);

   --  =========================================================
   --  SZ FIFO
   --  =========================================================

   Check ("SZ0 FIFO", GTE.SZ0, 2);

   Check ("SZ1 FIFO", GTE.SZ1, 3);

   Check ("SZ2 FIFO", GTE.SZ2, 4);

   Check ("SZ3 FIFO", GTE.SZ3, 1000);

   --  =========================================================
   --  Perspective projection
   --
   --  H = 1000
   --  SZ3 = 1000
   --  factor = 65536
   --
   --  SX = 100
   --  SY = 200
   --  =========================================================

   Check ("SX2", GTE.SX2, 100);

   Check ("SY2", GTE.SY2, 200);

   --  =========================================================
   --  Depth cue
   --  =========================================================

   Check ("IR0", GTE.IR0, 0);

   --  No saturation expected.
   Check ("FLAG", GTE.FLAG, 0);

   ------------------------------------------------------------------
   --  1. Saturación SX2 positiva
   ------------------------------------------------------------------

   Setup_Identity;

   GTE.V0_X := 16#0000_7FFF#;
   GTE.V0_Y := 0;
   GTE.V0_Z := 1000;

   Inst.Raw := 16#0008_0001#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   Check ("SX2 positive saturation", 16#0000_03FF#, GTE.SX2);
   Check ("FLAG SX2 saturation", 16#0000_4000#, GTE.FLAG);

   ------------------------------------------------------------------
   --  2. Saturación SY2 positiva
   ------------------------------------------------------------------

   Setup_Identity;

   GTE.V0_X := 0;
   GTE.V0_Y := 16#0000_7FFF#;
   GTE.V0_Z := 1000;

   PSX.GTE.Execute.Execute (GTE, Inst);

   Check ("SY2 positive saturation", 16#0000_03FF#, GTE.SY2);
   Check ("FLAG SY2 saturation", 16#0000_2000#, GTE.FLAG);

   ------------------------------------------------------------------
   --  3. Saturación SX2 negativa
   ------------------------------------------------------------------

   Setup_Identity;

   GTE.V0_X := 16#FFFF_8000#;
   GTE.V0_Y := 0;
   GTE.V0_Z := 1000;

   PSX.GTE.Execute.Execute (GTE, Inst);

   Check ("SX2 negative saturation", 16#FFFF_FC00#, GTE.SX2);
   Check ("FLAG SX2 negative saturation", 16#0000_4000#, GTE.FLAG);

   ------------------------------------------------------------------
   --  4. Saturación SY2 negativa
   ------------------------------------------------------------------

   Setup_Identity;

   GTE.V0_X := 0;
   GTE.V0_Y := 16#FFFF_8000#;
   GTE.V0_Z := 1000;

   PSX.GTE.Execute.Execute (GTE, Inst);

   Check ("SY2 negative saturation", 16#FFFF_FC00#, GTE.SY2);
   Check ("FLAG SY2 negative saturation", 16#0000_2000#, GTE.FLAG);

   ------------------------------------------------------------------
   --  5. SZ3 = 0 -> saturación + división por cero
   ------------------------------------------------------------------

   Setup_Identity;

   GTE.V0_X := 100;
   GTE.V0_Y := 200;
   GTE.V0_Z := 0;

   PSX.GTE.Execute.Execute (GTE, Inst);

   Check ("SZ3 zero", 0, GTE.SZ3);
   Check
     ("FLAG SZ3 saturation + divide overflow",
      16#0002_0000# or 16#8000_0000#,
      GTE.FLAG);

   ------------------------------------------------------------------
   --  6. Z negativo -> SZ3 saturado a cero
   ------------------------------------------------------------------

   Setup_Identity;

   GTE.V0_X := 100;
   GTE.V0_Y := 200;
   GTE.V0_Z := 16#FFFF_FF9C#; -- -100

   PSX.GTE.Execute.Execute (GTE, Inst);

   Check ("Negative Z -> SZ3 zero", 0, GTE.SZ3);
   Check ("Negative Z divide overflow", 16#8006_0000#, GTE.FLAG);

   ------------------------------------------------------------------
   --  7. SZ3 dentro del rango
   ------------------------------------------------------------------

   Setup_Identity;

   GTE.V0_X := 100;
   GTE.V0_Y := 200;
   GTE.V0_Z := 0;
   GTE.TRZ := 16#0000_FFFF#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   Check ("SZ3 maximum valid", 16#0000_FFFF#, GTE.SZ3);

   Put_Line ("");
   Put_Line ("PSX GTE RTPS tests finished.");

   ------------------------------------------------------------------
   --  1. Valores negativos
   ------------------------------------------------------------------

   Setup_Identity;

   GTE.V0_X := 16#FFFF_FF9C#; -- -100
   GTE.V0_Y := 16#FFFF_FF38#; -- -200
   GTE.V0_Z := 1000;

   Inst.Raw := 16#0008_0001#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   Check ("Negative IR1", 16#FFFF_FF9C#, GTE.IR1);
   Check ("Negative IR2", 16#FFFF_FF38#, GTE.IR2);
   Check ("Negative IR3", 1000, GTE.IR3);

   ------------------------------------------------------------------
   --  2. Translation
   ------------------------------------------------------------------

   Setup_Identity;

   GTE.V0_X := 100;
   GTE.V0_Y := 200;
   GTE.V0_Z := 1000;

   GTE.TRX := 50;
   GTE.TRY := 25;
   GTE.TRZ := 100;

   PSX.GTE.Execute.Execute (GTE, Inst);

   Check ("Translation IR1", 150, GTE.IR1);
   Check ("Translation IR2", 225, GTE.IR2);
   Check ("Translation IR3", 1100, GTE.IR3);

   ------------------------------------------------------------------
   --  3. Saturación IR positiva
   ------------------------------------------------------------------

   Setup_Identity;

   GTE.V0_X := 16#0000_7FFF#;
   GTE.V0_Y := 16#0000_7FFF#;
   GTE.V0_Z := 16#0000_7FFF#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   Check ("IR1 positive saturation", 16#0000_7FFF#, GTE.IR1);
   Check ("IR2 positive saturation", 16#0000_7FFF#, GTE.IR2);
   Check ("IR3 positive saturation", 16#0000_7FFF#, GTE.IR3);

   ------------------------------------------------------------------
   --  4. Saturación IR negativa con LM=0
   ------------------------------------------------------------------

   Setup_Identity;

   GTE.V0_X := 16#FFFF_8000#;
   GTE.V0_Y := 16#FFFF_8000#;
   GTE.V0_Z := 16#FFFF_8000#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   Check ("IR1 negative saturation", 16#FFFF_8000#, GTE.IR1);
   Check ("IR2 negative saturation", 16#FFFF_8000#, GTE.IR2);
   Check ("IR3 negative saturation", 16#FFFF_8000#, GTE.IR3);

   ------------------------------------------------------------------
   --  5. LM = 1
   ------------------------------------------------------------------

   Setup_Identity;

   GTE.V0_X := 16#FFFF_8000#;
   GTE.V0_Y := 16#FFFF_8000#;
   GTE.V0_Z := 16#FFFF_8000#;

   --  Command 01 + SF=1 + LM=1
   Inst.Raw := 16#0008_0401#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   Check ("LM IR1 clamps to zero", 0, GTE.IR1);
   Check ("LM IR2 clamps to zero", 0, GTE.IR2);
   Check ("LM IR3 clamps to zero", 0, GTE.IR3);

   ------------------------------------------------------------------
   --  6. SF = 0
   ------------------------------------------------------------------

   Setup_Identity;

   GTE.V0_X := 100;
   GTE.V0_Y := 200;
   GTE.V0_Z := 1000;

   --  Command 01, SF=0
   Inst.Raw := 16#0000_0001#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   Check ("SF=0 IR1", 16#0000_7FFF#, GTE.IR1);
   Check ("SF=0 IR2", 16#0000_7FFF#, GTE.IR2);
   Check ("SF=0 IR3", 16#0000_7FFF#, GTE.IR3);

end PSX_GTE_RTPS_Tests_Complete;
