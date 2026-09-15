with Ada.Text_IO;
with Interfaces;
with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with PSX.Timers;

procedure Psx_Memory_Load_Cycle_Count_Tests is

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

   procedure Prepare_LW (Address : Interfaces.Unsigned_32) is
   begin
      PSX.CPU.Reset (CPU);
      PSX.Memory.Reset (Memory);

      CPU.PC := 16#0000_0000#;
      CPU.Next_PC := 16#0000_0004#;

      CPU.Registers (1) := Address;

      -- LW R2, 0(R1)
      PSX.Memory.Write_32 (Memory, 16#0000_0000#, 16#8C22_0000#);
   end Prepare_LW;

begin

   Put_Line ("Testing PSX Memory LW cycle counts...");
   New_Line;

   ----------------------------------------------------------------
   -- RAM
   ----------------------------------------------------------------

   Prepare_LW (16#0000_0100#);

   PSX.Memory.Write_32 (Memory, 16#0000_0100#, 16#1234_5678#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("LW RAM timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 7);

   ----------------------------------------------------------------
   -- Scratchpad
   ----------------------------------------------------------------

   Prepare_LW (16#1F80_0000#);

   PSX.Memory.Write_32 (Memory, 16#1F80_0000#, 16#AABB_CCDD#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("LW Scratchpad timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 1);

   ----------------------------------------------------------------
   -- I/O
   ----------------------------------------------------------------

   -- Use the Timer 0 target register itself as the I/O address.
   Prepare_LW (16#1F80_1108#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("LW I/O timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 5);

   New_Line;
   Put_Line ("PSX Memory LW cycle count tests finished.");

end Psx_Memory_Load_Cycle_Count_Tests;
