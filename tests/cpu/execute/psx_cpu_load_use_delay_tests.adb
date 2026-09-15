with Ada.Text_IO;
with Interfaces;
with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with PSX.Register;

procedure PSX_CPU_Load_Use_Delay_Tests is

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

   -- R1 = 0x100
   PSX.Register.Write (CPU.Registers, 1, 16#0000_0100#);

   -- Memoria[0x100] = 10
   PSX.Memory.Write_32 (Memory, 16#0000_0100#, 10);

   -- LW R2, 0(R1)
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#8C22_0000#);

   -- ADD R3, R2, R0
   PSX.Memory.Write_32 (Memory, 16#0001_0004#, 16#0040_1820#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   -- Ejecutar LW.
   PSX.CPU.Step.Step (CPU, Memory);

   Check ("LW result delayed", PSX.Register.Read (CPU.Registers, 2), 0);

   -- Ejecutar ADD inmediatamente después del LW.
   PSX.CPU.Step.Step (CPU, Memory);

   -- El ADD debe haber visto el valor anterior de R2: 0.
   Check ("Load-use hazard", PSX.Register.Read (CPU.Registers, 3), 0);

   -- El LW sí debe haberse aplicado después.
   Check ("Loaded value available", PSX.Register.Read (CPU.Registers, 2), 10);

   Ada.Text_IO.Put_Line ("");
   Ada.Text_IO.Put_Line ("PSX CPU load-use delay tests finished.");

end PSX_CPU_Load_Use_Delay_Tests;
