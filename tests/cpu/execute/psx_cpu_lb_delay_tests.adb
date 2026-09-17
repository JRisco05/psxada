with Ada.Text_IO;
with Interfaces;
with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with PSX.Register;

procedure PSX_CPU_LB_Delay_Tests is

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

   --  R1 = 0x100
   PSX.Register.Write (CPU.Registers, 1, 16#0000_0100#);

   --  Memoria[0x100] = 0x00000080
   --  LB debe producir 0xFFFFFF80.
   PSX.Memory.Write_8 (Memory, 16#0000_0100#, 16#80#);

   --  LB R2, 0(R1)
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#8022_0000#);

   --  NOP
   PSX.Memory.Write_32 (Memory, 16#0001_0004#, 16#0000_0000#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   Check ("LB delay before", PSX.Register.Read (CPU.Registers, 2), 0);

   --  Ejecutar LB.
   PSX.CPU.Step.Step (CPU, Memory);

   Check ("LB delay after LB", PSX.Register.Read (CPU.Registers, 2), 0);

   --  Ejecutar NOP.
   PSX.CPU.Step.Step (CPU, Memory);

   --  LB debe quedar disponible después de la siguiente instrucción.
   Check
     ("LB delay after next instruction",
      PSX.Register.Read (CPU.Registers, 2),
      16#FFFF_FF80#);

   Ada.Text_IO.Put_Line ("");
   Ada.Text_IO.Put_Line ("PSX CPU LB delay tests finished.");

end PSX_CPU_LB_Delay_Tests;
