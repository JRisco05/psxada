with PSX.Memory;
with PSX.Types;

package PSX.DMA is

   subtype Word32 is PSX.Types.Word32;

   Channel_Count : constant := 7;

   type DMA_Channel is record
      Base_Address    : Word32 := 0;
      Block_Control   : Word32 := 0;
      Channel_Control : Word32 := 0;
   end record;

   type DMA_Channel_Array is array (0 .. Channel_Count - 1) of DMA_Channel;

   type DMA_State is record
      Channels : DMA_Channel_Array;
      DPCR     : Word32 := 0;
      DICR     : Word32 := 0;
   end record;

   procedure Reset (DMA : out DMA_State);

   procedure Process
     (DMA : in out DMA_State; Memory : in out PSX.Memory.Memory_State);

end PSX.DMA;
