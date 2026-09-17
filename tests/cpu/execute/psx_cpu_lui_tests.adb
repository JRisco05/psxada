with Ada.Text_IO; use Ada.Text_IO;

with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with PSX.Types;
with Interfaces;

procedure PSX_CPU_LUI_Tests is

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

   Put_Line ("Testing PSX CPU LUI...");
   New_Line;

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   --  LUI R3, 0x1234
   --  R3 = 0x12340000
   PSX.Memory.Write_32
     (Memory,
      16#0001_0000#,
      16#3C03_1234#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("LUI basic",
      16#1234_0000#,
      CPU.Registers (3));

   --  LUI R3, 0xFFFF
   --  R3 = 0xFFFF0000
   PSX.Memory.Write_32
     (Memory,
      16#0001_0000#,
      16#3C03_FFFF#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("LUI upper bits",
      16#FFFF_0000#,
      CPU.Registers (3));

   Put_Line ("");
   Put_Line ("PSX CPU LUI tests finished.");

end PSX_CPU_LUI_Tests;
