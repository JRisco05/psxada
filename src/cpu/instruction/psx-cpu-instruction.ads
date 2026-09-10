with PSX.Types;

package PSX.CPU.Instruction is

   subtype Word32 is PSX.Types.Word32;

   type Instruction is record
      Raw : Word32;
   end record;

   function Opcode (Inst : Instruction) return Word32;

   function Rs (Inst : Instruction) return Word32;

   function Rt (Inst : Instruction) return Word32;

   function Rd (Inst : Instruction) return Word32;

   function Shamt (Inst : Instruction) return Word32;

   function Funct (Inst : Instruction) return Word32;

   function Immediate (Inst : Instruction) return Word32;

   function Target (Inst : Instruction) return Word32;

end PSX.CPU.Instruction;