with Ada.Text_IO; use Ada.Text_IO;
with Interfaces;

with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;

procedure PSX_CPU_COP0_MFC0_Tests is

   use type Interfaces.Unsigned_32;

   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

begin
   Put_Line ("Testing PSX CPU COP0 MFC0...");
   New_Line;

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   --  MFC0 R2, $12
   CPU.Status := 16#1234_5678#;

   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#4002_6000#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (2) = 16#1234_5678# then
      Put_Line ("PASS: MFC0 Status");
   else
      Put_Line ("FAIL: MFC0 Status");
   end if;

   --  MFC0 R3, $14
   CPU.EPC := 16#8000_1234#;

   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#4003_7000#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (3) = 16#8000_1234# then
      Put_Line ("PASS: MFC0 EPC");
   else
      Put_Line ("FAIL: MFC0 EPC");
   end if;

   New_Line;
   Put_Line ("PSX CPU COP0 MFC0 tests finished.");

end PSX_CPU_COP0_MFC0_Tests;
