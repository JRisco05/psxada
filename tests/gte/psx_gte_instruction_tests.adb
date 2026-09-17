with Ada.Text_IO; use Ada.Text_IO;
with Interfaces;

with PSX.GTE.Instruction;

procedure PSX_GTE_Instruction_Tests is

   use type Interfaces.Unsigned_32;

   Inst : PSX.GTE.Instruction.Instruction;

begin
   Put_Line ("Testing PSX GTE instruction decoder...");
   New_Line;

   --  Command = 16
   --  Sf = 1
   --  Mx = 2
   --  V = 1
   --  Cv = 3
   --  Lm = 1
   Inst.Raw :=
     16#0000_0010#
     or Interfaces.Shift_Left (1, 19)
     or Interfaces.Shift_Left (2, 17)
     or Interfaces.Shift_Left (1, 15)
     or Interfaces.Shift_Left (3, 13)
     or Interfaces.Shift_Left (1, 10);

   if PSX.GTE.Instruction.Command (Inst) = 16 then
      Put_Line ("PASS: GTE command");
   else
      Put_Line ("FAIL: GTE command");
   end if;

   if PSX.GTE.Instruction.Sf (Inst) = 1 then
      Put_Line ("PASS: GTE SF");
   else
      Put_Line ("FAIL: GTE SF");
   end if;

   if PSX.GTE.Instruction.Mx (Inst) = 2 then
      Put_Line ("PASS: GTE MX");
   else
      Put_Line ("FAIL: GTE MX");
   end if;

   if PSX.GTE.Instruction.V (Inst) = 1 then
      Put_Line ("PASS: GTE V");
   else
      Put_Line ("FAIL: GTE V");
   end if;

   if PSX.GTE.Instruction.Cv (Inst) = 3 then
      Put_Line ("PASS: GTE CV");
   else
      Put_Line ("FAIL: GTE CV");
   end if;

   if PSX.GTE.Instruction.Lm (Inst) = 1 then
      Put_Line ("PASS: GTE LM");
   else
      Put_Line ("FAIL: GTE LM");
   end if;

   New_Line;
   Put_Line ("PSX GTE instruction decoder tests finished.");

end PSX_GTE_Instruction_Tests;
