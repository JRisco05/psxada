with PSX.GTE.Instruction;
with Ada.Text_IO;
with PSX.Types;
with PSX.GTE;
with PSX.GTE.Execute;
with Interfaces;

procedure PSX_GTE_MVMVA_V3_Tests is

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
   Put_Line ("Testing PSX GTE MVMVA V=3...");

   PSX.GTE.Reset (GTE);

   -- Vector IR = (100, 200, 300)
   GTE.IR1 := 100;
   GTE.IR2 := 200;
   GTE.IR3 := 300;

   -- Matriz identidad
   GTE.RT11 := 4096;
   GTE.RT12 := 0;
   GTE.RT13 := 0;

   GTE.RT21 := 0;
   GTE.RT22 := 4096;
   GTE.RT23 := 0;

   GTE.RT31 := 0;
   GTE.RT32 := 0;
   GTE.RT33 := 4096;

   -- Sin traslación
   GTE.TRX := 0;
   GTE.TRY := 0;
   GTE.TRZ := 0;

   -- SF=1, V=3, MX=0, CV=0, LM=0, CMD=12
   Inst.Raw := 16#0009_800C#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   Check ("IR1 V=3", 100, GTE.IR1);
   Check ("IR2 V=3", 200, GTE.IR2);
   Check ("IR3 V=3", 300, GTE.IR3);

   Check ("MAC1 V=3", 100, GTE.MAC1);
   Check ("MAC2 V=3", 200, GTE.MAC2);
   Check ("MAC3 V=3", 300, GTE.MAC3);

   Check ("FLAG V=3", 0, GTE.FLAG);

   Put_Line ("PSX GTE MVMVA V=3 tests finished.");

end PSX_GTE_MVMVA_V3_Tests;
