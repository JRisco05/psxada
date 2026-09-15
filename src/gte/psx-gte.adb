package body PSX.GTE is

   procedure Reset (GTE : out GTE_State) is
   begin
      GTE.V0_X := 0;
      GTE.V0_Y := 0;
      GTE.V0_Z := 0;

      GTE.V1_X := 0;
      GTE.V1_Y := 0;
      GTE.V1_Z := 0;

      GTE.V2_X := 0;
      GTE.V2_Y := 0;
      GTE.V2_Z := 0;

      GTE.MAC0 := 0;
      GTE.MAC1 := 0;
      GTE.MAC2 := 0;
      GTE.MAC3 := 0;

      GTE.RGB0 := 0;
      GTE.RGB1 := 0;
      GTE.RGB2 := 0;

      GTE.IR0 := 0;
      GTE.IR1 := 0;
      GTE.IR2 := 0;
      GTE.IR3 := 0;

      GTE.SX0 := 0;
      GTE.SY0 := 0;
      GTE.SX1 := 0;
      GTE.SY1 := 0;
      GTE.SX2 := 0;
      GTE.SY2 := 0;

      GTE.SZ0 := 0;
      GTE.SZ1 := 0;
      GTE.SZ2 := 0;
      GTE.SZ3 := 0;

      GTE.RT11 := 0;
      GTE.RT12 := 0;
      GTE.RT13 := 0;

      GTE.TRX := 0;
      GTE.TRY := 0;
      GTE.TRZ := 0;

      GTE.OFX := 0;
      GTE.OFY := 0;

      GTE.H := 0;

      GTE.DQA := 0;
      GTE.DQB := 0;

      GTE.ZSF3 := 0;
      GTE.ZSF4 := 0;

      GTE.FLAG := 0;
   end Reset;

end PSX.GTE;