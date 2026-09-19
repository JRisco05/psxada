with Ada.Text_IO; use Ada.Text_IO;
with PSX.GTE;
with PSX.GTE.Instruction;
with PSX.GTE.Execute;
with PSX.Types;
with Interfaces;

procedure PSX_GTE_MVMVA_IR_Negative_Saturation_Tests is

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
   Put_Line ("Testing PSX GTE MVMVA IR negative saturation...");

   PSX.GTE.Reset (GTE);

   -- V0 = large negative values
   GTE.V0_X := 16#8000#;
   GTE.V0_Y := 16#8000#;
   GTE.V0_Z := 16#8000#;

   -- Rotation matrix = identity
   GTE.RT11 := 4096;
   GTE.RT22 := 4096;
   GTE.RT33 := 4096;

   -- CV=3: no translation
   -- MX=0: rotation matrix
   -- V=0: V0
   -- SF=1
   -- LM=0: allow negative range down to -32768
   Inst.Raw := 16#0008_600C#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   -- Exact minimum representable IR value.
   Check ("IR1 negative saturation", GTE.IR1, 16#FFFF_8000#);
   Check ("IR2 negative saturation", GTE.IR2, 16#FFFF_8000#);
   Check ("IR3 negative saturation", GTE.IR3, 16#FFFF_8000#);

   -- No saturation should occur because -32768 is exactly the limit.
   Check ("FLAG IR negative saturation", GTE.FLAG, 0);

   Put_Line ("PSX GTE MVMVA IR negative saturation tests finished.");

end PSX_GTE_MVMVA_IR_Negative_Saturation_Tests;
