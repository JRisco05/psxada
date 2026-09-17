with Ada.Text_IO;
with Interfaces;
with PSX.GTE;
with PSX.GTE.Instruction;
with PSX.GTE.Execute;

procedure PSX_GTE_RTPS_Overflow_Tests is

   use Ada.Text_IO;
   use type Interfaces.Unsigned_32;

   GTE : PSX.GTE.GTE_State;

   procedure Check
     (Name     : String;
      Expected : Interfaces.Unsigned_32;
      Actual   : Interfaces.Unsigned_32) is
   begin
      if Expected = Actual then
         Put_Line ("PASS: " & Name);
      else
         Put_Line
           ("FAIL: " & Name &
            " expected=0x" & Interfaces.Unsigned_32'Image (Expected) &
            " actual=0x" & Interfaces.Unsigned_32'Image (Actual));
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

      GTE.H   := 1000;
      GTE.DQA := 0;
      GTE.DQB := 0;
   end Setup_Identity;

   Inst : PSX.GTE.Instruction.Instruction;

begin
   Put_Line ("Testing PSX GTE RTPS overflow...");
   New_Line;

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
  Check
  ("Negative Z divide overflow",
   16#8006_0000#,
   GTE.FLAG);

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

   New_Line;
   Put_Line ("PSX GTE RTPS overflow tests finished.");

end PSX_GTE_RTPS_Overflow_Tests;