with Ada.Text_IO; use Ada.Text_IO;
with PSX.GTE;
with PSX.GTE.Instruction;
with PSX.GTE.Execute;
with PSX.Types;
with Interfaces;

procedure PSX_GTE_NCLIP_Negative_Tests is

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
   Put_Line ("Testing PSX GTE NCLIP negative result...");

   PSX.GTE.Reset (GTE);

   -- Reversed triangle:
   -- P0 = (0, 0)
   -- P1 = (0, 100)
   -- P2 = (100, 0)
   GTE.SX0 := 0;
   GTE.SY0 := 0;

   GTE.SX1 := 0;
   GTE.SY1 := 100;

   GTE.SX2 := 100;
   GTE.SY2 := 0;

   -- Command = NCLIP (6)
   Inst.Raw := 16#0000_0006#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   -- Expected MAC0 = -10000
   Check ("NCLIP negative MAC0", GTE.MAC0, 16#FFFF_D8F0#);

   Check ("NCLIP negative FLAG", GTE.FLAG, 0);

   Put_Line ("PSX GTE NCLIP negative tests finished.");

end PSX_GTE_NCLIP_Negative_Tests;
