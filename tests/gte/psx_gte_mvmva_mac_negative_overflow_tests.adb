with Ada.Text_IO; use Ada.Text_IO;
with PSX.GTE;
with PSX.GTE.Instruction;
with PSX.GTE.Execute;
with PSX.Types;
with Interfaces;

procedure PSX_GTE_MVMVA_MAC_Negative_Overflow_Tests is

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
   Put_Line ("Testing PSX GTE MVMVA MAC negative overflow...");

   PSX.GTE.Reset (GTE);

   -- V0 = maximum positive values
   GTE.V0_X := 16#8000#;
   GTE.V0_Y := 16#8000#;
   GTE.V0_Z := 16#8000#;

   -- Rotation matrix = maximum positive values
   GTE.RT11 := 32767;
   GTE.RT12 := 32767;
   GTE.RT13 := 32767;

   GTE.RT21 := 32767;
   GTE.RT22 := 32767;
   GTE.RT23 := 32767;

   GTE.RT31 := 32767;
   GTE.RT32 := 32767;
   GTE.RT33 := 32767;

   -- Translation = minimum signed 32-bit value
   GTE.TRX := 16#8000_0000#;
   GTE.TRY := 16#8000_0000#;
   GTE.TRZ := 16#8000_0000#;

   -- CV=0: translation vector
   -- MX=0: rotation matrix
   -- V=0: V0
   -- SF=0
   -- LM=0
   -- Command=MVMVA (12)
   Inst.Raw := 16#0000_000C#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   -- Negative MAC overflow flags:
   -- MAC1 -> bit 30
   -- MAC2 -> bit 29
   -- MAC3 -> bit 28
   Check
     ("MAC1 negative overflow FLAG bit 30",
      GTE.FLAG and 16#4000_0000#,
      16#4000_0000#);

   Check
     ("MAC2 negative overflow FLAG bit 29",
      GTE.FLAG and 16#2000_0000#,
      16#2000_0000#);

   Check
     ("MAC3 negative overflow FLAG bit 28",
      GTE.FLAG and 16#1000_0000#,
      16#1000_0000#);

   Put_Line ("PSX GTE MVMVA MAC negative overflow tests finished.");

end PSX_GTE_MVMVA_MAC_Negative_Overflow_Tests;
