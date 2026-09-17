with Ada.Text_IO;
with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with Interfaces;

procedure PSX_CPU_LWR_Delay_Tests is

   use type Interfaces.Unsigned_32;
   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

begin
   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.Registers (1) := 16#0000_0100#;
   CPU.Registers (2) := 16#AABB_CCDD#;

   --  Memoria = 11 22 33 44
   PSX.Memory.Write_32 (Memory, 16#0000_0100#, 16#1122_3344#);

   --  LWR R2, 3(R1)
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#9822_0003#);

   --  NOP
   PSX.Memory.Write_32 (Memory, 16#0001_0004#, 16#0000_0000#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   --  Ejecutar LWR.
   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (2) = 16#AABB_CCDD# then
      Ada.Text_IO.Put_Line ("PASS: LWR delay before");
   else
      Ada.Text_IO.Put_Line ("FAIL: LWR delay before");
   end if;

   if CPU.Load_Pending then
      Ada.Text_IO.Put_Line ("PASS: LWR pending");
   else
      Ada.Text_IO.Put_Line ("FAIL: LWR pending");
   end if;

   --  Ejecutar NOP.
   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (2) = 16#AABB_CC11# then
      Ada.Text_IO.Put_Line ("PASS: LWR result after delay");
   else
      Ada.Text_IO.Put_Line ("FAIL: LWR result after delay");
   end if;

   Ada.Text_IO.Put_Line ("PSX CPU LWR delay tests finished.");

end PSX_CPU_LWR_Delay_Tests;
