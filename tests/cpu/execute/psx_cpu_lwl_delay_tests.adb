with Ada.Text_IO;
with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with Interfaces;

procedure PSX_CPU_LWL_Delay_Tests is

   use type Interfaces.Unsigned_32;
   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

begin
   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   --  R1 = dirección base
   CPU.Registers (1) := 16#0000_0100#;

   --  Valor inicial de R2.
   CPU.Registers (2) := 16#AABB_CCDD#;

   --  Memoria:
   --  0x100 = 11
   --  0x101 = 22
   --  0x102 = 33
   --  0x103 = 44
   PSX.Memory.Write_32 (Memory, 16#0000_0100#, 16#1122_3344#);

   --  LWL R2, 0(R1)
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#8822_0000#);

   --  NOP
   PSX.Memory.Write_32 (Memory, 16#0001_0004#, 16#0000_0000#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   --  Ejecutar LWL.
   PSX.CPU.Step.Step (CPU, Memory);

   --  Debe conservar el valor antiguo durante el delay.
   if CPU.Registers (2) = 16#AABB_CCDD# then
      Ada.Text_IO.Put_Line ("PASS: LWL delay before");
   else
      Ada.Text_IO.Put_Line ("FAIL: LWL delay before");
   end if;

   if CPU.Load_Pending then
      Ada.Text_IO.Put_Line ("PASS: LWL pending");
   else
      Ada.Text_IO.Put_Line ("FAIL: LWL pending");
   end if;

   --  Ejecutar NOP: aquí se aplica el resultado.
   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (2) = 16#44BB_CCDD# then
      Ada.Text_IO.Put_Line ("PASS: LWL result after delay");
   else
      Ada.Text_IO.Put_Line ("FAIL: LWL result after delay");
   end if;

   Ada.Text_IO.Put_Line ("PSX CPU LWL delay tests finished.");

end PSX_CPU_LWL_Delay_Tests;
