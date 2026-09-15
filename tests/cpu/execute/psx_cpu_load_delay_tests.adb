with Ada.Text_IO;
with Interfaces;
with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with PSX.Register;

procedure PSX_CPU_Load_Delay_Tests is

   use type Interfaces.Unsigned_32;

   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

   procedure Check
     (Name     : String;
      Actual   : Interfaces.Unsigned_32;
      Expected : Interfaces.Unsigned_32) is
   begin
      if Actual = Expected then
         Ada.Text_IO.Put_Line ("PASS: " & Name);
      else
         Ada.Text_IO.Put_Line
           ("FAIL: "
            & Name
            & " expected="
            & Interfaces.Unsigned_32'Image (Expected)
            & " actual="
            & Interfaces.Unsigned_32'Image (Actual));
      end if;
   end Check;

begin

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   -- R1 = 0x00000100
   PSX.Register.Write (CPU.Registers, 1, 16#0000_0100#);

   -- Memoria[0x100] = 0x12345678
   PSX.Memory.Write_32 (Memory, 16#0000_0100#, 16#1234_5678#);

   -- LW R2, 0(R1)
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#8C22_0000#);

   -- NOP
   PSX.Memory.Write_32 (Memory, 16#0001_0004#, 16#0000_0000#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   Check ("LW delay before", PSX.Register.Read (CPU.Registers, 2), 0);

   -- Ejecutar LW
   PSX.CPU.Step.Step (CPU, Memory);

   Check ("LW delay after LW", PSX.Register.Read (CPU.Registers, 2), 0);

   Ada.Text_IO.Put_Line ("Load_Pending = " & Boolean'Image (CPU.Load_Pending));

   Ada.Text_IO.Put_Line
     ("Load_Register = "
      & PSX.Register.Register_Index'Image (CPU.Load_Register));

   Ada.Text_IO.Put_Line
     ("Load_Value = " & Interfaces.Unsigned_32'Image (CPU.Load_Value));

   -- Ejecutar NOP
   PSX.CPU.Step.Step (CPU, Memory);

   -- Ahora el resultado del LW debe estar en R2.
   Check
     ("LW delay after next instruction",
      PSX.Register.Read (CPU.Registers, 2),
      16#1234_5678#);

   Ada.Text_IO.Put_Line ("");
   Ada.Text_IO.Put_Line ("PSX CPU load delay tests finished.");

end PSX_CPU_Load_Delay_Tests;
