with Ada.Text_IO;
with Interfaces;
with PSX.GTE;
with PSX.GTE.Execute;
with PSX.GTE.Instruction;

procedure PSX_GTE_MVMVA_Tests is

   use Ada.Text_IO;
   use Interfaces;

   GTE  : PSX.GTE.GTE_State;
   Inst : PSX.GTE.Instruction.Instruction;

   procedure Check
     (Name : String; Expected : Unsigned_32; Actual : Unsigned_32) is
   begin
      if Expected = Actual then
         Put_Line ("PASS: " & Name);
      else
         Put_Line
           ("FAIL: "
            & Name
            & " expected=0x"
            & Unsigned_32'Image (Expected)
            & " actual=0x"
            & Unsigned_32'Image (Actual));
      end if;
   end Check;

begin
   New_Line;
   Put_Line ("=========================================================");
   Put_Line ("Testing PSX GTE MVMVA...");
   Put_Line ("=========================================================");
   New_Line;

   PSX.GTE.Reset (GTE);

   --  Vector V0 = (100, 200, 300)
   PSX.GTE.Write_Data (GTE, 0, 16#00C8_0064#);
   PSX.GTE.Write_Data (GTE, 1, 16#0000_012C#);

   --  Identity rotation matrix.
   PSX.GTE.Write_Control (GTE, 32, 16#0000_1000#); -- RT11=4096, RT12=0
   PSX.GTE.Write_Control (GTE, 33, 16#0000_0000#); -- RT13=0, RT21=0
   PSX.GTE.Write_Control (GTE, 34, 16#0000_1000#); -- RT22=4096, RT23=0
   PSX.GTE.Write_Control (GTE, 35, 16#0000_0000#); -- RT31=0, RT32=0
   PSX.GTE.Write_Control (GTE, 36, 16#0000_1000#); -- RT33=4096

   --  No translation.
   PSX.GTE.Write_Control (GTE, 37, 0); -- TRX
   PSX.GTE.Write_Control (GTE, 38, 0); -- TRY
   PSX.GTE.Write_Control (GTE, 39, 0); -- TRZ

   Inst.Raw := 16#0008_000C#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   Check ("IR1", 100, GTE.IR1);
   Check ("IR2", 200, GTE.IR2);
   Check ("IR3", 300, GTE.IR3);

   Check ("MAC1", 100, GTE.MAC1);
   Check ("MAC2", 200, GTE.MAC2);
   Check ("MAC3", 300, GTE.MAC3);

   Check ("FLAG", 0, GTE.FLAG);

   New_Line;

   --  V0 = (100, 200, 300)
   PSX.GTE.Write_Data (GTE, 0, 16#00C8_0064#);
   PSX.GTE.Write_Data (GTE, 1, 300);

   --  V1 = (400, 500, 600)
   PSX.GTE.Write_Data (GTE, 2, 16#01F4_0190#);
   PSX.GTE.Write_Data (GTE, 3, 600);

   --  RT = identidad en formato Q12.
   PSX.GTE.Write_Control (GTE, 32, 16#0000_1000#);
   PSX.GTE.Write_Control (GTE, 33, 0);
   PSX.GTE.Write_Control (GTE, 34, 16#0000_1000#);
   PSX.GTE.Write_Control (GTE, 35, 0);
   PSX.GTE.Write_Control (GTE, 36, 4096);

   --  TR = 0
   PSX.GTE.Write_Control (GTE, 37, 0);
   PSX.GTE.Write_Control (GTE, 38, 0);
   PSX.GTE.Write_Control (GTE, 39, 0);

   Inst.Raw := 16#0008_800C#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   Check ("IR1 V=1", 400, PSX.GTE.Read_Data (GTE, 9));

   Check ("IR2 V=1", 500, PSX.GTE.Read_Data (GTE, 10));

   Check ("IR3 V=1", 600, PSX.GTE.Read_Data (GTE, 11));

   Check ("MAC1 V=1", 400, PSX.GTE.Read_Data (GTE, 25));

   Check ("MAC2 V=1", 500, PSX.GTE.Read_Data (GTE, 26));

   Check ("MAC3 V=1", 600, PSX.GTE.Read_Data (GTE, 27));

   Check ("FLAG V=1", 0, PSX.GTE.Read_Control (GTE, 63));

   New_Line;

   --  V0 = (100, 200, 300)
   GTE.V0_X := 100;
   GTE.V0_Y := 200;
   GTE.V0_Z := 300;

   --  V1 = (400, 500, 600)
   GTE.V1_X := 400;
   GTE.V1_Y := 500;
   GTE.V1_Z := 600;

   --  V2 = (700, 800, 900)
   GTE.V2_X := 700;
   GTE.V2_Y := 800;
   GTE.V2_Z := 900;

   --  Matriz identidad (4096 = 1.0 en formato 12.4)
   GTE.RT11 := 4096;
   GTE.RT12 := 0;
   GTE.RT13 := 0;

   GTE.RT21 := 0;
   GTE.RT22 := 4096;
   GTE.RT23 := 0;

   GTE.RT31 := 0;
   GTE.RT32 := 0;
   GTE.RT33 := 4096;

   --  Sin traslación
   GTE.TRX := 0;
   GTE.TRY := 0;
   GTE.TRZ := 0;

   --  SF=1, V=2, LM=0, MX=0, CV=0, CMD=12
   Inst.Raw := 16#0009_000C#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   Check ("IR1 V=2", 700, GTE.IR1);
   Check ("IR2 V=2", 800, GTE.IR2);
   Check ("IR3 V=2", 900, GTE.IR3);

   Check ("MAC1 V=2", 700, GTE.MAC1);
   Check ("MAC2 V=2", 800, GTE.MAC2);
   Check ("MAC3 V=2", 900, GTE.MAC3);

   Check ("FLAG V=2", 0, GTE.FLAG);

   New_Line;

   --  V0 = (100, 200, 300)
   PSX.GTE.Write_Data (GTE, 0, 16#00C8_0064#);
   PSX.GTE.Write_Data (GTE, 1, 300);

   --  RT = identidad en formato Q12.
   --  Los registros de la matriz están empaquetados.

   PSX.GTE.Write_Control (GTE, 32, 16#0000_1000#); -- RT11=4096, RT12=0
   PSX.GTE.Write_Control (GTE, 33, 0);              -- RT13=0, RT21=0
   PSX.GTE.Write_Control (GTE, 34, 16#0000_1000#); -- RT22=4096, RT23=0
   PSX.GTE.Write_Control (GTE, 35, 0);              -- RT31=0, RT32=0
   PSX.GTE.Write_Control (GTE, 36, 4096);           -- RT33=4096

   --  TR = 0
   PSX.GTE.Write_Control (GTE, 37, 0);
   PSX.GTE.Write_Control (GTE, 38, 0);
   PSX.GTE.Write_Control (GTE, 39, 0);

   --  MVMVA:
   --  command = 12
   --  SF = 0
   --  MX = 0 (RT)
   --  V = 0 (V0)
   --  CV = 0 (TR)
   Inst.Raw := 16#0000_000C#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   Check ("MAC1 SF=0", 409600, PSX.GTE.Read_Data (GTE, 25));

   Check ("MAC2 SF=0", 819200, PSX.GTE.Read_Data (GTE, 26));

   Check ("MAC3 SF=0", 1228800, PSX.GTE.Read_Data (GTE, 27));

   Check ("IR1 SF=0", 32767, PSX.GTE.Read_Data (GTE, 9));

   Check ("IR2 SF=0", 32767, PSX.GTE.Read_Data (GTE, 10));

   Check ("IR3 SF=0", 32767, PSX.GTE.Read_Data (GTE, 11));

   New_Line;

   -- V0 = (100, 200, 300)
   GTE.V0_X := 100;
   GTE.V0_Y := 200;
   GTE.V0_Z := 300;

   -- RT = identity
   GTE.RT11 := 4096;
   GTE.RT22 := 4096;
   GTE.RT33 := 4096;

   -- Light matrix = 2 * identity
   -- 8192 = 2.0 in 12.4 fixed-point
   GTE.L11 := 8192;
   GTE.L22 := 8192;
   GTE.L33 := 8192;

   -- Translation = 0
   GTE.TRX := 0;
   GTE.TRY := 0;
   GTE.TRZ := 0;

   -- SF=1
   -- MX=1
   -- V=0
   -- CV=0
   -- LM=0
   -- Command=MVMVA (12)
   Inst.Raw := 16#000A_000C#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   -- MX=1 must use the Light Matrix.
   -- (100,200,300) * 2 = (200,400,600)
   Check ("IR1 MX=1", GTE.IR1, 200);
   Check ("IR2 MX=1", GTE.IR2, 400);
   Check ("IR3 MX=1", GTE.IR3, 600);

   Check ("MAC1 MX=1", GTE.MAC1, 200);
   Check ("MAC2 MX=1", GTE.MAC2, 400);
   Check ("MAC3 MX=1", GTE.MAC3, 600);

   Check ("FLAG MX=1", GTE.FLAG, 0);

   New_Line;

   -- V0 = (100, 200, 300)
   GTE.V0_X := 100;
   GTE.V0_Y := 200;
   GTE.V0_Z := 300;

   -- RT = identity
   GTE.RT11 := 4096;
   GTE.RT22 := 4096;
   GTE.RT33 := 4096;

   -- Light matrix = identity
   GTE.L11 := 4096;
   GTE.L22 := 4096;
   GTE.L33 := 4096;

   -- Color matrix = 2 * identity
   GTE.LR1 := 8192;
   GTE.LG2 := 8192;
   GTE.LB3 := 8192;

   -- Translation = 0
   GTE.TRX := 0;
   GTE.TRY := 0;
   GTE.TRZ := 0;

   -- SF=1
   -- MX=2
   -- V=0
   -- CV=0
   -- LM=0
   -- Command=MVMVA (12)
   Inst.Raw := 16#000C_000C#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   -- MX=2 must use the Color Matrix.
   -- (100,200,300) * 2 = (200,400,600)
   Check ("IR1 MX=2", GTE.IR1, 200);
   Check ("IR2 MX=2", GTE.IR2, 400);
   Check ("IR3 MX=2", GTE.IR3, 600);

   Check ("MAC1 MX=2", GTE.MAC1, 200);
   Check ("MAC2 MX=2", GTE.MAC2, 400);
   Check ("MAC3 MX=2", GTE.MAC3, 600);

   Check ("FLAG MX=2", GTE.FLAG, 0);

   New_Line;

   -- V0 = maximum positive signed 16-bit values
   GTE.V0_X := 32767;
   GTE.V0_Y := 32767;
   GTE.V0_Z := 32767;

   GTE.TRX := 16#7FFF_FFFF#;
   GTE.TRY := 16#7FFF_FFFF#;
   GTE.TRZ := 16#7FFF_FFFF#;

   -- Rotation matrix = large positive values.
   -- 32767 * 32767 * 3 produces a MAC value
   -- far beyond the signed 44-bit GTE MAC range.
   GTE.RT11 := 32767;
   GTE.RT12 := 32767;
   GTE.RT13 := 32767;

   GTE.RT21 := 32767;
   GTE.RT22 := 32767;
   GTE.RT23 := 32767;

   GTE.RT31 := 32767;
   GTE.RT32 := 32767;
   GTE.RT33 := 32767;

   -- CV=3: no translation
   -- MX=0: rotation matrix
   -- V=0: V0
   -- SF=0: keep full MAC result
   -- LM=0
   -- Command=MVMVA (12)
   Inst.Raw := 16#0000_000C#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   -- MAC overflow flags:
   -- MAC1 -> bit 30
   -- MAC2 -> bit 29
   -- MAC3 -> bit 28
   Check
     ("MAC1 overflow FLAG bit 30", GTE.FLAG and 16#4000_0000#, 16#4000_0000#);

   Check
     ("MAC2 overflow FLAG bit 29", GTE.FLAG and 16#2000_0000#, 16#2000_0000#);

   Check
     ("MAC3 overflow FLAG bit 28", GTE.FLAG and 16#1000_0000#, 16#1000_0000#);

   New_Line;

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

   New_Line;
   Put_Line ("PSX GTE MVMVA tests finished.");

end PSX_GTE_MVMVA_Tests;
