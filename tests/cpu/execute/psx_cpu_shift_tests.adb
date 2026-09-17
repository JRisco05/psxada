with Ada.Text_IO;
with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with Interfaces;

procedure PSX_CPU_Shift_Tests is

   use type Interfaces.Unsigned_32;
   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

begin

   Ada.Text_IO.Put_Line ("Testing PSX CPU shift instructions...");
   Ada.Text_IO.New_Line;

   ------------------------------------------------------------------
   --  SLL R3, R1, 4
   ------------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.Registers (1) := 16#0000_0003#;

   --  SLL R3, R1, 4
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#0001_1900#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (3) = 16#0000_0030# then
      Ada.Text_IO.Put_Line ("PASS: SLL");
   else
      Ada.Text_IO.Put_Line ("FAIL: SLL");
   end if;

   ------------------------------------------------------------------
   --  SRL R3, R1, 4
   ------------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.Registers (1) := 16#0000_0030#;

   --  SRL R3, R1, 4
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#0001_1902#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (3) = 16#0000_0003# then
      Ada.Text_IO.Put_Line ("PASS: SRL");
   else
      Ada.Text_IO.Put_Line ("FAIL: SRL");
   end if;

   ------------------------------------------------------------------
   --  SRA R3, R1, 4
   ------------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.Registers (1) := 16#F000_0000#;

   --  SRA R3, R1, 4
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#0001_1903#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (3) = 16#FF00_0000# then
      Ada.Text_IO.Put_Line ("PASS: SRA");
   else
      Ada.Text_IO.Put_Line ("FAIL: SRA");
   end if;

   ------------------------------------------------------------------
   --  SLLV R3, R1, R2
   ------------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.Registers (1) := 16#0000_0003#;
   CPU.Registers (2) := 4;

   --  SLLV R3, R1, R2
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#0041_1804#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (3) = 16#0000_0030# then
      Ada.Text_IO.Put_Line ("PASS: SLLV");
   else
      Ada.Text_IO.Put_Line ("FAIL: SLLV");
   end if;

   ------------------------------------------------------------------
   --  SRLV R3, R1, R2
   ------------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.Registers (1) := 16#0000_0030#;
   CPU.Registers (2) := 4;

   --  SRLV R3, R1, R2
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#0041_1806#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (3) = 16#0000_0003# then
      Ada.Text_IO.Put_Line ("PASS: SRLV");
   else
      Ada.Text_IO.Put_Line ("FAIL: SRLV");
   end if;

   ------------------------------------------------------------------
   --  SRAV R3, R1, R2
   ------------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.Registers (1) := 16#F000_0000#;
   CPU.Registers (2) := 4;

   --  SRAV R3, R1, R2
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#0041_1807#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   if CPU.Registers (3) = 16#FF00_0000# then
      Ada.Text_IO.Put_Line ("PASS: SRAV");
   else
      Ada.Text_IO.Put_Line ("FAIL: SRAV");
   end if;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("PSX CPU shift tests finished.");

end PSX_CPU_Shift_Tests;
