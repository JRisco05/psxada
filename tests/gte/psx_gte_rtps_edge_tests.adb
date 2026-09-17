with Ada.Text_IO;
with Interfaces;
with PSX.GTE;
with PSX.GTE.Instruction;
with PSX.GTE.Execute;

procedure PSX_GTE_RTPS_Edge_Tests is

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
   Put_Line ("Testing PSX GTE RTPS edge cases...");
   New_Line;

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

   New_Line;
   Put_Line ("PSX GTE RTPS edge tests finished.");

end PSX_GTE_RTPS_Edge_Tests;