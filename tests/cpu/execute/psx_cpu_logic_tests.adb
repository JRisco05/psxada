with Ada.Text_IO;
with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with Interfaces;

procedure PSX_CPU_Logic_Tests is

   use type Interfaces.Unsigned_32;
   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

begin

   Ada.Text_IO.Put_Line ("Testing PSX CPU logical instructions...");
   Ada.Text_IO.New_Line;

   ------------------------------------------------------------------
   --  AND
   ------------------------------------------------------------------
   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.Registers (1) := 16#F0F0_F0F0#;
   CPU.Registers (2) := 16#0FF0_0FF0#;

   --  AND R3, R1, R2 (Opcode real: 16#0022_1824#)
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#0022_1824#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (3) = 16#00F0_00F0# then
      Ada.Text_IO.Put_Line ("PASS: AND");
   else
      Ada.Text_IO.Put_Line ("FAIL: AND");
   end if;

   ------------------------------------------------------------------
   --  OR
   ------------------------------------------------------------------
   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.Registers (1) := 16#F0F0_F0F0#;
   CPU.Registers (2) := 16#0FF0_0FF0#;

   --  OR R3, R1, R2 (Opcode real: 16#0022_1825#)
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#0022_1825#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (3) = 16#FFF0_FFF0# then
      Ada.Text_IO.Put_Line ("PASS: OR");
   else
      Ada.Text_IO.Put_Line ("FAIL: OR");
   end if;

   ------------------------------------------------------------------
   --  XOR
   ------------------------------------------------------------------
   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.Registers (1) := 16#F0F0_F0F0#;
   CPU.Registers (2) := 16#0FF0_0FF0#;

   --  XOR R3, R1, R2 (Opcode real: 16#0022_1826#)
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#0022_1826#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (3) = 16#FF00_FF00# then
      Ada.Text_IO.Put_Line ("PASS: XOR");
   else
      Ada.Text_IO.Put_Line ("FAIL: XOR");
   end if;

   ------------------------------------------------------------------
   --  NOR
   ------------------------------------------------------------------
   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.Registers (1) := 16#F0F0_F0F0#;
   CPU.Registers (2) := 16#0FF0_0FF0#;

   --  NOR R3, R1, R2 (Opcode real: 16#0022_1827#)
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#0022_1827#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (3) = 16#000F_000F# then
      Ada.Text_IO.Put_Line ("PASS: NOR");
   else
      Ada.Text_IO.Put_Line ("FAIL: NOR");
   end if;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("PSX CPU logic tests finished.");

end PSX_CPU_Logic_Tests;
