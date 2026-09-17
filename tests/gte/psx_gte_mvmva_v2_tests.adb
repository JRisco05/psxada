with Ada.Text_IO;
with PSX.GTE;
with PSX.GTE.Instruction;
with PSX.GTE.Execute;
with PSX.Types;
with Interfaces;

procedure PSX_GTE_MVMVA_V2_Tests is

   use type Interfaces.Unsigned_32;
   use Ada.Text_IO;

   GTE  : PSX.GTE.GTE_State;
   Inst : PSX.GTE.Instruction.Instruction;

   procedure Check
     (Name : String; Expected : PSX.Types.Word32; Actual : PSX.Types.Word32) is
   begin
      if Expected = Actual then
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

begin
   Put_Line ("Testing PSX GTE MVMVA V=2...");

   PSX.GTE.Reset (GTE);

   --  V0 = (100, 200, 300)
   GTE.V0_X := 100;
   GTE.V0_Y := 200;
   GTE.V0_Z := 300;

   --  V1 = (400, 500, 600)
   GTE.V1_X := 400;
   GTE.V1_Y := 500;
   GTE.V1_Z := 600;

   --  V2 = (700, 800, 900)
   GTE.V2_X := 700;
   GTE.V2_Y := 800;
   GTE.V2_Z := 900;

   --  Matriz identidad (4096 = 1.0 en formato 12.4)
   GTE.RT11 := 4096;
   GTE.RT12 := 0;
   GTE.RT13 := 0;

   GTE.RT21 := 0;
   GTE.RT22 := 4096;
   GTE.RT23 := 0;

   GTE.RT31 := 0;
   GTE.RT32 := 0;
   GTE.RT33 := 4096;

   --  Sin traslación
   GTE.TRX := 0;
   GTE.TRY := 0;
   GTE.TRZ := 0;

   --  SF=1, V=2, LM=0, MX=0, CV=0, CMD=12
   Inst.Raw := 16#0009_000C#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   Check ("IR1 V=2", 700, GTE.IR1);
   Check ("IR2 V=2", 800, GTE.IR2);
   Check ("IR3 V=2", 900, GTE.IR3);

   Check ("MAC1 V=2", 700, GTE.MAC1);
   Check ("MAC2 V=2", 800, GTE.MAC2);
   Check ("MAC3 V=2", 900, GTE.MAC3);

   Check ("FLAG V=2", 0, GTE.FLAG);

   Put_Line ("PSX GTE MVMVA V=2 tests finished.");

end PSX_GTE_MVMVA_V2_Tests;
