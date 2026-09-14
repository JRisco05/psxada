with PSX.GPU;
with PSX.Memory;
with PSX.Types;

package PSX.DMA is

   subtype Word32 is PSX.Types.Word32;

   procedure Reset (Memory : in out PSX.Memory.Memory_State);

   procedure Process (Memory : in out PSX.Memory.Memory_State);

   procedure Process
     (Memory : in out PSX.Memory.Memory_State; GPU : in out PSX.GPU.GPU_State);

end PSX.DMA;
