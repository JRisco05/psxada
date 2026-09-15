with Ada.Text_IO;
with Interfaces;
with PSX.CPU;
with PSX.CPU.MulDiv;

procedure Psx_CPU_MulDiv_Tests is

   use Ada.Text_IO;
   use type Interfaces.Unsigned_32;

   CPU : PSX.CPU.CPU_State;

   procedure Check (Name : String; Condition : Boolean) is
   begin
      if Condition then
         Put_Line ("PASS: " & Name);
      else
         Put_Line ("FAIL: " & Name);
      end if;
   end Check;

begin

   Put_Line ("Testing PSX.CPU.MulDiv...");
   New_Line;

   PSX.CPU.Reset (CPU);

   --  MULT: 2 * 3 = 6
   PSX.CPU.MulDiv.Start_Multiply (CPU, 2, 3, True);

   Check ("MULT HI = 0", CPU.HI = 0);

   Check ("MULT LO = 6", CPU.LO = 6);

   Check ("MULT busy", CPU.MulDiv_Busy);

   Check ("MULT cycles = 6", CPU.MulDiv_Cycles = 6);

   --  Complete the operation.
   PSX.CPU.MulDiv.Tick (CPU, 6);

   Check ("MULT completed", not CPU.MulDiv_Busy);

   Check ("MULT cycles = 0", CPU.MulDiv_Cycles = 0);

   New_Line;

   --  MULTU: 0xFFFFFFFF * 2
   PSX.CPU.MulDiv.Start_Multiply (CPU, 16#FFFF_FFFF#, 2, False);

   Check ("MULTU HI", CPU.HI = 1);

   Check ("MULTU LO", CPU.LO = 16#FFFF_FFFE#);

   Check ("MULTU cycles = 13", CPU.MulDiv_Cycles = 13);

   PSX.CPU.MulDiv.Tick (CPU, 13);

   Check ("MULTU completed", not CPU.MulDiv_Busy);

   New_Line;

   --  DIV: 20 / 3
   PSX.CPU.MulDiv.Start_Divide (CPU, 20, 3, True);

   Check ("DIV quotient = 6", CPU.LO = 6);

   Check ("DIV remainder = 2", CPU.HI = 2);

   Check ("DIV cycles = 36", CPU.MulDiv_Cycles = 36);

   PSX.CPU.MulDiv.Tick (CPU, 36);

   Check ("DIV completed", not CPU.MulDiv_Busy);

   New_Line;

   --  DIVU: 20 / 3
   PSX.CPU.MulDiv.Start_Divide (CPU, 20, 3, False);

   Check ("DIVU quotient = 6", CPU.LO = 6);

   Check ("DIVU remainder = 2", CPU.HI = 2);

   Check ("DIVU cycles = 36", CPU.MulDiv_Cycles = 36);

   PSX.CPU.MulDiv.Tick (CPU, 36);

   Check ("DIVU completed", not CPU.MulDiv_Busy);

   New_Line;

   Put_Line ("MulDiv tests finished.");

end Psx_CPU_MulDiv_Tests;
