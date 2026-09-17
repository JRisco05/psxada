with PSX.Types;

package PSX.GTE.Instruction is

   subtype Word32 is PSX.Types.Word32;

   type Instruction is record
      Raw : Word32;
   end record;

   function Command (Inst : Instruction) return Word32;

   function Sf (Inst : Instruction) return Word32;

   function Mx (Inst : Instruction) return Word32;

   function V (Inst : Instruction) return Word32;

   function Cv (Inst : Instruction) return Word32;

   function Lm (Inst : Instruction) return Word32;

end PSX.GTE.Instruction;
