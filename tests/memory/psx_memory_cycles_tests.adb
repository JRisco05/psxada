with Ada.Text_IO;
with PSX.Memory.Cycles;
with Interfaces;

procedure Psx_Memory_Cycles_Tests is

   use Ada.Text_IO;

   procedure Check (Name : String; Actual : Natural; Expected : Natural) is
   begin
      if Actual = Expected then
         Put_Line ("PASS: " & Name);
      else
         Put_Line
           ("FAIL: "
            & Name
            & " expected="
            & Natural'Image (Expected)
            & " actual="
            & Natural'Image (Actual));
      end if;
   end Check;

begin

   Put_Line ("Testing PSX.Memory.Cycles...");
   New_Line;

   Check ("Scratchpad", PSX.Memory.Cycles.Load_Cycles (16#1F80_0000#), 1);

   Check ("I/O", PSX.Memory.Cycles.Load_Cycles (16#1F80_0400#), 5);

   Check ("RAM", PSX.Memory.Cycles.Load_Cycles (16#0000_0000#), 7);

   Check ("BIOS KSEG1", PSX.Memory.Cycles.Load_Cycles (16#BFC0_0000#), 27);

   Check ("BIOS KUSEG", PSX.Memory.Cycles.Load_Cycles (16#1FC0_0000#), 27);

   New_Line;
   Put_Line ("PSX.Memory.Cycles tests finished.");

end Psx_Memory_Cycles_Tests;
