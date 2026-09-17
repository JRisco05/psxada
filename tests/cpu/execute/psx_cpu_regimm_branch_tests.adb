with Ada.Text_IO; use Ada.Text_IO;
with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with PSX.Types;
with Interfaces;

procedure PSX_CPU_Regimm_Branch_Tests is

   use type Interfaces.Unsigned_32;

   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

   procedure Check
     (Name : String; Expected : PSX.Types.Word32; Actual : PSX.Types.Word32) is
   begin
      if Actual = Expected then
         Put_Line ("PASS: " & Name);
      else
         Put_Line ("FAIL: " & Name);
      end if;
   end Check;

begin

   Put_Line ("Testing PSX CPU REGIMM branches...");
   New_Line;

   ------------------------------------------------------------------
   --  BLTZ tomado (Branch Less Than Zero)
   ------------------------------------------------------------------
   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   --  R1 = -1 (Es menor que cero, por lo tanto SÍ salta)
   CPU.Registers (1) := 16#FFFF_FFFF#;

   --  Escribimos BLTZ R1, +2
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#0420_0002#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   --  Como SÍ saltó, el Next_PC final debe ser 0x0001_000C
   Check ("BLTZ taken", 16#0001_000C#, CPU.Next_PC);

   ------------------------------------------------------------------
   --  BLTZ no tomado
   ------------------------------------------------------------------
   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   --  R1 = 1 (Es mayor que cero, por lo tanto NO salta)
   CPU.Registers (1) := 1;

   --  Escribimos BLTZ R1, +2
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#0420_0002#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   --  Como NO saltó, sigue en línea recta
   --  y el Next_PC final debe ser 0x0001_0008
   Check ("BLTZ not taken", 16#0001_0008#, CPU.Next_PC);

   ------------------------------------------------------------------
   --  BGEZ tomado (Branch Greater Than or Equal to Zero)
   ------------------------------------------------------------------
   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   --  R1 = 1 (Es mayor o igual a cero, por lo tanto SÍ salta)
   CPU.Registers (1) := 1;

   --  Escribimos BGEZ R1, +2
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#0421_0002#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   --  Como SÍ saltó, el Next_PC final debe ser 0x0001_000C
   Check ("BGEZ taken", 16#0001_000C#, CPU.Next_PC);

   ------------------------------------------------------------------
   --  BGEZ no tomado
   ------------------------------------------------------------------
   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   --  R1 = -1 (Es menor que cero, por lo tanto NO salta)
   CPU.Registers (1) := 16#FFFF_FFFF#;

   --  Escribimos BGEZ R1, +2
   PSX.Memory.Write_32 (Memory, 16#0001_0000#, 16#0421_0002#);

   CPU.PC := 16#0001_0000#;
   CPU.Next_PC := 16#0001_0004#;

   PSX.CPU.Step.Step (CPU, Memory);

   --  Como NO saltó, sigue en línea recta
   --  y el Next_PC final debe ser 0x0001_0008
   Check ("BGEZ not taken", 16#0001_0008#, CPU.Next_PC);

   Put_Line ("");
   Put_Line ("PSX CPU REGIMM branch tests finished.");

end PSX_CPU_Regimm_Branch_Tests;
