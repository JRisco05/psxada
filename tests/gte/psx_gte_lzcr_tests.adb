with Ada.Text_IO;
with Interfaces;
with PSX.GTE;
with PSX.Types;

procedure PSX_GTE_LZCR_Tests is

   use type Interfaces.Unsigned_32;
   use Ada.Text_IO;

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
            & " expected="
            & PSX.Types.Word32'Image (Expected)
            & " actual="
            & PSX.Types.Word32'Image (Actual));
      end if;
   end Check;

begin
   Put_Line ("Testing PSX GTE LZCS/LZCR...");
   New_Line;

   PSX.GTE.Reset (GTE);

   --  32 leading zeroes.
   PSX.GTE.Write_Data (GTE, 30, 16#0000_0000#);

   Check ("LZCS = 0", PSX.GTE.Read_Data (GTE, 30), 16#0000_0000#);

   Check ("LZCR 0x00000000", PSX.GTE.Read_Data (GTE, 31), 32);

   --  One leading one.
   PSX.GTE.Write_Data (GTE, 30, 16#8000_0000#);

   Check ("LZCS = 0x80000000", PSX.GTE.Read_Data (GTE, 30), 16#8000_0000#);

   Check ("LZCR 0x80000000", PSX.GTE.Read_Data (GTE, 31), 1);

   --  Four leading zeroes.
   PSX.GTE.Write_Data (GTE, 30, 16#0FFF_FFFF#);

   Check ("LZCR four leading zeroes", PSX.GTE.Read_Data (GTE, 31), 4);

   --  Four leading ones.
   PSX.GTE.Write_Data (GTE, 30, 16#F000_0000#);

   Check ("LZCR four leading ones", PSX.GTE.Read_Data (GTE, 31), 4);

   --  Eight leading zeroes.
   PSX.GTE.Write_Data (GTE, 30, 16#00FF_FFFF#);

   Check ("LZCR eight leading zeroes", PSX.GTE.Read_Data (GTE, 31), 8);

   --  Eight leading ones.
   PSX.GTE.Write_Data (GTE, 30, 16#FF00_0000#);

   Check ("LZCR eight leading ones", PSX.GTE.Read_Data (GTE, 31), 8);

   --  One leading one followed by zero.
   PSX.GTE.Write_Data (GTE, 30, 16#8000_0001#);

   Check ("LZCR single leading one", PSX.GTE.Read_Data (GTE, 31), 1);

   --  All ones.
   PSX.GTE.Write_Data (GTE, 30, 16#FFFF_FFFF#);

   Check ("LZCR all ones", PSX.GTE.Read_Data (GTE, 31), 32);

   --  LZCR is read-only.
   PSX.GTE.Write_Data (GTE, 31, 16#1234_5678#);

   Check ("LZCR remains read-only", PSX.GTE.Read_Data (GTE, 31), 32);

   Put_Line ("");
   Put_Line ("PSX GTE LZCS/LZCR tests finished.");

end PSX_GTE_LZCR_Tests;
