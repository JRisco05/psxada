with Interfaces;
with PSX.GTE;
with PSX.GTE.Execute;
with PSX.GTE.Instruction;
with Ada.Text_IO; use Ada.Text_IO;

procedure PSX_GTE_MVMVA_SF0_Tests is

   use type Interfaces.Unsigned_32;

   GTE : PSX.GTE.GTE_State;
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
   Put_Line ("Testing PSX GTE MVMVA SF=0...");

   PSX.GTE.Reset (GTE);

   -- V0 = (100, 200, 300)
   PSX.GTE.Write_Data (GTE, 0, 16#00C8_0064#);
   PSX.GTE.Write_Data (GTE, 1, 300);

      -- RT = identidad en formato Q12.
   -- Los registros de la matriz están empaquetados.

   PSX.GTE.Write_Control (GTE, 32, 16#0000_1000#); -- RT11=4096, RT12=0
   PSX.GTE.Write_Control (GTE, 33, 0);              -- RT13=0, RT21=0
   PSX.GTE.Write_Control (GTE, 34, 16#0000_1000#); -- RT22=4096, RT23=0
   PSX.GTE.Write_Control (GTE, 35, 0);              -- RT31=0, RT32=0
   PSX.GTE.Write_Control (GTE, 36, 4096);           -- RT33=4096

   -- TR = 0
PSX.GTE.Write_Control (GTE, 37, 0);
   PSX.GTE.Write_Control (GTE, 38, 0);
   PSX.GTE.Write_Control (GTE, 39, 0);

   -- MVMVA:
   -- command = 12
   -- SF = 0
   -- MX = 0 (RT)
   -- V = 0 (V0)
   -- CV = 0 (TR)
   Inst.Raw := 16#0000_000C#;

   PSX.GTE.Execute.Execute (GTE, Inst);

   Check
     ("MAC1 SF=0",
      409600,
      PSX.GTE.Read_Data (GTE, 24));

   Check
     ("MAC2 SF=0",
      819200,
      PSX.GTE.Read_Data (GTE, 25));

   Check
     ("MAC3 SF=0",
      1228800,
      PSX.GTE.Read_Data (GTE, 26));

   Check
     ("IR1 SF=0",
      32767,
      PSX.GTE.Read_Data (GTE, 9));

   Check
     ("IR2 SF=0",
      32767,
      PSX.GTE.Read_Data (GTE, 10));

   Check
     ("IR3 SF=0",
      32767,
      PSX.GTE.Read_Data (GTE, 11));

   Put_Line ("PSX GTE MVMVA SF=0 tests finished.");
end PSX_GTE_MVMVA_SF0_Tests;