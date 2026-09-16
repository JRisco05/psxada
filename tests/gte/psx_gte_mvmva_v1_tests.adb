with Ada.Text_IO; use Ada.Text_IO;
with Interfaces;
with PSX.GTE;
with PSX.GTE.Execute;
with PSX.GTE.Instruction;

procedure PSX_GTE_MVMVA_V1_Tests is

   use type Interfaces.Unsigned_32;

   GTE  : PSX.GTE.GTE_State;
   Inst : PSX.GTE.Instruction.Instruction;

   procedure Check
     (Name     : String;
      Expected : Interfaces.Unsigned_32;
      Actual   : Interfaces.Unsigned_32)
   is
   begin
      if Actual = Expected then
         Put_Line ("PASS: " & Name);
      else
         Put_Line
           ("FAIL: " & Name &
            " expected=0x" & Interfaces.Unsigned_32'Image (Expected) &
            " actual=0x" & Interfaces.Unsigned_32'Image (Actual));
      end if;
   end Check;

begin
   Put_Line ("Testing PSX GTE MVMVA V=1...");

   PSX.GTE.Reset (GTE);

   -- V0 = (100, 200, 300)
   PSX.GTE.Write_Data (GTE, 0, 16#00C8_0064#);
   PSX.GTE.Write_Data (GTE, 1, 300);

   -- V1 = (400, 500, 600)
   PSX.GTE.Write_Data (GTE, 2, 16#01F4_0190#);
   PSX.GTE.Write_Data (GTE, 3, 600);

   -- RT = identidad en formato Q12.
   PSX.GTE.Write_Control (GTE, 32, 16#0000_1000#);
   PSX.GTE.Write_Control (GTE, 33, 0);
   PSX.GTE.Write_Control (GTE, 34, 16#0000_1000#);
   PSX.GTE.Write_Control (GTE, 35, 0);
   PSX.GTE.Write_Control (GTE, 36, 4096);

   -- TR = 0
   PSX.GTE.Write_Control (GTE, 37, 0);
   PSX.GTE.Write_Control (GTE, 38, 0);
   PSX.GTE.Write_Control (GTE, 39, 0);

   -- MVMVA
   -- command = 12
   -- SF = 1
   -- LM = 0
   -- MX = 0 (RT)
   -- V  = 1 (V1)
   -- CV = 0 (TR)
    Inst.Raw := 16#0008_800C#;

    PSX.GTE.Execute.Execute (GTE, Inst);

   Check
     ("IR1 V=1",
      400,
      PSX.GTE.Read_Data (GTE, 9));

   Check
     ("IR2 V=1",
      500,
      PSX.GTE.Read_Data (GTE, 10));

   Check
     ("IR3 V=1",
      600,
      PSX.GTE.Read_Data (GTE, 11));

   Check
     ("MAC1 V=1",
      400,
      PSX.GTE.Read_Data (GTE, 25));

   Check
     ("MAC2 V=1",
      500,
      PSX.GTE.Read_Data (GTE, 26));

   Check
     ("MAC3 V=1",
      600,
      PSX.GTE.Read_Data (GTE, 27));

   Check
     ("FLAG V=1",
      0,
      PSX.GTE.Read_Control (GTE, 63));


   Put_Line ("PSX GTE MVMVA V=1 tests finished.");
end PSX_GTE_MVMVA_V1_Tests;