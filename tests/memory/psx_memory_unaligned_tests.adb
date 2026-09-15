with Ada.Text_IO;
with Interfaces;
with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;

procedure Psx_Memory_Unaligned_Tests is

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

   procedure Prepare
     (Address        : Interfaces.Unsigned_32;
      Instruction    : Interfaces.Unsigned_32;
      Register_Value : Interfaces.Unsigned_32 := 16#AABB_CCDD#) is
   begin
      PSX.CPU.Reset (CPU);
      PSX.Memory.Reset (Memory);

      CPU.PC := 16#0000_0000#;
      CPU.Next_PC := 16#0000_0004#;

      CPU.Registers (1) := Address;
      CPU.Registers (2) := Register_Value;

      PSX.Memory.Write_32 (Memory, 16#0000_0000#, Instruction);

      PSX.Memory.Write_32 (Memory, 16#0000_0100#, 16#4433_2211#);

      PSX.Memory.Write_32 (Memory, 16#0000_0104#, 16#8877_6655#);
   end Prepare;

begin

   Put_Line ("Testing PSX unaligned memory instructions...");
   New_Line;

   ----------------------------------------------------------------
   -- LWL
   ----------------------------------------------------------------

   -- LWL R2, 0(R1)
   Prepare (16#0000_0100#, 16#8822_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("LWL offset 0", CPU.Registers (2), 16#11BB_CCDD#);

   -- LWL R2, 1(R1)
   Prepare (16#0000_0101#, 16#8822_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("LWL offset 1", CPU.Registers (2), 16#2211_CCDD#);

   -- LWL R2, 2(R1)
   Prepare (16#0000_0102#, 16#8822_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("LWL offset 2", CPU.Registers (2), 16#3322_11DD#);

   -- LWL R2, 3(R1)
   Prepare (16#0000_0103#, 16#8822_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("LWL offset 3", CPU.Registers (2), 16#4433_2211#);

   ----------------------------------------------------------------
   -- LWR
   ----------------------------------------------------------------

   -- LWR R2, 0(R1)
   Prepare (16#0000_0100#, 16#9822_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("LWR offset 0", CPU.Registers (2), 16#4433_2211#);

   -- LWR R2, 1(R1)
   Prepare (16#0000_0101#, 16#9822_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("LWR offset 1", CPU.Registers (2), 16#AA44_3322#);

   -- LWR R2, 2(R1)
   Prepare (16#0000_0102#, 16#9822_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("LWR offset 2", CPU.Registers (2), 16#AABB_4433#);

   -- LWR R2, 3(R1)
   Prepare (16#0000_0103#, 16#9822_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check ("LWR offset 3", CPU.Registers (2), 16#AABB_CC44#);

   ----------------------------------------------------------------
   -- SWL
   ----------------------------------------------------------------

   -- SWL R2, 0(R1)
   --
   -- R1 = 0x00000100
   -- R2 = 0xAABBCCDD
   --
   -- Memoria inicial:
   -- 0x100 = 11 22 33 44
   --
   -- Después de SWL:
   -- 0x100 = AA 22 33 44

   Prepare (16#0000_0100#, 16#A822_0000#, 16#AABB_CCDD#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("SWL offset 0 byte 0",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0100#)),
      16#0000_00AA#);

   ----------------------------------------------------------------
   -- SWR
   ----------------------------------------------------------------

   -- SWR R2, 0(R1)
   Prepare (16#0000_0100#, 16#B822_0000#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("SWR offset 0 byte 0",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0100#)),
      16#0000_00DD#);

   ----------------------------------------------------------------
   -- Unaligned word load: LWR + LWL
   ----------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0000_0000#;
   CPU.Next_PC := 16#0000_0004#;

   CPU.Registers (1) := 16#0000_0101#;
   CPU.Registers (2) := 16#AABB_CCDD#;

   -- LWR R2, 0(R1)
   PSX.Memory.Write_32 (Memory, 16#0000_0000#, 16#9822_0000#);

   -- LWL R2, 3(R1)
   PSX.Memory.Write_32 (Memory, 16#0000_0004#, 16#8822_0003#);

   PSX.Memory.Write_32 (Memory, 16#0000_0100#, 16#4433_2211#);

   PSX.Memory.Write_32 (Memory, 16#0000_0104#, 16#8877_6655#);

   PSX.CPU.Step.Step (CPU, Memory);
   PSX.CPU.Step.Step (CPU, Memory);

   Check ("LWR+LWL unaligned word", CPU.Registers (2), 16#5544_3322#);

   ----------------------------------------------------------------
   -- SWL offset 1
   ----------------------------------------------------------------

   -- SWL R2, 1(R1)
   --
   -- R1 = 0x00000100
   -- R2 = 0xAABBCCDD
   --
   -- Memoria inicial:
   -- 0x100 = 11 22 33 44
   --
   -- Resultado:
   -- 0x100 = BB AA 33 44

   Prepare (16#0000_0100#, 16#A822_0001#, 16#AABB_CCDD#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("SWL offset 1 byte 0",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0100#)),
      16#0000_00BB#);

   Check
     ("SWL offset 1 byte 1",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0101#)),
      16#0000_00AA#);

   ----------------------------------------------------------------
   -- SWL offset 2
   ----------------------------------------------------------------

   -- SWL R2, 2(R1)
   --
   -- Resultado:
   -- 0x100 = CC BB AA 44

   Prepare (16#0000_0100#, 16#A822_0002#, 16#AABB_CCDD#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("SWL offset 2 byte 0",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0100#)),
      16#0000_00CC#);

   Check
     ("SWL offset 2 byte 1",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0101#)),
      16#0000_00BB#);

   Check
     ("SWL offset 2 byte 2",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0102#)),
      16#0000_00AA#);

   ----------------------------------------------------------------
   -- SWL offset 3
   ----------------------------------------------------------------

   -- SWL R2, 3(R1)
   --
   -- Resultado:
   -- 0x100 = DD CC BB AA

   Prepare (16#0000_0100#, 16#A822_0003#, 16#AABB_CCDD#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("SWL offset 3 byte 0",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0100#)),
      16#0000_00DD#);

   Check
     ("SWL offset 3 byte 1",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0101#)),
      16#0000_00CC#);

   Check
     ("SWL offset 3 byte 2",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0102#)),
      16#0000_00BB#);

   Check
     ("SWL offset 3 byte 3",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0103#)),
      16#0000_00AA#);

   ----------------------------------------------------------------
   -- SWR offset 1
   ----------------------------------------------------------------

   Prepare (16#0000_0100#, 16#B822_0001#, 16#AABB_CCDD#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("SWR offset 1 byte 0",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0100#)),
      16#0000_0011#);

   Check
     ("SWR offset 1 byte 1",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0101#)),
      16#0000_00DD#);

   Check
     ("SWR offset 1 byte 2",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0102#)),
      16#0000_00CC#);

   Check
     ("SWR offset 1 byte 3",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0103#)),
      16#0000_00BB#);

   ----------------------------------------------------------------
   -- SWR offset 2
   ----------------------------------------------------------------

   Prepare (16#0000_0100#, 16#B822_0002#, 16#AABB_CCDD#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("SWR offset 2 byte 0",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0100#)),
      16#0000_0011#);

   Check
     ("SWR offset 2 byte 1",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0101#)),
      16#0000_0022#);

   Check
     ("SWR offset 2 byte 2",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0102#)),
      16#0000_00DD#);

   Check
     ("SWR offset 2 byte 3",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0103#)),
      16#0000_00CC#);

   ----------------------------------------------------------------
   -- SWR offset 3
   ----------------------------------------------------------------

   Prepare (16#0000_0100#, 16#B822_0003#, 16#AABB_CCDD#);

   PSX.CPU.Step.Step (CPU, Memory);

   Check
     ("SWR offset 3 byte 0",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0100#)),
      16#0000_0011#);

   Check
     ("SWR offset 3 byte 1",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0101#)),
      16#0000_0022#);

   Check
     ("SWR offset 3 byte 2",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0102#)),
      16#0000_0033#);

   Check
     ("SWR offset 3 byte 3",
      Interfaces.Unsigned_32 (PSX.Memory.Read_8 (Memory, 16#0000_0103#)),
      16#0000_00DD#);

   New_Line;
   Put_Line ("PSX unaligned memory tests finished.");

end Psx_Memory_Unaligned_Tests;
