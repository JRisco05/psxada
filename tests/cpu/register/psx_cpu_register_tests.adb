with Ada.Text_IO;
with Interfaces;

with PSX.CPU;
with PSX.CPU.Execute;
with PSX.CPU.Instruction;
with PSX.Memory;
with PSX.Register;

procedure Psx_Cpu_Execute_Tests is

   use type Interfaces.Unsigned_32;

   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;
   Inst   : PSX.CPU.Instruction.Instruction;

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Ada.Text_IO.Put_Line ("FAIL: " & Message);
         raise Program_Error;
      end if;
   end Assert;

begin

   Ada.Text_IO.Put_Line ("Testing PSX.CPU.Execute...");
   Ada.Text_IO.New_Line;

   PSX.Memory.Reset (Memory);

   --------------------------------------------------
   --  SLL
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 2, 1);

   --  SLL R1, R2, 4
   Inst.Raw := 16#0002_0900#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 1) = 16, "SLL R1,R2,4");

   Ada.Text_IO.Put_Line ("PASS: SLL");

   --------------------------------------------------
   --  SRL
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 2, 16);

   --  SRL R1, R2, 2
   Inst.Raw := 16#0002_0882#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 1) = 4, "SRL R1,R2,2");

   Ada.Text_IO.Put_Line ("PASS: SRL");

   --------------------------------------------------
   --  SRA
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 2, 16#8000_0000#);

   --  SRA R1, R2, 1
   Inst.Raw := 16#0002_0843#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 16#C000_0000#, "SRA R1,R2,1");

   Ada.Text_IO.Put_Line ("PASS: SRA");

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("All execution tests passed.");

end Psx_Cpu_Execute_Tests;
