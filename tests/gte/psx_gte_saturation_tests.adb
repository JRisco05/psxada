with Ada.Text_IO; use Ada.Text_IO;

with PSX.GTE.Execute.Saturation;
with PSX.Types;
with Interfaces;

procedure PSX_GTE_Saturation_Tests is

   use type Interfaces.Unsigned_32;
   
   subtype Word32 is PSX.Types.Word32;

begin
   Put_Line ("Testing PSX GTE IR saturation...");
   New_Line;

   if PSX.GTE.Execute.Saturation.Saturate_IR (0) = 0 then
      Put_Line ("PASS: IR zero");
   else
      Put_Line ("FAIL: IR zero");
   end if;

   if PSX.GTE.Execute.Saturation.Saturate_IR (32767) = 32767 then
      Put_Line ("PASS: IR max");
   else
      Put_Line ("FAIL: IR max");
   end if;

   if PSX.GTE.Execute.Saturation.Saturate_IR (40000) = 32767 then
      Put_Line ("PASS: IR positive saturation");
   else
      Put_Line ("FAIL: IR positive saturation");
   end if;

   if PSX.GTE.Execute.Saturation.Saturate_IR (-32768) =
      16#0000_8000# then
      Put_Line ("PASS: IR min");
   else
      Put_Line ("FAIL: IR min");
   end if;

   if PSX.GTE.Execute.Saturation.Saturate_IR (-40000) =
      16#0000_8000# then
      Put_Line ("PASS: IR negative saturation");
   else
      Put_Line ("FAIL: IR negative saturation");
   end if;

   New_Line;
   Put_Line ("PSX GTE IR saturation tests finished.");

end PSX_GTE_Saturation_Tests;