with Ada.Text_IO;
with Interfaces;
with PSX.GTE;
with PSX.GTE.Instruction;
with PSX.GTE.Execute;

procedure PSX_GTE_RTPT_Tests is

   use Ada.Text_IO;
   use type Interfaces.Unsigned_32;

   GTE : PSX.GTE.GTE_State;

   procedure Check
     (Name     : String;
      Expected : Interfaces.Unsigned_32;
      Actual   : Interfaces.Unsigned_32) is
   begin
      if Expected = Actual then
         Put_Line ("PASS: " & Name);
      else
         Put_Line
           ("FAIL: " & Name &
            " expected=0x" & Interfaces.Unsigned_32'Image (Expected) &
            " actual=0x" & Interfaces.Unsigned_32'Image (Actual));
      end if;
   end Check;

   procedure Setup_Identity is
   begin
      PSX.GTE.Reset (GTE);

      GTE.RT11 := 16#0000_1000#;
      GTE.RT22 := 16#0000_1000#;
      GTE.RT33 := 16#0000_1000#;

      GTE.TRX := 0;
      GTE.TRY := 0;
      GTE.TRZ := 0;

      GTE.OFX := 0;
      GTE.OFY := 0;

      GTE.H   := 1000;
      GTE.DQA := 0;
      GTE.DQB := 0;
   end Setup_Identity;

   Inst : PSX.GTE.Instruction.Instruction;

begin
   Put_Line ("Testing PSX GTE RTPT...");
   New_Line;

   Setup_Identity;

   ------------------------------------------------------------------
   -- Tres vértices
   ------------------------------------------------------------------

   GTE.V0_X := 100;
   GTE.V0_Y := 200;
   GTE.V0_Z := 1000;

   GTE.V1_X := 300;
   GTE.V1_Y := 400;
   GTE.V1_Z := 2000;

   GTE.V2_X := 500;
   GTE.V2_Y := 600;
   GTE.V2_Z := 3000;

   -- RTPT = command 30
   -- SF = 1
   -- LM = 0
   Inst.Raw := 16#0008_0030#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   ------------------------------------------------------------------
   -- IR: el último vértice debe quedar en IR1-IR3
   ------------------------------------------------------------------

   Check ("IR1 final", 500, GTE.IR1);
   Check ("IR2 final", 600, GTE.IR2);
   Check ("IR3 final", 3000, GTE.IR3);

   ------------------------------------------------------------------
   -- MAC: corresponde al último vértice
   ------------------------------------------------------------------

   Check ("MAC1 final", 500, GTE.MAC1);
   Check ("MAC2 final", 600, GTE.MAC2);
   Check ("MAC3 final", 3000, GTE.MAC3);

   ------------------------------------------------------------------
   -- SZ FIFO
   --
   -- Antes: SZ0=0 SZ1=0 SZ2=0 SZ3=0
   -- V0 -> SZ3=1000
   -- V1 -> SZ3=2000
   -- V2 -> SZ3=3000
   ------------------------------------------------------------------

   Check ("SZ0 FIFO", 1000, GTE.SZ0);
   Check ("SZ1 FIFO", 2000, GTE.SZ1);
   Check ("SZ2 FIFO", 3000, GTE.SZ2);
   Check ("SZ3 FIFO", 3000, GTE.SZ3);

   ------------------------------------------------------------------
   -- SXY FIFO
   ------------------------------------------------------------------

   Check ("SX0 FIFO", 100, GTE.SX0);
   Check ("SY0 FIFO", 200, GTE.SY0);

   Check ("SX1 FIFO", 300, GTE.SX1);
   Check ("SY1 FIFO", 400, GTE.SY1);

   Check ("SX2 FIFO", 500, GTE.SX2);
   Check ("SY2 FIFO", 600, GTE.SY2);

   ------------------------------------------------------------------
   -- IR0
   ------------------------------------------------------------------

   Check ("IR0", 0, GTE.IR0);

   ------------------------------------------------------------------
   -- FLAG
   ------------------------------------------------------------------

   Check ("FLAG", 0, GTE.FLAG);

   New_Line;
   Put_Line ("PSX GTE RTPT tests finished.");

end PSX_GTE_RTPT_Tests;