with PSX.CPU;
with PSX.CPU.Instruction;
with PSX.Memory;

package PSX.CPU.Fetch is

   function Fetch
     (CPU : PSX.CPU.CPU_State; Memory : PSX.Memory.Memory_State)
      return PSX.CPU.Instruction.Instruction;

end PSX.CPU.Fetch;
