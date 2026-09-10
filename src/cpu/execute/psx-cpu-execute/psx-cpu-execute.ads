with PSX.CPU;
with PSX.CPU.Instruction;
with PSX.Memory;

package PSX.CPU.Execute is

   procedure Execute
     (CPU    : in out PSX.CPU.CPU_State;
      Memory : in out PSX.Memory.Memory_State;
      Inst   : PSX.CPU.Instruction.Instruction);

end PSX.CPU.Execute;
