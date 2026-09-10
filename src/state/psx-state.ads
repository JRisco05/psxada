with PSX.CPU;
with PSX.Memory;

package PSX.State is

   type PSX_State is record
      CPU    : PSX.CPU.CPU_State;
      Memory : PSX.Memory.Memory_State;
   end record;

   procedure Reset (System : in out PSX_State);

end PSX.State;
