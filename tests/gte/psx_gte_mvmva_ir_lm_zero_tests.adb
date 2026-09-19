with Ada.Text_IO; use Ada.Text_IO;
with PSX.GTE;
with PSX.GTE.Instruction;
with PSX.GTE.Execute;
with PSX.Types;
with Interfaces;

procedure PSX_GTE_MVMVA_IR_LM_Zero_Tests is

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
   Put_Line ("Testing PSX GTE MVMVA LM=1 lower saturation...");

   PSX.GTE.Reset (GTE);

   -- Negative V0 values
   GTE.V0_X := 16#8000#;
   GTE.V0_Y := 16#8000#;
   GTE.V0_Z := 16#8000#;

   -- Identity rotation matrix
   GTE.RT11 := 4096;
   GTE.RT22 := 4096;
   GTE.RT33 := 4096;

   -- CV=3: no translation
   -- MX=0: rotation matrix
   -- V=0: V0
   -- SF=1
   -- LM=1: lower limit is 0
   Inst.Raw := 16#0008_640C#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   -- Negative results must saturate to zero.
   Check ("IR1 LM=1 lower saturation", GTE.IR1, 0);

   Check ("IR2 LM=1 lower saturation", GTE.IR2, 0);

   Check ("IR3 LM=1 lower saturation", GTE.IR3, 0);

   -- Saturation flags.
   Check ("IR1 LM=1 FLAG bit 24", GTE.FLAG and 16#0100_0000#, 16#0100_0000#);

   Check ("IR2 LM=1 FLAG bit 23", GTE.FLAG and 16#0080_0000#, 16#0080_0000#);

   Check ("IR3 LM=1 FLAG bit 22", GTE.FLAG and 16#0040_0000#, 16#0040_0000#);

   Put_Line ("PSX GTE MVMVA LM=1 lower saturation tests finished.");

end PSX_GTE_MVMVA_IR_LM_Zero_Tests;
