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

   Put_Line ("Testing PSX GTE MVMVA...");
   New_Line;

   PSX.GTE.Reset (GTE);

   -- Vector V0 = (100, 200, 300)
   PSX.GTE.Write_Data (GTE, 0, 16#00C8_0064#);
   PSX.GTE.Write_Data (GTE, 1, 16#0000_012C#);

   -- Identity rotation matrix.
   PSX.GTE.Write_Control (GTE, 32, 16#0000_1000#); -- RT11=4096, RT12=0
   PSX.GTE.Write_Control (GTE, 33, 16#0000_0000#); -- RT13=0, RT21=0
   PSX.GTE.Write_Control (GTE, 34, 16#0000_1000#); -- RT22=4096, RT23=0
   PSX.GTE.Write_Control (GTE, 35, 16#0000_0000#); -- RT31=0, RT32=0
   PSX.GTE.Write_Control (GTE, 36, 16#0000_1000#); -- RT33=4096

   -- No translation.
   PSX.GTE.Write_Control (GTE, 37, 0); -- TRX
   PSX.GTE.Write_Control (GTE, 38, 0); -- TRY
   PSX.GTE.Write_Control (GTE, 39, 0); -- TRZ

   -- MVMVA:
   -- command = 12
   -- SF = 1
   -- MX = 0 (RT)
   -- V  = 0 (V0)
   -- CV = 0 (TR)
   -- LM = 0
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
   Put_Line ("PSX GTE MVMVA tests finished.");

end PSX_GTE_MVMVA_Tests;
