with Ada.Text_IO;
with PSX.GTE;
with Interfaces;

procedure PSX_GTE_AVSZ4_Overflow_Tests is

   use type Interfaces.Unsigned_32;

   use Ada.Text_IO;

   GTE : PSX.GTE.GTE_State;

begin
   Put_Line ("Testing PSX GTE AVSZ4 overflow...");

   PSX.GTE.Reset (GTE);

   GTE.SZ0 := 16#FFFF#;
   GTE.SZ1 := 16#FFFF#;
   GTE.SZ2 := 16#FFFF#;
   GTE.SZ3 := 16#FFFF#;

   GTE.ZSF4 := 16#7FFF#;

   -- Inst.Raw := 16#0000_0003#;

   -- PSX.GTE.Execute.Execute (GTE, Inst);

   if GTE.OTZ = 16#FFFF# then
      Put_Line ("PASS: AVSZ4 OTZ saturation");
   else
      Put_Line ("FAIL: AVSZ4 OTZ saturation");
   end if;

   if (GTE.FLAG and 16#0004_0000#) /= 0 then
      Put_Line ("PASS: AVSZ4 FLAG bit 18");
   else
      Put_Line ("FAIL: AVSZ4 FLAG bit 18");
   end if;

   Put_Line ("PSX GTE AVSZ4 overflow tests finished.");

end PSX_GTE_AVSZ4_Overflow_Tests;
