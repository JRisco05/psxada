with Interfaces;

package body PSX.CPU.Instruction is

   use type Interfaces.Unsigned_32;

   function Opcode (Inst : Instruction) return Word32 is
   begin
      return Interfaces.Shift_Right (Inst.Raw, 26);
   end Opcode;

   function Rs (Inst : Instruction) return Word32 is
   begin
      return Interfaces.Shift_Right (Inst.Raw, 21) and 16#1F#;
   end Rs;

   function Rt (Inst : Instruction) return Word32 is
   begin
      return Interfaces.Shift_Right (Inst.Raw, 16) and 16#1F#;
   end Rt;

   function Rd (Inst : Instruction) return Word32 is
   begin
      return Interfaces.Shift_Right (Inst.Raw, 11) and 16#1F#;
   end Rd;

   function Shamt (Inst : Instruction) return Word32 is
   begin
      return Interfaces.Shift_Right (Inst.Raw, 6) and 16#1F#;
   end Shamt;

   function Funct (Inst : Instruction) return Word32 is
   begin
      return Inst.Raw and 16#3F#;
   end Funct;

   function Immediate (Inst : Instruction) return Word32 is
   begin
      return Inst.Raw and 16#FFFF#;
   end Immediate;

   function Target (Inst : Instruction) return Word32 is
   begin
      return Inst.Raw and 16#03FF_FFFF#;
   end Target;

end PSX.CPU.Instruction;