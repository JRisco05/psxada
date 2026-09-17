with Ada.Text_IO; use Ada.Text_IO;
with PSX.GTE;
with PSX.GTE.Execute;
with PSX.GTE.Instruction;

procedure PSX_GTE_Execute_Tests is

   GTE  : PSX.GTE.GTE_State;
   Inst : PSX.GTE.Instruction.Instruction;

begin
   Put_Line ("Testing PSX GTE execute...");
   New_Line;

   PSX.GTE.Reset (GTE);

   Inst.Raw := 16#0000_0010#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   Put_Line ("PASS: GTE execute call");

   New_Line;
   Put_Line ("PSX GTE execute tests finished.");

end PSX_GTE_Execute_Tests;
