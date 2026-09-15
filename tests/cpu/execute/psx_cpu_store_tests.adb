with Ada.Text_IO;
with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with Interfaces;

procedure PSX_CPU_Store_Tests is

   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;

   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

begin

   ------------------------------------------------------------------
   -- SB
   ------------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.Registers (1) := 16#0000_0100#;
   CPU.Registers (2) := 16#AABB_CCDD#;

   -- SB R2, 0(R1)
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#A022_0000#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   if PSX.Memory.Read_8 (Memory, 16#0000_0100#) = 16#DD# then
      Ada.Text_IO.Put_Line ("PASS: SB");
   else
      Ada.Text_IO.Put_Line ("FAIL: SB");
   end if;

   ------------------------------------------------------------------
   -- SH
   ------------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.Registers (1) := 16#0000_0100#;
   CPU.Registers (2) := 16#AABB_CCDD#;

   -- SH R2, 0(R1)
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#A422_0000#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   if PSX.Memory.Read_16 (Memory, 16#0000_0100#) = 16#CCDD# then
      Ada.Text_IO.Put_Line ("PASS: SH");
   else
      Ada.Text_IO.Put_Line ("FAIL: SH");
   end if;

   ------------------------------------------------------------------
   -- SW
   ------------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.Registers (1) := 16#0000_0100#;
   CPU.Registers (2) := 16#AABB_CCDD#;

   -- SW R2, 0(R1)
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#AC22_0000#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   if PSX.Memory.Read_32 (Memory, 16#0000_0100#) = 16#AABB_CCDD# then
      Ada.Text_IO.Put_Line ("PASS: SW");
   else
      Ada.Text_IO.Put_Line ("FAIL: SW");
   end if;

   Ada.Text_IO.Put_Line ("PSX CPU store tests finished.");

end PSX_CPU_Store_Tests;
