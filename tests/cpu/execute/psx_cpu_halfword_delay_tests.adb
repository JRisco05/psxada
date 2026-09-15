with Ada.Text_IO;
with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with Interfaces;

procedure PSX_CPU_Halfword_Delay_Tests is

   use type Interfaces.Unsigned_32;

   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

begin
   ------------------------------------------------------------------
   -- LH
   ------------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.Registers (1) := 16#0000_0100#;

   -- 0x8000
   PSX.Memory.Write_16 (Memory, 16#0000_0100#, 16#8000#);

   -- LH R2, 0(R1)
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#8422_0000#);

   -- NOP
   PSX.Memory.Write_32 (Memory, 16#0001_0004#, 16#0000_0000#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (2) = 0 then
      Ada.Text_IO.Put_Line ("PASS: LH delay before");
   else
      Ada.Text_IO.Put_Line ("FAIL: LH delay before");
   end if;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (2) = 16#FFFF_8000# then
      Ada.Text_IO.Put_Line ("PASS: LH sign extension");
   else
      Ada.Text_IO.Put_Line ("FAIL: LH sign extension");
   end if;

   ------------------------------------------------------------------
   -- LHU
   ------------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.Registers (1) := 16#0000_0100#;

   -- 0x8000
   PSX.Memory.Write_16 (Memory, 16#0000_0100#, 16#8000#);

   -- LHU R2, 0(R1)
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#9422_0000#);

   -- NOP
   PSX.Memory.Write_32 (Memory, 16#0001_0004#, 16#0000_0000#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (2) = 0 then
      Ada.Text_IO.Put_Line ("PASS: LHU delay before");
   else
      Ada.Text_IO.Put_Line ("FAIL: LHU delay before");
   end if;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (2) = 16#0000_8000# then
      Ada.Text_IO.Put_Line ("PASS: LHU zero extension");
   else
      Ada.Text_IO.Put_Line ("FAIL: LHU zero extension");
   end if;

   Ada.Text_IO.Put_Line ("PSX CPU halfword delay tests finished.");

end PSX_CPU_Halfword_Delay_Tests;
