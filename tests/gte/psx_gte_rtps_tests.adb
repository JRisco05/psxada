with Ada.Text_IO;
with PSX.GTE;
with PSX.GTE.Execute;
with PSX.GTE.Instruction;
with PSX.Types;
with Interfaces;

procedure PSX_GTE_RTPS_Tests is

   use type Interfaces.Unsigned_32;
   
   use Ada.Text_IO;

   GTE : PSX.GTE.GTE_State;

   Inst : PSX.GTE.Instruction.Instruction;

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

   Put_Line ("Testing PSX GTE RTPS...");
   New_Line;

   PSX.GTE.Reset (GTE);

   -- =========================================================
   -- Identity rotation matrix.
   -- 1.0 in GTE fixed point = 0x1000.
   -- =========================================================

   PSX.GTE.Write_Control
     (GTE, 32, 16#0000_1000#);

   PSX.GTE.Write_Control
     (GTE, 33, 16#0000_0000#);

   PSX.GTE.Write_Control
     (GTE, 34, 16#0000_1000#);

   PSX.GTE.Write_Control
     (GTE, 35, 16#0000_0000#);

   PSX.GTE.Write_Control
     (GTE, 36, 16#0000_1000#);

   -- Translation = 0.
   PSX.GTE.Write_Control
     (GTE, 37, 0);

   PSX.GTE.Write_Control
     (GTE, 38, 0);

   PSX.GTE.Write_Control
     (GTE, 39, 0);

   -- Screen offset = 0.
   PSX.GTE.Write_Control
     (GTE, 56, 0);

   PSX.GTE.Write_Control
     (GTE, 57, 0);

   -- H = 1000.
   PSX.GTE.Write_Control
     (GTE, 58, 1000);

   -- DQA/DQB = 0.
   PSX.GTE.Write_Control
     (GTE, 59, 0);

   PSX.GTE.Write_Control
     (GTE, 60, 0);

   -- Vertex V0 = (100, 200, 1000).
   PSX.GTE.Write_Data
     (GTE, 0, 16#00C8_0064#);

   PSX.GTE.Write_Data
     (GTE, 1, 1000);

   -- Preload FIFOs so we can verify the shift.
   PSX.GTE.Write_Data
     (GTE, 16, 1);

   PSX.GTE.Write_Data
     (GTE, 17, 2);

   PSX.GTE.Write_Data
     (GTE, 18, 3);

   PSX.GTE.Write_Data
     (GTE, 19, 4);

   -- RTPS command:
   -- command = 01h
   -- sf = 1
   -- lm = 0
   Inst.Raw := 16#0008_0001#;

   PSX.GTE.Execute.Execute
     (GTE, Inst);

   -- =========================================================
   -- Rotation / translation
   -- =========================================================

   Check
     ("IR1",
      GTE.IR1,
      100);

   Check
     ("IR2",
      GTE.IR2,
      200);

   Check
     ("IR3",
      GTE.IR3,
      1000);

   Check
     ("MAC1",
      GTE.MAC1,
      100);

   Check
     ("MAC2",
      GTE.MAC2,
      200);

   Check
     ("MAC3",
      GTE.MAC3,
      1000);

   -- =========================================================
   -- SZ FIFO
   -- =========================================================

   Check
     ("SZ0 FIFO",
      GTE.SZ0,
      2);

   Check
     ("SZ1 FIFO",
      GTE.SZ1,
      3);

   Check
     ("SZ2 FIFO",
      GTE.SZ2,
      4);

   Check
     ("SZ3 FIFO",
      GTE.SZ3,
      1000);

   -- =========================================================
   -- Perspective projection
   --
   -- H = 1000
   -- SZ3 = 1000
   -- factor = 65536
   --
   -- SX = 100
   -- SY = 200
   -- =========================================================

   Check
     ("SX2",
      GTE.SX2,
      100);

   Check
     ("SY2",
      GTE.SY2,
      200);

   -- =========================================================
   -- Depth cue
   -- =========================================================

   Check
     ("IR0",
      GTE.IR0,
      0);

   -- No saturation expected.
   Check
     ("FLAG",
      GTE.FLAG,
      0);

   Put_Line ("");
   Put_Line ("PSX GTE RTPS tests finished.");

end PSX_GTE_RTPS_Tests;