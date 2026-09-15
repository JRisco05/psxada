with Ada.Text_IO;
with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with Interfaces;

procedure PSX_CPU_LWL_LWR_Delay_Tests is

   use type Interfaces.Unsigned_32;
   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

begin
   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.Registers (1) := 16#0000_0100#;
   CPU.Registers (2) := 16#0000_0000#;

   -- Palabra de prueba.
   PSX.Memory.Write_32 (Memory, 16#0000_0100#, 16#1122_3344#);

   -- LWL R2, 3(R1)
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#8822_0003#);

   -- LWR R2, 0(R1)
   PSX.Memory.Write_32 (Memory, 16#0001_0004#, 16#9822_0000#);

   -- NOP
   PSX.Memory.Write_32 (Memory, 16#0001_0008#, 16#0000_0000#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   -- LWL
   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (2) = 0 then
      Ada.Text_IO.Put_Line ("PASS: LWL not committed immediately");
   else
      Ada.Text_IO.Put_Line ("FAIL: LWL committed immediately");
   end if;

   -- LWR
   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Load_Pending then
      Ada.Text_IO.Put_Line ("PASS: LWR pending");
   else
      Ada.Text_IO.Put_Line ("FAIL: LWR pending");
   end if;

   -- Aplicar resultado.
   PSX.CPU.Step.Step (CPU, Memory);

   Ada.Text_IO.Put_Line ("LWR pending = 0x" & CPU.Load_Value'Image);
   Ada.Text_IO.Put_Line ("LWL pending = 0x" & CPU.Load_Value'Image);

   Ada.Text_IO.Put_Line ("R2 = 0x" & CPU.Registers (2)'Image);

   if CPU.Registers (2) = 16#1122_3344# then
      Ada.Text_IO.Put_Line ("PASS: LWL + LWR reconstructed word");
   else
      Ada.Text_IO.Put_Line ("FAIL: LWL + LWR reconstructed word");
   end if;

   Ada.Text_IO.Put_Line ("PSX CPU LWL/LWR delay tests finished.");

end PSX_CPU_LWL_LWR_Delay_Tests;
