with Ada.Text_IO;
with Interfaces;
with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with PSX.Timers;

procedure Psx_Memory_Load_All_Cycle_Tests is

   use Ada.Text_IO;
   use type Interfaces.Unsigned_32;

   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

   procedure Check
     (Name     : String;
      Actual   : Interfaces.Unsigned_32;
      Expected : Interfaces.Unsigned_32) is
   begin
      if Actual = Expected then
         Put_Line ("PASS: " & Name);
      else
         Put_Line
           ("FAIL: "
            & Name
            & " expected="
            & Interfaces.Unsigned_32'Image (Expected)
            & " actual="
            & Interfaces.Unsigned_32'Image (Actual));
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

      -- Load instruction at PC.
      PSX.Memory.Write_32 (Memory, 16#0000_0000#, Instruction);
   end Prepare_Load;

begin

   Put_Line ("Testing PSX Memory load cycle counts...");
   New_Line;

   ----------------------------------------------------------------
   -- LB
   ----------------------------------------------------------------

   -- RAM
   Prepare_Load (16#0000_0100#, 16#8022_0000#);
   PSX.Memory.Write_32 (Memory, 16#0000_0100#, 16#0000_007F#);
   PSX.CPU.Step.Step (CPU, Memory);
   Check ("LB RAM timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 7);

   -- Scratchpad
   Prepare_Load (16#1F80_0000#, 16#8022_0000#);
   PSX.Memory.Write_32 (Memory, 16#1F80_0000#, 16#0000_007F#);
   PSX.CPU.Step.Step (CPU, Memory);
   Check
     ("LB Scratchpad timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 1);

   -- I/O
   Prepare_Load (16#1F80_1108#, 16#8022_0000#);
   PSX.CPU.Step.Step (CPU, Memory);
   Check ("LB I/O timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 5);

   ----------------------------------------------------------------
   -- LBU
   ----------------------------------------------------------------

   -- RAM
   Prepare_Load (16#0000_0100#, 16#9022_0000#);
   PSX.Memory.Write_32 (Memory, 16#0000_0100#, 16#0000_007F#);
   PSX.CPU.Step.Step (CPU, Memory);
   Check ("LBU RAM timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 7);

   -- Scratchpad
   Prepare_Load (16#1F80_0000#, 16#9022_0000#);
   PSX.Memory.Write_32 (Memory, 16#1F80_0000#, 16#0000_007F#);
   PSX.CPU.Step.Step (CPU, Memory);
   Check
     ("LBU Scratchpad timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 1);

   -- I/O
   Prepare_Load (16#1F80_1108#, 16#9022_0000#);
   PSX.CPU.Step.Step (CPU, Memory);
   Check ("LBU I/O timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 5);

   ----------------------------------------------------------------
   -- LH
   ----------------------------------------------------------------

   -- RAM
   Prepare_Load (16#0000_0100#, 16#8422_0000#);
   PSX.Memory.Write_32 (Memory, 16#0000_0100#, 16#0000_1234#);
   PSX.CPU.Step.Step (CPU, Memory);
   Check ("LH RAM timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 7);

   -- Scratchpad
   Prepare_Load (16#1F80_0000#, 16#8422_0000#);
   PSX.Memory.Write_32 (Memory, 16#1F80_0000#, 16#0000_1234#);
   PSX.CPU.Step.Step (CPU, Memory);
   Check
     ("LH Scratchpad timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 1);

   -- I/O
   Prepare_Load (16#1F80_1108#, 16#8422_0000#);
   PSX.CPU.Step.Step (CPU, Memory);
   Check ("LH I/O timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 5);

   ----------------------------------------------------------------
   -- LHU
   ----------------------------------------------------------------

   -- RAM
   Prepare_Load (16#0000_0100#, 16#9422_0000#);
   PSX.Memory.Write_32 (Memory, 16#0000_0100#, 16#0000_1234#);
   PSX.CPU.Step.Step (CPU, Memory);
   Check ("LHU RAM timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 7);

   -- Scratchpad
   Prepare_Load (16#1F80_0000#, 16#9422_0000#);
   PSX.Memory.Write_32 (Memory, 16#1F80_0000#, 16#0000_1234#);
   PSX.CPU.Step.Step (CPU, Memory);
   Check
     ("LHU Scratchpad timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 1);

   -- I/O
   Prepare_Load (16#1F80_1108#, 16#9422_0000#);
   PSX.CPU.Step.Step (CPU, Memory);
   Check ("LHU I/O timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 5);

   New_Line;
   Put_Line ("PSX Memory load cycle count tests finished.");

end Psx_Memory_Load_All_Cycle_Tests;
