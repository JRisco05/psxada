with PSX.Memory;

package body PSX.CPU.Fetch is

   function Fetch
     (CPU : PSX.CPU.CPU_State; Memory : PSX.Memory.Memory_State)
      return PSX.CPU.Instruction.Instruction
   is
      Inst : PSX.CPU.Instruction.Instruction;
   begin

      Inst.Raw := PSX.Memory.Read_32 (Memory, CPU.PC);

      return Inst;

   end Fetch;

end PSX.CPU.Fetch;
