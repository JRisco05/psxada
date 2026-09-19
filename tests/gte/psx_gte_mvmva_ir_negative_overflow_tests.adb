with Ada.Text_IO; use Ada.Text_IO;
with PSX.GTE;
with PSX.GTE.Instruction;
with PSX.GTE.Execute;
with PSX.Types;
with Interfaces;

procedure PSX_GTE_MVMVA_IR_Negative_Overflow_Tests is

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
   Put_Line ("Testing PSX GTE MVMVA IR negative overflow...");

   PSX.GTE.Reset (GTE);

   -- V0 = -32768
   GTE.V0_X := 16#8000#;
   GTE.V0_Y := 16#8000#;
   GTE.V0_Z := 16#8000#;

   -- Rotation matrix slightly greater than 1.0
   -- 4097 / 4096
   GTE.RT11 := 4097;
   GTE.RT22 := 4097;
   GTE.RT33 := 4097;

   -- CV=3: no translation
   -- MX=0: rotation matrix
   -- V=0: V0
   -- SF=1
   -- LM=0
   Inst.Raw := 16#0008_600C#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   -- Values below -32768 must saturate to -32768.
   Check ("IR1 negative overflow saturation", GTE.IR1, 16#FFFF_8000#);

   Check ("IR2 negative overflow saturation", GTE.IR2, 16#FFFF_8000#);

   Check ("IR3 negative overflow saturation", GTE.IR3, 16#FFFF_8000#);

   -- IR saturation flags:
   -- IR1 -> bit 24
   -- IR2 -> bit 23
   -- IR3 -> bit 22
   Check
     ("IR1 saturation FLAG bit 24", GTE.FLAG and 16#0100_0000#, 16#0100_0000#);

   Check
     ("IR2 saturation FLAG bit 23", GTE.FLAG and 16#0080_0000#, 16#0080_0000#);

   Check
     ("IR3 saturation FLAG bit 22", GTE.FLAG and 16#0040_0000#, 16#0040_0000#);

   Put_Line ("PSX GTE MVMVA IR negative overflow tests finished.");

end PSX_GTE_MVMVA_IR_Negative_Overflow_Tests;
