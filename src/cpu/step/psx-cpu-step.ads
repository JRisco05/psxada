with PSX.CPU;
with PSX.Memory;

package PSX.CPU.Step is

   procedure Step
     (CPU : in out PSX.CPU.CPU_State; Memory : in out PSX.Memory.Memory_State);

end PSX.CPU.Step;
