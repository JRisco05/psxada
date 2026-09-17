with Ada.Text_IO; use Ada.Text_IO;

with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with PSX.Types;
with Interfaces;

procedure PSX_CPU_HILO_Move_Tests is

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

   Put_Line ("Testing PSX CPU HI/LO move instructions...");
   New_Line;

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   --  MTHI R1
   CPU.Registers (1) := 16#1234_5678#;

   PSX.Memory.Write_32
     (Memory,
      16#0001_0000#,
      16#0020_08_11#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("MTHI",
      16#1234_5678#,
      CPU.HI);

   --  MFHI R2
   PSX.Memory.Write_32
     (Memory,
      16#0001_0000#,
      16#0000_10_10#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("MFHI",
      16#1234_5678#,
      CPU.Registers (2));

   --  MTLO R1
   CPU.Registers (1) := 16#89AB_CDEF#;

   PSX.Memory.Write_32
     (Memory,
      16#0001_0000#,
      16#0020_00_13#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("MTLO",
      16#89AB_CDEF#,
      CPU.LO);

   --  MFLO R2
   PSX.Memory.Write_32
     (Memory,
      16#0001_0000#,
      16#0000_10_12#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("MFLO",
      16#89AB_CDEF#,
      CPU.Registers (2));

   Put_Line ("");
   Put_Line ("PSX CPU HI/LO move tests finished.");

end PSX_CPU_HILO_Move_Tests;
