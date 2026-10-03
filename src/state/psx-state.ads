with PSX.CPU;
with PSX.Memory;

package PSX.State is

   type PSX_State is record
      CPU    : PSX.CPU.CPU_State;
      Memory : PSX.Memory.Memory_State;
   end record;

   procedure Reset
     (System : out PSX_State); -- Cambiado a 'out' para inicializar limpio

end PSX.State;
