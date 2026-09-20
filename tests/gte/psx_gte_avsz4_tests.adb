with Ada.Text_IO;
with PSX.Types;
with PSX.GTE;
with PSX.GTE.Execute;
with PSX.GTE.Instruction;
with Interfaces;

procedure PSX_GTE_AVSZ4_Tests is

   use type Interfaces.Unsigned_32;
   
   GTE  : PSX.GTE.GTE_State;
   Inst : PSX.GTE.Instruction.Instruction;

   Expected_MAC0 : constant PSX.Types.Word32 := 40_960_000;
   Expected_OTZ  : constant PSX.Types.Word32 := 10_000;

begin
   Ada.Text_IO.Put_Line ("Testing PSX GTE AVSZ4...");

   PSX.GTE.Reset (GTE);

   GTE.SZ0 := 1000;
   GTE.SZ1 := 2000;
   GTE.SZ2 := 3000;
   GTE.SZ3 := 4000;

   GTE.ZSF4 := 4096;

   Inst.Raw := 16#0000_0003#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   if GTE.MAC0 = Expected_MAC0 then
      Ada.Text_IO.Put_Line ("PASS: AVSZ4 MAC0");
   else
      Ada.Text_IO.Put_Line
        ("FAIL: AVSZ4 MAC0 expected="
         & PSX.Types.Word32'Image (Expected_MAC0)
         & " actual="
         & PSX.Types.Word32'Image (GTE.MAC0));
   end if;

   if GTE.OTZ = Expected_OTZ then
      Ada.Text_IO.Put_Line ("PASS: AVSZ4 OTZ");
   else
      Ada.Text_IO.Put_Line
        ("FAIL: AVSZ4 OTZ expected="
         & PSX.Types.Word32'Image (Expected_OTZ)
         & " actual="
         & PSX.Types.Word32'Image (GTE.OTZ));
   end if;

   if GTE.FLAG = 0 then
      Ada.Text_IO.Put_Line ("PASS: AVSZ4 FLAG");
   else
      Ada.Text_IO.Put_Line
        ("FAIL: AVSZ4 FLAG actual=" & PSX.Types.Word32'Image (GTE.FLAG));
   end if;

   Ada.Text_IO.Put_Line ("PSX GTE AVSZ4 tests finished.");

end PSX_GTE_AVSZ4_Tests;
