with Ada.Text_IO; use Ada.Text_IO;
with PSX.GTE;
with PSX.GTE.Instruction;
with PSX.GTE.Execute;
with PSX.Types;
with Interfaces;

procedure PSX_GTE_MVMVA_IR_Positive_Overflow_Tests is

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
   Put_Line ("Testing PSX GTE MVMVA IR positive overflow...");

   PSX.GTE.Reset (GTE);

   -- V0 = maximum positive signed 16-bit value
   GTE.V0_X := 32767;
   GTE.V0_Y := 32767;
   GTE.V0_Z := 32767;

   -- Slightly larger than identity
   -- 8192 / 4096 = 2.0
   GTE.RT11 := 8192;
   GTE.RT22 := 8192;
   GTE.RT33 := 8192;

   -- CV=3: no translation
   -- MX=0: rotation matrix
   -- V=0: V0
   -- SF=1
   -- LM=0
   Inst.Raw := 16#0008_600C#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   -- 32767 * 2 = 65534 -> saturates to 32767.
   Check ("IR1 positive overflow saturation", GTE.IR1, 32767);

   Check ("IR2 positive overflow saturation", GTE.IR2, 32767);

   Check ("IR3 positive overflow saturation", GTE.IR3, 32767);

   -- Saturation flags.
   Check
     ("IR1 positive saturation FLAG bit 24",
      GTE.FLAG and 16#0100_0000#,
      16#0100_0000#);

   Check
     ("IR2 positive saturation FLAG bit 23",
      GTE.FLAG and 16#0080_0000#,
      16#0080_0000#);

   Check
     ("IR3 positive saturation FLAG bit 22",
      GTE.FLAG and 16#0040_0000#,
      16#0040_0000#);

   Put_Line ("PSX GTE MVMVA IR positive overflow tests finished.");

end PSX_GTE_MVMVA_IR_Positive_Overflow_Tests;
