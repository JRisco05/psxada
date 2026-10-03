package body PSX.State is

   -------------
   --  RESET  --
   -------------
   procedure Reset (System : out PSX_State) is
   begin
      -- 1. Reseteamos el CPU
      PSX.CPU.Reset (System.CPU);
      
      -- 2. Reseteamos la Memoria (Timers incluidos internamente)
      PSX.Memory.Reset (System.Memory);
      
      -- 3. 🌟 NUEVO: Inicializamos la GPU que ahora reside dentro del bus de memoria
      PSX.GPU.Reset (System.Memory.GPU);
   end Reset;

 Downs PSX.State;
