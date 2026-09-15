with Ada.Text_IO;
with PSX.Timers;
with PSX.Types;
with Interfaces;
with PSX.Memory;

procedure PSX_Timers_Tests is

   use type Interfaces.Unsigned_32;
   Timers : PSX.Timers.Timers_State;

   procedure Check
     (Name : String; Expected : PSX.Types.Word32; Actual : PSX.Types.Word32) is
   begin
      if Expected = Actual then
         Ada.Text_IO.Put_Line ("PASS: " & Name);
      else
         Ada.Text_IO.Put_Line
           ("FAIL: "
            & Name
            & " expected="
            & PSX.Types.Word32'Image (Expected)
            & " actual="
            & PSX.Types.Word32'Image (Actual));
      end if;
   end Check;

begin

   Ada.Text_IO.Put_Line ("Testing PSX Timers...");

   PSX.Timers.Reset (Timers);

   -- Reset
   Check ("Timer 0 counter reset", 0, PSX.Timers.Read_Counter (Timers, 0));

   Check ("Timer 1 counter reset", 0, PSX.Timers.Read_Counter (Timers, 1));

   Check ("Timer 2 counter reset", 0, PSX.Timers.Read_Counter (Timers, 2));

   -- Counter
   PSX.Timers.Write_Counter (Timers, 0, 16#1234#);

   Check
     ("Timer 0 counter write/read",
      16#1234#,
      PSX.Timers.Read_Counter (Timers, 0));

   -- Mode
   PSX.Timers.Write_Mode (Timers, 0, 16#0180#);

   Check
     ("Timer 0 mode write/read", 16#0180#, PSX.Timers.Read_Mode (Timers, 0));

   -- Target
   PSX.Timers.Write_Target (Timers, 0, 16#5678#);

   Check
     ("Timer 0 target write/read",
      16#5678#,
      PSX.Timers.Read_Target (Timers, 0));

   -- Timer 1
   PSX.Timers.Write_Counter (Timers, 1, 16#1111#);
   PSX.Timers.Write_Mode (Timers, 1, 16#2222#);
   PSX.Timers.Write_Target (Timers, 1, 16#3333#);

   Check ("Timer 1 counter", 16#1111#, PSX.Timers.Read_Counter (Timers, 1));

   Check ("Timer 1 mode", 16#2222#, PSX.Timers.Read_Mode (Timers, 1));

   Check ("Timer 1 target", 16#3333#, PSX.Timers.Read_Target (Timers, 1));

   -- Timer 2

   PSX.Timers.Write_Counter (Timers, 2, 16#AAAA#);

   PSX.Timers.Write_Mode (Timers, 2, 16#0300#);

   Check ("Timer 2 mode", 16#0300#, PSX.Timers.Read_Mode (Timers, 2));

   PSX.Timers.Write_Target (Timers, 2, 16#CCCC#);

   Check ("Timer 2 counter", 16#AAAA#, PSX.Timers.Read_Counter (Timers, 2));

   Check ("Timer 2 target", 16#CCCC#, PSX.Timers.Read_Target (Timers, 2));

   -- Timer tick

   PSX.Timers.Reset (Timers);

   PSX.Timers.Write_Counter (Timers, 0, 10);

   PSX.Timers.Write_Target (Timers, 0, 15);

   PSX.Timers.Tick (Timers, 0, 5);

   Check ("Timer 0 tick", 15, PSX.Timers.Read_Counter (Timers, 0));

   Check
     ("Timer 0 target reached",
      16#0400#,
      PSX.Timers.Read_Mode (Timers, 0) and 16#0400#);

   -- Counter must remain 16-bit

   PSX.Timers.Reset (Timers);

   PSX.Timers.Write_Counter (Timers, 0, 16#1234_5678#);

   Check
     ("Timer 0 counter 16-bit", 16#5678#, PSX.Timers.Read_Counter (Timers, 0));

   -- Target must remain 16-bit

   PSX.Timers.Write_Target (Timers, 0, 16#ABCD_1234#);

   Check
     ("Timer 0 target 16-bit", 16#1234#, PSX.Timers.Read_Target (Timers, 0));

   -- Reset on target

   PSX.Timers.Reset (Timers);

   PSX.Timers.Write_Counter (Timers, 0, 8);

   PSX.Timers.Write_Target (Timers, 0, 10);

   -- Bit 3: reset counter on target
   PSX.Timers.Write_Mode (Timers, 0, 16#0008#);

   PSX.Timers.Tick (Timers, 0, 2);

   Check ("Timer 0 reset on target", 0, PSX.Timers.Read_Counter (Timers, 0));

   Check
     ("Timer 0 target flag after reset",
      16#0400#,
      PSX.Timers.Read_Mode (Timers, 0) and 16#0400#);

   -- Overflow

   PSX.Timers.Reset (Timers);

   PSX.Timers.Write_Counter (Timers, 0, 16#FFFE#);

   PSX.Timers.Tick (Timers, 0, 2);

   Check ("Timer 0 overflow counter", 0, PSX.Timers.Read_Counter (Timers, 0));

   Check
     ("Timer 0 overflow flag",
      16#0800#,
      PSX.Timers.Read_Mode (Timers, 0) and 16#0800#);

   -- Mode status flags are cleared when Mode is written

   PSX.Timers.Reset (Timers);

   PSX.Timers.Write_Counter (Timers, 0, 9);

   PSX.Timers.Write_Target (Timers, 0, 10);

   PSX.Timers.Tick (Timers, 0, 1);

   Check
     ("Timer 0 target flag set",
      16#0400#,
      PSX.Timers.Read_Mode (Timers, 0) and 16#0400#);

   PSX.Timers.Write_Mode (Timers, 0, 16#0000#);

   Check
     ("Timer 0 target flag cleared",
      0,
      PSX.Timers.Read_Mode (Timers, 0) and 16#0400#);

   -- Timer MMIO through PSX.Memory

   declare
      Memory : PSX.Memory.Memory_State;
   begin
      PSX.Memory.Reset (Memory);

      -- Timer 0 Counter: 0x1F801100
      PSX.Memory.Write_32 (Memory, 16#1F80_1100#, 16#0000_1234#);

      Check
        ("Timer 0 MMIO counter",
         16#0000_1234#,
         PSX.Memory.Read_32 (Memory, 16#1F80_1100#));

      -- Timer 0 Mode: 0x1F801104
      PSX.Memory.Write_32 (Memory, 16#1F80_1104#, 16#0000_0180#);

      Check
        ("Timer 0 MMIO mode",
         16#0000_0180#,
         PSX.Memory.Read_32 (Memory, 16#1F80_1104#));

      -- Timer 0 Target: 0x1F801108
      PSX.Memory.Write_32 (Memory, 16#1F80_1108#, 16#0000_5678#);

      Check
        ("Timer 0 MMIO target",
         16#0000_5678#,
         PSX.Memory.Read_32 (Memory, 16#1F80_1108#));

      -- Timer 1 Counter: 0x1F801110
      PSX.Memory.Write_32 (Memory, 16#1F80_1110#, 16#0000_1111#);

      Check
        ("Timer 1 MMIO counter",
         16#0000_1111#,
         PSX.Memory.Read_32 (Memory, 16#1F80_1110#));

      -- Timer 2 Counter: 0x1F801120
      PSX.Memory.Write_32 (Memory, 16#1F80_1120#, 16#0000_AAAA#);

      Check
        ("Timer 2 MMIO counter",
         16#0000_AAAA#,
         PSX.Memory.Read_32 (Memory, 16#1F80_1120#));
   end;

   Ada.Text_IO.Put_Line ("Timers tests finished.");

end PSX_Timers_Tests;
