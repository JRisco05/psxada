with Ada.Text_IO; use Ada.Text_IO;

with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with PSX.Types;
with Interfaces;

procedure PSX_CPU_Compare_Tests is

   use type Interfaces.Unsigned_32;
   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

   procedure Check
     (Name     : String;
      Expected : PSX.Types.Word32;
      Actual   : PSX.Types.Word32) is
   begin
      if Actual = Expected then
         Put_Line ("PASS: " & Name);
      else
         Put_Line ("FAIL: " & Name);
         Put_Line ("  Expected = " & PSX.Types.Word32'Image (Expected));
         Put_Line ("  Actual   = " & PSX.Types.Word32'Image (Actual));
      end if;
   end Check;

begin

   Put_Line ("Testing PSX CPU comparison instructions...");
   New_Line;

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   -- SLT R3, R1, R2
   -- R1 = -1
   -- R2 = 1
   -- Resultado: 1
   CPU.Registers (1) := 16#FFFF_FFFF#;
   CPU.Registers (2) := 1;

   PSX.Memory.Write_32
     (Memory,
      16#0001_0000#,
      16#0022_18_2A#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("SLT signed",
      1,
      CPU.Registers (3));

   -- SLTU R3, R1, R2
   -- R1 = 0xFFFFFFFF
   -- R2 = 1
   -- Como unsigned: 0xFFFFFFFF > 1
   -- Resultado: 0
   CPU.Registers (1) := 16#FFFF_FFFF#;
   CPU.Registers (2) := 1;

   PSX.Memory.Write_32
     (Memory,
      16#0001_0000#,
      16#0022_18_2B#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("SLTU unsigned",
      0,
      CPU.Registers (3));

   Put_Line ("");
   Put_Line ("PSX CPU comparison tests finished.");

end PSX_CPU_Compare_Tests;
