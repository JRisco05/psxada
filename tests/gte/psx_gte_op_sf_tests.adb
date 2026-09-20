with Ada.Text_IO;
with PSX.Types;
with PSX.GTE;
with PSX.GTE.Execute;
with PSX.GTE.Instruction;
with Interfaces;

procedure PSX_GTE_OP_SF_Tests is

   use type Interfaces.Unsigned_32;

   GTE  : PSX.GTE.GTE_State;
   Inst : PSX.GTE.Instruction.Instruction;

   Expected_IR1 : constant PSX.Types.Word32 := 2;
   Expected_IR2 : constant PSX.Types.Word32 := 2;
   Expected_IR3 : constant PSX.Types.Word32 := 16#FFFF_FFFC#;

begin
   Ada.Text_IO.Put_Line ("Testing PSX GTE OP SF...");

   PSX.GTE.Reset (GTE);

   GTE.RT11 := 1;
   GTE.RT22 := 1;
   GTE.RT33 := 1;

   GTE.IR1 := 10000;
   GTE.IR2 := 30000;
   GTE.IR3 := 20000;

   Inst.Raw := 16#0008_0000#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   if GTE.IR1 = Expected_IR1 then
      Ada.Text_IO.Put_Line ("PASS: OP SF IR1");
   else
      Ada.Text_IO.Put_Line
        ("FAIL: OP SF IR1 expected="
         & PSX.Types.Word32'Image (Expected_IR1)
         & " actual="
         & PSX.Types.Word32'Image (GTE.IR1));
   end if;

   if GTE.IR2 = Expected_IR2 then
      Ada.Text_IO.Put_Line ("PASS: OP SF IR2");
   else
      Ada.Text_IO.Put_Line
        ("FAIL: OP SF IR2 expected="
         & PSX.Types.Word32'Image (Expected_IR2)
         & " actual="
         & PSX.Types.Word32'Image (GTE.IR2));
   end if;

   if GTE.IR3 = Expected_IR3 then
      Ada.Text_IO.Put_Line ("PASS: OP SF IR3");
   else
      Ada.Text_IO.Put_Line
        ("FAIL: OP SF IR3 expected="
         & PSX.Types.Word32'Image (Expected_IR3)
         & " actual="
         & PSX.Types.Word32'Image (GTE.IR3));
   end if;

   if GTE.FLAG = 0 then
      Ada.Text_IO.Put_Line ("PASS: OP SF FLAG");
   else
      Ada.Text_IO.Put_Line
        ("FAIL: OP SF FLAG actual=" & PSX.Types.Word32'Image (GTE.FLAG));
   end if;

   Ada.Text_IO.Put_Line ("PSX GTE OP SF tests finished.");

end PSX_GTE_OP_SF_Tests;
