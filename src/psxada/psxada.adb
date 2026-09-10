with Ada.Text_IO;
with PSX.CPU.Execute;
with PSX.CPU.Instruction;
with PSX.Register;
with PSX.State;

procedure Psxada is

   System : PSX.State.PSX_State;
   Inst   : PSX.CPU.Instruction.Instruction;

begin
   PSX.State.Reset (System);

   --  R2 = 16#8000_0000#
   PSX.Register.Write (System.CPU.Registers, 2, 16#8000_0000#);

   --  SRA R1, R2, 1
   Inst.Raw := 16#0002_0843#;

   Ada.Text_IO.Put_Line
     ("Opcode = " & PSX.CPU.Instruction.Opcode (Inst)'Image);

   Ada.Text_IO.Put_Line ("Rt = " & PSX.CPU.Instruction.Rt (Inst)'Image);

   Ada.Text_IO.Put_Line ("Rd = " & PSX.CPU.Instruction.Rd (Inst)'Image);

   Ada.Text_IO.Put_Line ("Shamt = " & PSX.CPU.Instruction.Shamt (Inst)'Image);

   Ada.Text_IO.Put_Line ("Funct = " & PSX.CPU.Instruction.Funct (Inst)'Image);

   --  Ejecutar instrucción
   PSX.CPU.Execute.Execute (System.CPU, System.Memory, Inst);

   --  Leer resultado después de ejecutar
   Ada.Text_IO.Put_Line
     ("SRA R1 = " & PSX.Register.Read (System.CPU.Registers, 1)'Image);

end Psxada;
