with Ada.Text_IO;
with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with Interfaces;

procedure PSX_CPU_LBU_Delay_Tests is

   use type Interfaces.Unsigned_32;

   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

begin
   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   --  R1 = 0x00000100
   CPU.Registers (1) := 16#0000_0100#;

   --  Memoria: 0x80
   PSX.Memory.Write_8 (Memory, 16#0000_0100#, 16#80#);

   --  LBU R2, 0(R1)
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#9022_0000#);

   --  NOP
   PSX.Memory.Write_32 (Memory, 16#0001_0004#, 16#0000_0000#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (2) = 0 then
      Ada.Text_IO.Put_Line ("PASS: LBU delay before");
   else
      Ada.Text_IO.Put_Line ("FAIL: LBU delay before");
   end if;

   if CPU.Load_Pending then
      Ada.Text_IO.Put_Line ("PASS: LBU pending");
   else
      Ada.Text_IO.Put_Line ("FAIL: LBU pending");
   end if;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (2) = 16#0000_0080# then
      Ada.Text_IO.Put_Line ("PASS: LBU zero extension");
   else
      Ada.Text_IO.Put_Line ("FAIL: LBU zero extension");
   end if;

   Ada.Text_IO.Put_Line ("PSX CPU LBU delay tests finished.");

end PSX_CPU_LBU_Delay_Tests;
