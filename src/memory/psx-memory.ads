with PSX.Types;
with PSX.Timers;

package PSX.Memory is

   type DMA_Register_Array is
     array (PSX.Types.Word32 range 0 .. 16#7F#) of PSX.Types.Word32;

   type Memory_Array is
     array (PSX.Types.Word32 range 0 .. 16#001F_FFFF#) of PSX.Types.Word8;

   type Scratchpad_Array is
     array (PSX.Types.Word32 range 0 .. 16#0000_03FF#) of PSX.Types.Word8;

   type BIOS_Array is
     array (PSX.Types.Word32 range 0 .. 16#0007_FFFF#) of PSX.Types.Word8;

   type Memory_State is record
      Data          : Memory_Array;
      Scratchpad    : Scratchpad_Array;
      BIOS          : BIOS_Array;
      DMA_Registers : DMA_Register_Array;
      Timers        : PSX.Timers.Timers_State;
   end record;

   procedure Reset (Memory : out Memory_State);

   function Read_8
     (Memory : Memory_State; Address : PSX.Types.Word32)
      return PSX.Types.Word8;

   function Read_16
     (Memory : Memory_State; Address : PSX.Types.Word32)
      return PSX.Types.Word16;

   function Read_32
     (Memory : Memory_State; Address : PSX.Types.Word32)
      return PSX.Types.Word32;

   procedure Write_8
     (Memory  : in out Memory_State;
      Address : PSX.Types.Word32;
      Value   : PSX.Types.Word8);

   procedure Write_16
     (Memory  : in out Memory_State;
      Address : PSX.Types.Word32;
      Value   : PSX.Types.Word16);

   procedure Write_32
     (Memory  : in out Memory_State;
      Address : PSX.Types.Word32;
      Value   : PSX.Types.Word32);

   procedure Load_BIOS (Memory : in out Memory_State; Path : String);

end PSX.Memory;
