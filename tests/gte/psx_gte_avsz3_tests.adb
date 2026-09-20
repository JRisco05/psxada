with Ada.Text_IO;
with PSX.GTE;
with PSX.GTE.Execute;
with PSX.GTE.Instruction;
with PSX.Types;
with Interfaces;

procedure PSX_GTE_AVSZ3_Tests is

   use type Interfaces.Unsigned_32;

   GTE  : PSX.GTE.GTE_State;
   Inst : PSX.GTE.Instruction.Instruction;

   Expected_MAC0 : constant PSX.Types.Word32 := 24_576_000;

   Expected_OTZ : constant PSX.Types.Word32 := 6000;

begin
   Ada.Text_IO.Put_Line ("Testing PSX GTE AVSZ3...");

   PSX.GTE.Reset (GTE);

   GTE.SZ1 := 1000;
   GTE.SZ2 := 2000;
   GTE.SZ3 := 3000;

   GTE.ZSF3 := 4096;

   Inst.Raw := 16#0000_0002#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   if GTE.MAC0 = Expected_MAC0 then
      Ada.Text_IO.Put_Line ("PASS: AVSZ3 MAC0");
   else
      Ada.Text_IO.Put_Line
        ("FAIL: AVSZ3 MAC0 expected=0x"
         & PSX.Types.Word32'Image (Expected_MAC0)
         & " actual=0x"
         & PSX.Types.Word32'Image (GTE.MAC0));
   end if;

   if GTE.OTZ = Expected_OTZ then
      Ada.Text_IO.Put_Line ("PASS: AVSZ3 OTZ");
   else
      Ada.Text_IO.Put_Line
        ("FAIL: AVSZ3 OTZ expected=6000 actual="
         & PSX.Types.Word32'Image (GTE.OTZ));
   end if;

   if GTE.FLAG = 0 then
      Ada.Text_IO.Put_Line ("PASS: AVSZ3 FLAG");
   else
      Ada.Text_IO.Put_Line
        ("FAIL: AVSZ3 FLAG actual=" & PSX.Types.Word32'Image (GTE.FLAG));
   end if;

   Ada.Text_IO.Put_Line ("PSX GTE AVSZ3 tests finished.");

end PSX_GTE_AVSZ3_Tests;
