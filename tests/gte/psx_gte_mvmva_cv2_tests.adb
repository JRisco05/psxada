with Ada.Text_IO; use Ada.Text_IO;
with PSX.GTE;
with PSX.GTE.Instruction;
with PSX.GTE.Execute;
with PSX.Types;
with Interfaces;

procedure PSX_GTE_MVMVA_CV2_Tests is

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
   Put_Line ("Testing PSX GTE MVMVA CV=2...");

   PSX.GTE.Reset (GTE);

   -- V0 = (100, 200, 300)
   GTE.V0_X := 100;
   GTE.V0_Y := 200;
   GTE.V0_Z := 300;

   -- RT = identity
   GTE.RT11 := 4096;
   GTE.RT22 := 4096;
   GTE.RT33 := 4096;

   -- Far Color = (1000, 2000, 3000)
   GTE.RFC := 1000;
   GTE.GFC := 2000;
   GTE.BFC := 3000;

   -- CV=2
   -- MX=0
   -- V=0
   -- SF=1
   -- LM=0
   -- Command=MVMVA (12)
   Inst.Raw := 16#0008_400C#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   -- V0 + FC = (1100, 2200, 3300)
   Check ("IR1 CV=2", GTE.IR1, 1100);
   Check ("IR2 CV=2", GTE.IR2, 2200);
   Check ("IR3 CV=2", GTE.IR3, 3300);

   Check ("MAC1 CV=2", GTE.MAC1, 1100);
   Check ("MAC2 CV=2", GTE.MAC2, 2200);
   Check ("MAC3 CV=2", GTE.MAC3, 3300);

   Check ("FLAG CV=2", GTE.FLAG, 0);

   Put_Line ("PSX GTE MVMVA CV=2 tests finished.");

end PSX_GTE_MVMVA_CV2_Tests;
