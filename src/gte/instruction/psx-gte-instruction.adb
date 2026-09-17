package body PSX.GTE.Instruction is


   function Command (Inst : Instruction) return Word32 is
   begin
      return Inst.Raw and 16#0000_003F#;
   end Command;

   function Sf (Inst : Instruction) return Word32 is
   begin
      return Interfaces.Shift_Right (Inst.Raw, 19) and 1;
   end Sf;

   function Mx (Inst : Instruction) return Word32 is
   begin
      return Interfaces.Shift_Right (Inst.Raw, 17) and 3;
   end Mx;

   function V (Inst : Instruction) return Word32 is
   begin
      return Interfaces.Shift_Right (Inst.Raw, 15) and 3;
   end V;

   function Cv (Inst : Instruction) return Word32 is
   begin
      return Interfaces.Shift_Right (Inst.Raw, 13) and 3;
   end Cv;

   function Lm (Inst : Instruction) return Word32 is
   begin
      return Interfaces.Shift_Right (Inst.Raw, 10) and 1;
   end Lm;

end PSX.GTE.Instruction;
