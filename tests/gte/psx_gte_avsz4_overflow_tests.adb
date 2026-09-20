with Ada.Text_IO;
with PSX.Types;
with PSX.GTE;
with PSX.GTE.Execute;
with PSX.GTE.Instruction;
with Interfaces;

procedure PSX_GTE_AVSZ4_Overflow_Tests is

   use type Interfaces.Unsigned_32;

   GTE  : PSX.GTE.GTE_State;
   Inst : PSX.GTE.Instruction.Instruction;

begin
   Ada.Text_IO.Put_Line ("Testing PSX GTE AVSZ4 overflow...");

   PSX.GTE.Reset (GTE);

   GTE.SZ0 := 16#FFFF#;
   GTE.SZ1 := 16#FFFF#;
   GTE.SZ2 := 16#FFFF#;
   GTE.SZ3 := 16#FFFF#;

   GTE.ZSF4 := 16#7FFF#;

   Inst.Raw := 16#0000_0003#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   if GTE.OTZ = 16#0000_FFFF# then
      Ada.Text_IO.Put_Line ("PASS: AVSZ4 OTZ saturation");
   else
      Ada.Text_IO.Put_Line
        ("FAIL: AVSZ4 OTZ saturation expected=65535 actual="
         & PSX.Types.Word32'Image (GTE.OTZ));
   end if;

   if (GTE.FLAG and 16#0004_0000#) /= 0 then
      Ada.Text_IO.Put_Line ("PASS: AVSZ4 FLAG bit 18");
   else
      Ada.Text_IO.Put_Line ("FAIL: AVSZ4 FLAG bit 18");
   end if;

   Ada.Text_IO.Put_Line ("PSX GTE AVSZ4 overflow tests finished.");

end PSX_GTE_AVSZ4_Overflow_Tests;
