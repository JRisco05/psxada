with Ada.Text_IO;
with PSX.GTE;
with PSX.Types;
with Interfaces;

procedure PSX_GTE_Control_Tests is

   use type Interfaces.Unsigned_32;

   use Ada.Text_IO;

   GTE : PSX.GTE.GTE_State;

   procedure Check
     (Name     : String;
      Actual   : PSX.Types.Word32;
      Expected : PSX.Types.Word32) is
   begin
      if Actual = Expected then
         Put_Line ("PASS: " & Name);
      else
         Put_Line
           ("FAIL: " & Name
            & " expected="
            & PSX.Types.Word32'Image (Expected)
            & " actual="
            & PSX.Types.Word32'Image (Actual));
      end if;
   end Check;

begin
   Put_Line ("Testing PSX GTE control registers...");
   New_Line;

   PSX.GTE.Reset (GTE);

   --  RT11 / RT12
   PSX.GTE.Write_Control
     (GTE, 32, 16#2222_1111#);

   Check ("RT11", GTE.RT11, 16#0000_1111#);
   Check ("RT12", GTE.RT12, 16#0000_2222#);

   Check
     ("RT11/RT12 packed",
      PSX.GTE.Read_Control (GTE, 32),
      16#2222_1111#);

   --  RT13 / RT21
   PSX.GTE.Write_Control
     (GTE, 33, 16#4444_3333#);

   Check ("RT13", GTE.RT13, 16#0000_3333#);
   Check ("RT21", GTE.RT21, 16#0000_4444#);

   Check
     ("RT13/RT21 packed",
      PSX.GTE.Read_Control (GTE, 33),
      16#4444_3333#);

   --  Translation vector
   PSX.GTE.Write_Control
     (GTE, 37, 16#1111_1111#);

   PSX.GTE.Write_Control
     (GTE, 38, 16#2222_2222#);

   PSX.GTE.Write_Control
     (GTE, 39, 16#3333_3333#);

   Check ("TRX", GTE.TRX, 16#1111_1111#);
   Check ("TRY", GTE.TRY, 16#2222_2222#);
   Check ("TRZ", GTE.TRZ, 16#3333_3333#);

   --  Light matrix
   PSX.GTE.Write_Control
     (GTE, 40, 16#BBBB_AAAA#);

   Check ("L11", GTE.L11, 16#0000_AAAA#);
   Check ("L12", GTE.L12, 16#0000_BBBB#);

   --  Background color
   PSX.GTE.Write_Control
     (GTE, 45, 16#1111_1111#);

   PSX.GTE.Write_Control
     (GTE, 46, 16#2222_2222#);

   PSX.GTE.Write_Control
     (GTE, 47, 16#3333_3333#);

   Check ("RBK", GTE.RBK, 16#1111_1111#);
   Check ("GBK", GTE.GBK, 16#2222_2222#);
   Check ("BBK", GTE.BBK, 16#3333_3333#);

   --  Light color matrix
   PSX.GTE.Write_Control
     (GTE, 48, 16#BBBB_AAAA#);

   Check ("LR1", GTE.LR1, 16#0000_AAAA#);
   Check ("LR2", GTE.LR2, 16#0000_BBBB#);

   --  Far color
   PSX.GTE.Write_Control
     (GTE, 53, 16#1111_1111#);
   PSX.GTE.Write_Control
     (GTE, 54, 16#2222_2222#);
   PSX.GTE.Write_Control
     (GTE, 55, 16#3333_3333#);

   Check ("RFC", GTE.RFC, 16#1111_1111#);
   Check ("GFC", GTE.GFC, 16#2222_2222#);
   Check ("BFC", GTE.BFC, 16#3333_3333#);

   --  Screen offset / projection
   PSX.GTE.Write_Control
     (GTE, 56, 16#1111_1111#);

   PSX.GTE.Write_Control
     (GTE, 57, 16#2222_2222#);

   PSX.GTE.Write_Control
     (GTE, 58, 16#0000_3333#);

   Check ("OFX", GTE.OFX, 16#1111_1111#);
   Check ("OFY", GTE.OFY, 16#2222_2222#);
   Check ("H", GTE.H, 16#0000_3333#);

   --  Depth cue
   PSX.GTE.Write_Control
     (GTE, 59, 16#0000_4444#);

   PSX.GTE.Write_Control
     (GTE, 60, 16#5555_5555#);

   Check ("DQA", GTE.DQA, 16#0000_4444#);
   Check ("DQB", GTE.DQB, 16#5555_5555#);

   --  Depth averaging
   PSX.GTE.Write_Control
     (GTE, 61, 16#0000_6666#);

   PSX.GTE.Write_Control
     (GTE, 62, 16#0000_7777#);

   Check ("ZSF3", GTE.ZSF3, 16#0000_6666#);
   Check ("ZSF4", GTE.ZSF4, 16#0000_7777#);

   --  FLAG is read-only.
   Check
     ("FLAG reset",
      PSX.GTE.Read_Control (GTE, 63),
      0);

   PSX.GTE.Write_Control
     (GTE, 63, 16#FFFF_FFFF#);

   Check
     ("FLAG remains read-only",
      PSX.GTE.Read_Control (GTE, 63),
      0);

   Put_Line ("");
   Put_Line ("PSX GTE control register tests finished.");

end PSX_GTE_Control_Tests;