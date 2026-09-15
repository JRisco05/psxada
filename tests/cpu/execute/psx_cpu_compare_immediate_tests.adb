with Ada.Text_IO; use Ada.Text_IO;

with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with PSX.Types;
with Interfaces;

procedure PSX_CPU_Compare_Immediate_Tests is

   use type Interfaces.Unsigned_32;

   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

   procedure Check
     (Name : String; Expected : PSX.Types.Word32; Actual : PSX.Types.Word32) is
   begin
      if Actual = Expected then
         Put_Line ("PASS: " & Name);
      else
         Put_Line ("FAIL: " & Name);
      end if;
   end Check;

begin

   Put_Line ("Testing PSX CPU comparison immediate instructions...");
   New_Line;

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   -- SLTI R3, R1, -1
   -- R1 = -2
   -- -2 < -1 => 1
   CPU.Registers (1) := 16#FFFF_FFFE#;

   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#2823_FFFF#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("SLTI signed", 1, CPU.Registers (3));

   -- SLTIU R3, R1, -1
   -- R1 = 1
   -- Immediate sign-extended = 0xFFFFFFFF
   -- 1 < 0xFFFFFFFF unsigned => 1
   CPU.Registers (1) := 1;

   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#2C23_FFFF#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("SLTIU unsigned", 1, CPU.Registers (3));

   Put_Line ("");
   Put_Line ("PSX CPU comparison immediate tests finished.");

end PSX_CPU_Compare_Immediate_Tests;
