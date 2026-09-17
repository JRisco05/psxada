with Ada.Text_IO; use Ada.Text_IO;

with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with PSX.Types;
with Interfaces;

procedure PSX_CPU_Regimm_Link_Branch_Tests is

   use type Interfaces.Unsigned_32;

   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

   procedure Check
     (Name : String; Expected : PSX.Types.Word32; Actual : PSX.Types.Word32) is
   begin
      if Actual = Expected then
         Put_Line ("PASS: " & Name);
      else
         Put_Line
           ("FAIL: "
            & Name
            & " expected=0x"
            & PSX.Types.Word32'Image (Expected)
            & " actual=0x"
            & PSX.Types.Word32'Image (Actual));
      end if;
   end Check;

begin

   Put_Line ("Testing PSX CPU REGIMM link branches...");
   New_Line;

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   --  BLTZAL R1, +2
   --  R1 = -1 -> branch taken
   --  $ra = PC + 8
   CPU.Registers (1) := 16#FFFF_FFFF#;

   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#0430_0002#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("BLTZAL taken", 16#0001_000C#, CPU.Next_PC);

   Check ("BLTZAL link", 16#0001_0008#, CPU.Registers (31));

   --  BLTZAL R1, +2
   --  R1 = 1 -> branch not taken
   CPU.Registers (1) := 1;

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("BLTZAL not taken", 16#0001_0008#, CPU.Next_PC);

   Check ("BLTZAL link not taken", 16#0001_0008#, CPU.Registers (31));

   --  BGEZAL R1, +2
   --  R1 = 1 -> branch taken
   CPU.Registers (1) := 1;

   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#0431_0002#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("BGEZAL taken", 16#0001_000C#, CPU.Next_PC);

   Check ("BGEZAL link", 16#0001_0008#, CPU.Registers (31));

   --  BGEZAL R1, +2
   --  R1 = -1 -> branch not taken
   CPU.Registers (1) := 16#FFFF_FFFF#;

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("BGEZAL not taken", 16#0001_0008#, CPU.Next_PC);

   Check ("BGEZAL link not taken", 16#0001_0008#, CPU.Registers (31));

   New_Line;
   Put_Line ("PSX CPU REGIMM link branch tests finished.");

end PSX_CPU_Regimm_Link_Branch_Tests;
