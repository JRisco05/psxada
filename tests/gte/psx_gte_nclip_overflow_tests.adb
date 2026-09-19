with Ada.Text_IO; use Ada.Text_IO;
with PSX.GTE;
with PSX.GTE.Instruction;
with PSX.GTE.Execute;
with PSX.Types;
with Interfaces;

procedure PSX_GTE_NCLIP_Overflow_Tests is

   use type Interfaces.Unsigned_32;

   GTE : PSX.GTE.GTE_State;

   procedure Check
     (Name : String; Actual : PSX.Types.Word32; Expected : PSX.Types.Word32) is
   begin
      if Actual = Expected then
         Put_Line ("PASS: " & Name);
      else
         Put_Line
           ("FAIL: "
            & Name
            & " expected=0x"
            & PSX.Types.Word32'Image (Expected)
            & " actual=0x"
            & PSX.Types.Word32'Image (Actual));
      end if;
   end Check;

   Inst : PSX.GTE.Instruction.Instruction;

begin
   Put_Line ("Testing PSX GTE NCLIP MAC0 overflow...");

   PSX.GTE.Reset (GTE);

   -- Large coordinates to force MAC0 beyond signed 32-bit range.
   GTE.SX0 := 16#7FFF#;
   GTE.SY0 := 16#7FFF#;

   GTE.SX1 := 16#8000#;
   GTE.SY1 := 16#7FFF#;

   GTE.SX2 := 16#7FFF#;
   GTE.SY2 := 16#8000#;

   -- Command = NCLIP (6)
   Inst.Raw := 16#0000_0006#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   -- MAC0 must overflow the signed 32-bit range.
   Check
     ("NCLIP MAC0 overflow FLAG bit 16",
      GTE.FLAG and 16#0001_0000#,
      16#0001_0000#);

   Put_Line ("PSX GTE NCLIP MAC0 overflow tests finished.");

end PSX_GTE_NCLIP_Overflow_Tests;
