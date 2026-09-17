with Ada.Text_IO;
with Interfaces;
with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;

procedure Psx_CPU_MulDiv_Stall_Tests is

   use Ada.Text_IO;
   use type Interfaces.Unsigned_32;

   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

   procedure Check (Name : String; Condition : Boolean) is
   begin
      if Condition then
         Put_Line ("PASS: " & Name);
      else
         Put_Line ("FAIL: " & Name);
      end if;
   end Check;

begin

   Put_Line ("Testing PSX.CPU.MulDiv division timing...");
   New_Line;

   ----------------------------------------------------------------
   --  DIV
   ----------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0000_0000#;
   CPU.Next_PC := 16#0000_0004#;

   CPU.Registers (1) := 20;
   CPU.Registers (2) := 3;

   --  DIV R1, R2
   --  opcode = 0
   --  rs     = 1
   --  rt     = 2
   --  funct  = 26
   PSX.Memory.Write_32 (Memory, 16#0000_0000#, 16#0022_001A#);

   --  MFLO R3
   PSX.Memory.Write_32 (Memory, 16#0000_0004#, 16#0000_1812#);

   --  MFHI R4
   PSX.Memory.Write_32 (Memory, 16#0000_0008#, 16#0000_2010#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("DIV busy", CPU.MulDiv_Busy);

   Check ("DIV remaining cycles", CPU.MulDiv_Cycles = 35);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("DIV MFLO result", CPU.Registers (3) = 6);

   Check ("DIV completed", not CPU.MulDiv_Busy);

   ----------------------------------------------------------------
   --  DIVU
   ----------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0000_0000#;
   CPU.Next_PC := 16#0000_0004#;

   CPU.Registers (1) := 20;
   CPU.Registers (2) := 3;

   --  DIVU R1, R2
   --  funct = 27
   PSX.Memory.Write_32 (Memory, 16#0000_0000#, 16#0022_001B#);

   --  MFLO R3
   PSX.Memory.Write_32 (Memory, 16#0000_0004#, 16#0000_1812#);

   --  MFHI R4
   PSX.Memory.Write_32 (Memory, 16#0000_0008#, 16#0000_2010#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("DIVU busy", CPU.MulDiv_Busy);

   Check ("DIVU remaining cycles", CPU.MulDiv_Cycles = 35);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("DIVU MFLO result", CPU.Registers (3) = 6);

   Check ("DIVU completed", not CPU.MulDiv_Busy);

   New_Line;
   Put_Line ("MulDiv division timing tests finished.");

end Psx_CPU_MulDiv_Stall_Tests;
