with Ada.Text_IO; use Ada.Text_IO;

with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with PSX.Types;
with Interfaces;

procedure PSX_CPU_Add_Immediate_Tests is

   use type Interfaces.Unsigned_32;
   use type PSX.CPU.Exception_Code;

   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

   procedure Check
     (Name : String; Expected : PSX.Types.Word32; Actual : PSX.Types.Word32) is
   begin
      if Actual = Expected then
         Put_Line ("PASS: " & Name);
      else
         Put_Line ("FAIL: " & Name);
         Put_Line ("  Expected = " & PSX.Types.Word32'Image (Expected));
         Put_Line ("  Actual   = " & PSX.Types.Word32'Image (Actual));
      end if;
   end Check;

begin

   Put_Line ("Testing PSX CPU immediate arithmetic instructions...");
   New_Line;

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   -- ADDI R3, R1, -1
   -- 5 + (-1) = 4
   CPU.Registers (1) := 5;

   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#2023_FFFF#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("ADDI sign extension", 4, CPU.Registers (3));

   -- ADDIU R3, R1, -1
   -- 0 + (-1) = 0xFFFFFFFF
   CPU.Registers (1) := 0;

   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#2423_FFFF#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("ADDIU sign extension", 16#FFFF_FFFF#, CPU.Registers (3));

   -- ADDI overflow
   -- 0x7FFFFFFF + 1 => signed overflow
   CPU.Registers (1) := 16#7FFF_FFFF#;
   CPU.Registers (3) := 16#1234_5678#;

   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#2023_0001#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;
   CPU.Exception_Pending := False;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Cause = PSX.CPU.Overflow then
      Put_Line ("PASS: ADDI overflow");
   else
      Put_Line ("FAIL: ADDI overflow");
   end if;

   Put_Line ("");
   Put_Line ("PSX CPU immediate arithmetic tests finished.");

end PSX_CPU_Add_Immediate_Tests;
