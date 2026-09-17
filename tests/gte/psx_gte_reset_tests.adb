with Ada.Text_IO; use Ada.Text_IO;
with PSX.GTE;
with Interfaces;

procedure PSX_GTE_Reset_Tests is

   use type Interfaces.Unsigned_32;

   GTE : PSX.GTE.GTE_State;

begin
   Put_Line ("Testing PSX GTE reset...");
   New_Line;

   PSX.GTE.Reset (GTE);

   if GTE.V0_X = 0 and then GTE.V0_Y = 0 and then GTE.V0_Z = 0 then
      Put_Line ("PASS: GTE V0 reset");
   else
      Put_Line ("FAIL: GTE V0 reset");
   end if;

   if GTE.V1_X = 0 and then GTE.V1_Y = 0 and then GTE.V1_Z = 0 then
      Put_Line ("PASS: GTE V1 reset");
   else
      Put_Line ("FAIL: GTE V1 reset");
   end if;

   if GTE.V2_X = 0 and then GTE.V2_Y = 0 and then GTE.V2_Z = 0 then
      Put_Line ("PASS: GTE V2 reset");
   else
      Put_Line ("FAIL: GTE V2 reset");
   end if;

   if GTE.MAC0 = 0
     and then GTE.MAC1 = 0
     and then GTE.MAC2 = 0
     and then GTE.MAC3 = 0
   then
      Put_Line ("PASS: GTE MAC reset");
   else
      Put_Line ("FAIL: GTE MAC reset");
   end if;

   if GTE.IR0 = 0
     and then GTE.IR1 = 0
     and then GTE.IR2 = 0
     and then GTE.IR3 = 0
   then
      Put_Line ("PASS: GTE IR reset");
   else
      Put_Line ("FAIL: GTE IR reset");
   end if;

   if GTE.SX0 = 0
     and then GTE.SY0 = 0
     and then GTE.SX1 = 0
     and then GTE.SY1 = 0
     and then GTE.SX2 = 0
     and then GTE.SY2 = 0
   then
      Put_Line ("PASS: GTE screen coordinates reset");
   else
      Put_Line ("FAIL: GTE screen coordinates reset");
   end if;

   if GTE.SZ0 = 0
     and then GTE.SZ1 = 0
     and then GTE.SZ2 = 0
     and then GTE.SZ3 = 0
   then
      Put_Line ("PASS: GTE depth reset");
   else
      Put_Line ("FAIL: GTE depth reset");
   end if;

   if GTE.FLAG = 0 then
      Put_Line ("PASS: GTE FLAG reset");
   else
      Put_Line ("FAIL: GTE FLAG reset");
   end if;

   New_Line;
   Put_Line ("PSX GTE reset tests finished.");

end PSX_GTE_Reset_Tests;
