with Ada.Text_IO;
with Interfaces;
with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;

procedure Psx_Memory_Load_Timing_Tests is

   use Ada.Text_IO;
   use type Interfaces.Unsigned_32;

   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

   procedure Check (Name : String; Condition : Boolean) is
   begin
      if Condition then
         Put_Line ("PASS: " & Name);
      else
         Put_Line ("FAIL: " & Name);
      end if;
   end Check;

   procedure Prepare_Load
     (Address : Interfaces.Unsigned_32; Instruction : Interfaces.Unsigned_32)
   is
   begin
      PSX.CPU.Reset (CPU);
      PSX.Memory.Reset (Memory);

      CPU.PC := 16#0000_0000#;
      CPU.Next_PC := 16#0000_0004#;

      CPU.Registers (1) := Address;

      PSX.Memory.Write_32 (Memory, 16#0000_0000#, Instruction);
   end Prepare_Load;

begin

   Put_Line ("Testing PSX Memory load timing...");
   New_Line;

   ----------------------------------------------------------------
   --  LB
   ----------------------------------------------------------------

   Prepare_Load (16#0000_0100#, 16#8022_0000#);

   --  0x80 debe convertirse en 0xFFFFFF80.
   PSX.Memory.Write_32 (Memory, 16#0000_0100#, 16#0000_0080#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("LB sign extension", CPU.Registers (2) = 16#FFFF_FF80#);

   Check ("LB stall consumed", CPU.Memory_Stall_Cycles = 0);

   ----------------------------------------------------------------
   --  LBU
   ----------------------------------------------------------------

   Prepare_Load (16#0000_0100#, 16#9022_0000#);

   --  0x80 debe convertirse en 0x00000080.
   PSX.Memory.Write_32 (Memory, 16#0000_0100#, 16#0000_0080#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("LBU zero extension", CPU.Registers (2) = 16#0000_0080#);

   Check ("LBU stall consumed", CPU.Memory_Stall_Cycles = 0);

   ----------------------------------------------------------------
   --  LH
   ----------------------------------------------------------------

   Prepare_Load (16#0000_0100#, 16#8422_0000#);

   --  0x8000 debe convertirse en 0xFFFF8000.
   PSX.Memory.Write_32 (Memory, 16#0000_0100#, 16#0000_8000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("LH sign extension", CPU.Registers (2) = 16#FFFF_8000#);

   Check ("LH stall consumed", CPU.Memory_Stall_Cycles = 0);

   ----------------------------------------------------------------
   --  LHU
   ----------------------------------------------------------------

   Prepare_Load (16#0000_0100#, 16#9422_0000#);

   --  0x8000 debe convertirse en 0x00008000.
   PSX.Memory.Write_32 (Memory, 16#0000_0100#, 16#0000_8000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("LHU zero extension", CPU.Registers (2) = 16#0000_8000#);

   Check ("LHU stall consumed", CPU.Memory_Stall_Cycles = 0);

   ----------------------------------------------------------------
   --  LW
   ----------------------------------------------------------------

   Prepare_Load (16#0000_0100#, 16#8C22_0000#);

   PSX.Memory.Write_32 (Memory, 16#0000_0100#, 16#1234_5678#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("LW value", CPU.Registers (2) = 16#1234_5678#);

   Check ("LW stall consumed", CPU.Memory_Stall_Cycles = 0);

   New_Line;
   Put_Line ("PSX Memory load timing tests finished.");

end Psx_Memory_Load_Timing_Tests;
