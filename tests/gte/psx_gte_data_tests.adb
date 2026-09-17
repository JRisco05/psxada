with Ada.Text_IO;
with PSX.GTE;
with PSX.Types;
with Interfaces;

procedure PSX_GTE_Data_Tests is

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
   Put_Line ("Testing PSX GTE data registers...");
   New_Line;

   PSX.GTE.Reset (GTE);

   --  V0X / V0Y
   PSX.GTE.Write_Data (GTE, 0, 16#2222_1111#);

   Check ("V0X", GTE.V0_X, 16#0000_1111#);

   Check ("V0Y", GTE.V0_Y, 16#0000_2222#);

   Check ("V0 packed read", PSX.GTE.Read_Data (GTE, 0), 16#2222_1111#);

   --  V0Z
   PSX.GTE.Write_Data (GTE, 1, 16#3333_3333#);

   Check ("V0Z", GTE.V0_Z, 16#3333_3333#);

   --  V1X / V1Y
   PSX.GTE.Write_Data (GTE, 2, 16#5555_4444#);

   Check ("V1X", GTE.V1_X, 16#0000_4444#);

   Check ("V1Y", GTE.V1_Y, 16#0000_5555#);

   --  V1Z
   PSX.GTE.Write_Data (GTE, 3, 16#6666_6666#);

   Check ("V1Z", GTE.V1_Z, 16#6666_6666#);

   --  V2X / V2Y
   PSX.GTE.Write_Data (GTE, 4, 16#8888_7777#);

   Check ("V2X", GTE.V2_X, 16#0000_7777#);

   Check ("V2Y", GTE.V2_Y, 16#0000_8888#);

   --  V2Z
   PSX.GTE.Write_Data (GTE, 5, 16#9999_9999#);

   Check ("V2Z", GTE.V2_Z, 16#9999_9999#);

   --  SXY FIFO
   PSX.GTE.Write_Data (GTE, 12, 16#BBBB_AAAA#);

   Check ("SX0", GTE.SX0, 16#0000_AAAA#);

   Check ("SY0", GTE.SY0, 16#0000_BBBB#);

   PSX.GTE.Write_Data (GTE, 13, 16#DDDD_CCCC#);

   Check ("SX1", GTE.SX1, 16#0000_CCCC#);

   Check ("SY1", GTE.SY1, 16#0000_DDDD#);

   PSX.GTE.Write_Data (GTE, 14, 16#FFFF_EEEE#);

   Check ("SX2", GTE.SX2, 16#0000_EEEE#);

   Check ("SY2", GTE.SY2, 16#0000_FFFF#);

   --  SXYP writes must push the FIFO.
   PSX.GTE.Write_Data (GTE, 15, 16#2222_1111#);

   Check ("SXY FIFO SX0", GTE.SX0, 16#0000_CCCC#);

   Check ("SXY FIFO SY0", GTE.SY0, 16#0000_DDDD#);

   Check ("SXY FIFO SX1", GTE.SX1, 16#0000_EEEE#);

   Check ("SXY FIFO SY1", GTE.SY1, 16#0000_FFFF#);

   Check ("SXY FIFO SX2", GTE.SX2, 16#0000_1111#);

   Check ("SXY FIFO SY2", GTE.SY2, 16#0000_2222#);

   --  SZ FIFO / depth registers

   PSX.GTE.Write_Data (GTE, 16, 16#0000_1111#);

   Check ("SZ0", GTE.SZ0, 16#0000_1111#);

   PSX.GTE.Write_Data (GTE, 17, 16#0000_2222#);

   Check ("SZ1", GTE.SZ1, 16#0000_2222#);

   PSX.GTE.Write_Data (GTE, 18, 16#0000_3333#);

   Check ("SZ2", GTE.SZ2, 16#0000_3333#);

   PSX.GTE.Write_Data (GTE, 19, 16#0000_4444#);

   Check ("SZ3", GTE.SZ3, 16#0000_4444#);

   Check ("SZ0 read", PSX.GTE.Read_Data (GTE, 16), 16#0000_1111#);

   Check ("SZ3 read", PSX.GTE.Read_Data (GTE, 19), 16#0000_4444#);

   --  IR registers

   PSX.GTE.Write_Data (GTE, 8, 16#0000_1111#);

   PSX.GTE.Write_Data (GTE, 9, 16#0000_2222#);

   PSX.GTE.Write_Data (GTE, 10, 16#0000_3333#);

   PSX.GTE.Write_Data (GTE, 11, 16#0000_4444#);

   Check ("IR0", GTE.IR0, 16#0000_1111#);
   Check ("IR1", GTE.IR1, 16#0000_2222#);
   Check ("IR2", GTE.IR2, 16#0000_3333#);
   Check ("IR3", GTE.IR3, 16#0000_4444#);

   --  MAC registers

   PSX.GTE.Write_Data (GTE, 24, 16#1111_1111#);

   PSX.GTE.Write_Data (GTE, 25, 16#2222_2222#);

   PSX.GTE.Write_Data (GTE, 26, 16#3333_3333#);

   PSX.GTE.Write_Data (GTE, 27, 16#4444_4444#);

   Check ("MAC0", GTE.MAC0, 16#1111_1111#);
   Check ("MAC1", GTE.MAC1, 16#2222_2222#);
   Check ("MAC2", GTE.MAC2, 16#3333_3333#);
   Check ("MAC3", GTE.MAC3, 16#4444_4444#);

   Check ("MAC0 read", PSX.GTE.Read_Data (GTE, 24), 16#1111_1111#);

   Check ("MAC3 read", PSX.GTE.Read_Data (GTE, 27), 16#4444_4444#);

   Put_Line ("");
   Put_Line ("PSX GTE data register tests finished.");

end PSX_GTE_Data_Tests;
