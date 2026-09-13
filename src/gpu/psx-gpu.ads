with PSX.Types;

package PSX.GPU is

   subtype Word8 is PSX.Types.Word8;
   subtype Word16 is PSX.Types.Word16;
   subtype Word32 is PSX.Types.Word32;

   VRAM_WIDTH  : constant := 1024;
   VRAM_HEIGHT : constant := 512;

   type VRAM_Array is
     array (Natural range 0 .. VRAM_WIDTH * VRAM_HEIGHT - 1) of Word16;

   type GP0_Data_Array is array (Natural range 0 .. 15) of Word32;

   type GPU_State is record

      GP0    : Word32;
      GP1    : Word32;
      Status : Word32;
      VRAM   : VRAM_Array;

      GP0_Command        : Word8;
      GP0_Expected_Words : Natural;
      GP0_Received_Words : Natural;
      GP0_Data           : GP0_Data_Array;

      GP0_X      : Natural;
      GP0_Y      : Natural;
      GP0_Width  : Natural;
      GP0_Height : Natural;
      
   end record;

   procedure Reset (GPU : out GPU_State);

   procedure Write_GP0 (GPU : in out GPU_State; Value : Word32);

   procedure Write_GP1 (GPU : in out GPU_State; Value : Word32);

   function Read_Status (GPU : GPU_State) return Word32;

   procedure Write_VRAM
     (GPU : in out GPU_State; X : Natural; Y : Natural; Value : Word16);

   function Read_VRAM
     (GPU : GPU_State; X : Natural; Y : Natural) return Word16;

end PSX.GPU;
