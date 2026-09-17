with Ada.Text_IO;
with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with Interfaces;

procedure PSX_CPU_Logic_Immediate_Tests is

   use type Interfaces.Unsigned_32;
   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

begin

   Ada.Text_IO.Put_Line ("Testing PSX CPU logical immediate instructions...");
   Ada.Text_IO.New_Line;

   ------------------------------------------------------------------
   --  ANDI
   ------------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.Registers (1) := 16#0000_0FF0#;

   --  ANDI R3, R1, 0x00FF
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#3023_00FF#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (3) = 16#0000_00F0# then
      Ada.Text_IO.Put_Line ("PASS: ANDI");
   else
      Ada.Text_IO.Put_Line ("FAIL: ANDI");
   end if;

   ------------------------------------------------------------------
   --  ORI
   ------------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.Registers (1) := 16#0000_0F00#;

   --  ORI R3, R1, 0x00FF
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#3423_00FF#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (3) = 16#0000_0FFF# then
      Ada.Text_IO.Put_Line ("PASS: ORI");
   else
      Ada.Text_IO.Put_Line ("FAIL: ORI");
   end if;

   ------------------------------------------------------------------
   --  XORI
   ------------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.Registers (1) := 16#0000_0FF0#;

   --  XORI R3, R1, 0x00FF
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#3823_00FF#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (3) = 16#0000_0F0F# then
      Ada.Text_IO.Put_Line ("PASS: XORI");
   else
      Ada.Text_IO.Put_Line ("FAIL: XORI");
   end if;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("PSX CPU logical immediate tests finished.");

end PSX_CPU_Logic_Immediate_Tests;
