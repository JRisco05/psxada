with Ada.Text_IO; use Ada.Text_IO;
with Interfaces;
with PSX.GTE;
with PSX.GTE.Execute;
with PSX.GTE.Instruction;

procedure PSX_GTE_MVMVA_LM_Tests is

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
   Put_Line ("Testing PSX GTE MVMVA LM=1...");

   PSX.GTE.Reset (GTE);

   -- V0 = (32767, 32767, 32767)
   PSX.GTE.Write_Data (GTE, 0, 16#7FFF_7FFF#);
   PSX.GTE.Write_Data (GTE, 1, 16#0000_7FFF#);

   -- RT = diagonal 8192.
   -- 8192 = 2 * 4096.
   PSX.GTE.Write_Control (GTE, 32, 16#0000_2000#);
   PSX.GTE.Write_Control (GTE, 33, 0);
   PSX.GTE.Write_Control (GTE, 34, 16#0000_2000#);
   PSX.GTE.Write_Control (GTE, 35, 0);
   PSX.GTE.Write_Control (GTE, 36, 8192);

   -- TR = 0
   PSX.GTE.Write_Control (GTE, 37, 0);
   PSX.GTE.Write_Control (GTE, 38, 0);
   PSX.GTE.Write_Control (GTE, 39, 0);

   -- MVMVA
   -- command = 12
   -- SF = 1
   -- LM = 1
   -- MX = 0 (RT)
   -- V  = 0 (V0)
   -- CV = 0 (TR)
   Inst.Raw := 16#0000_040C#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   Check
     ("IR1 LM=1",
      32767,
      PSX.GTE.Read_Data (GTE, 9));

   Check
     ("IR2 LM=1",
      32767,
      PSX.GTE.Read_Data (GTE, 10));

   Check
     ("IR3 LM=1",
      32767,
      PSX.GTE.Read_Data (GTE, 11));

   -- Saturation flags: IR1=24, IR2=23, IR3=22.
   Check
     ("FLAG IR1 saturation",
      16#0100_0000#,
      PSX.GTE.Read_Control (GTE, 63) and 16#0100_0000#);

   Check
     ("FLAG IR2 saturation",
      16#0080_0000#,
      PSX.GTE.Read_Control (GTE, 63) and 16#0080_0000#);

   Check
     ("FLAG IR3 saturation",
      16#0040_0000#,
      PSX.GTE.Read_Control (GTE, 63) and 16#0040_0000#);

   Put_Line ("PSX GTE MVMVA LM=1 tests finished.");
end PSX_GTE_MVMVA_LM_Tests;