with Ada.Text_IO;
with Interfaces;
with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with PSX.Timers;

procedure Psx_Memory_Store_Cycle_Tests is

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

   procedure Prepare_Store
     (Address : Interfaces.Unsigned_32; Instruction : Interfaces.Unsigned_32)
   is
   begin
      PSX.CPU.Reset (CPU);
      PSX.Memory.Reset (Memory);

      CPU.PC := 16#0000_0000#;
      CPU.Next_PC := 16#0000_0004#;

      CPU.Registers (1) := Address;
      CPU.Registers (2) := 16#1234_5678#;

      PSX.Memory.Write_32 (Memory, 16#0000_0000#, Instruction);
   end Prepare_Store;

begin

   Put_Line ("Testing PSX Memory store cycle counts...");
   New_Line;

   ----------------------------------------------------------------
   --  SB
   ----------------------------------------------------------------

   --  SB R2, 0(R1)
   Prepare_Store (16#0000_0100#, 16#A022_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("SB RAM timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 7);

   ----------------------------------------------------------------
   --  SH
   ----------------------------------------------------------------

   --  SH R2, 0(R1)
   Prepare_Store (16#0000_0100#, 16#A422_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("SH RAM timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 7);

   ----------------------------------------------------------------
   --  SW
   ----------------------------------------------------------------

   --  SW R2, 0(R1)
   Prepare_Store (16#0000_0100#, 16#AC22_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("SW RAM timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 7);

   ----------------------------------------------------------------
   --  Store value semantics
   ----------------------------------------------------------------

   --  SB: debe escribir solamente los 8 bits inferiores
   Prepare_Store (16#0000_0100#, 16#A022_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("SB RAM value",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0100#)),
      16#0000_0078#);

   --  SH: debe escribir solamente los 16 bits inferiores
   Prepare_Store (16#0000_0100#, 16#A422_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("SH RAM value",
      Interfaces.Unsigned_32 (PSX.Memory.Read_16 (Memory, 16#0000_0100#)),
      16#0000_5678#);

   --  SW: debe escribir los 32 bits completos
   Prepare_Store (16#0000_0100#, 16#AC22_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("SW RAM value",
      PSX.Memory.Read_32 (Memory, 16#0000_0100#),
      16#1234_5678#);

   --  Scratchpad
   Prepare_Store (16#1F80_0000#, 16#A022_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("SB Scratchpad timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 1);

   --  I/O
   Prepare_Store (16#1F80_1108#, 16#A022_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("SB I/O timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 5);

   --  Scratchpad
   Prepare_Store (16#1F80_0000#, 16#A422_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("SH Scratchpad timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 1);

   --  I/O
   Prepare_Store (16#1F80_1108#, 16#A422_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("SH I/O timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 5);

   --  Scratchpad
   Prepare_Store (16#1F80_0000#, 16#AC22_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("SW Scratchpad timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 1);

   --  I/O
   Prepare_Store (16#1F80_1108#, 16#AC22_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("SW I/O timer", PSX.Timers.Read_Counter (Memory.Timers, 0), 5);

   ----------------------------------------------------------------
   --  Store value semantics: Scratchpad
   ----------------------------------------------------------------

   --  SB
   Prepare_Store (16#1F80_0000#, 16#A022_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("SB Scratchpad value",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#1F80_0000#)),
      16#0000_0078#);

   --  SH
   Prepare_Store (16#1F80_0000#, 16#A422_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("SH Scratchpad value",
      Interfaces.Unsigned_32 (PSX.Memory.Read_16 (Memory, 16#1F80_0000#)),
      16#0000_5678#);

   --  SW
   Prepare_Store (16#1F80_0000#, 16#AC22_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("SW Scratchpad value",
      PSX.Memory.Read_32 (Memory, 16#1F80_0000#),
      16#1234_5678#);

   New_Line;
   Put_Line ("PSX Memory store cycle tests finished.");

end Psx_Memory_Store_Cycle_Tests;
