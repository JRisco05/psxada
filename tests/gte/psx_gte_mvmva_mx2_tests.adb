with Ada.Text_IO; use Ada.Text_IO;
with PSX.GTE;
with PSX.GTE.Instruction;
with PSX.GTE.Execute;
with PSX.Types;
with Interfaces;

procedure PSX_GTE_MVMVA_MX2_Tests is

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
   Put_Line ("Testing PSX GTE MVMVA MX=2...");

   PSX.GTE.Reset (GTE);

   -- V0 = (100, 200, 300)
   GTE.V0_X := 100;
   GTE.V0_Y := 200;
   GTE.V0_Z := 300;

   -- RT = identity
   GTE.RT11 := 4096;
   GTE.RT22 := 4096;
   GTE.RT33 := 4096;

   -- Light matrix = identity
   GTE.L11 := 4096;
   GTE.L22 := 4096;
   GTE.L33 := 4096;

   -- Color matrix = 2 * identity
   GTE.LR1 := 8192;
   GTE.LG2 := 8192;
   GTE.LB3 := 8192;

   -- Translation = 0
   GTE.TRX := 0;
   GTE.TRY := 0;
   GTE.TRZ := 0;

   -- SF=1
   -- MX=2
   -- V=0
   -- CV=0
   -- LM=0
   -- Command=MVMVA (12)
   Inst.Raw := 16#000C_000C#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   -- MX=2 must use the Color Matrix.
   -- (100,200,300) * 2 = (200,400,600)
   Check ("IR1 MX=2", GTE.IR1, 200);
   Check ("IR2 MX=2", GTE.IR2, 400);
   Check ("IR3 MX=2", GTE.IR3, 600);

   Check ("MAC1 MX=2", GTE.MAC1, 200);
   Check ("MAC2 MX=2", GTE.MAC2, 400);
   Check ("MAC3 MX=2", GTE.MAC3, 600);

   Check ("FLAG MX=2", GTE.FLAG, 0);

   Put_Line ("PSX GTE MVMVA MX=2 tests finished.");

end PSX_GTE_MVMVA_MX2_Tests;
