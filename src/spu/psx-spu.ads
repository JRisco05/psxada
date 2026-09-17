with Interfaces;
with PSX.Types;

package PSX.SPU is

   use type Interfaces.Unsigned_32;

   subtype Word8 is PSX.Types.Word8;
   subtype Word16 is PSX.Types.Word16;
   subtype Word32 is PSX.Types.Word32;

   --  Estructura de un canal individual
   type SPU_Channel is record
      Volume_Left     : Word16;
      Volume_Right    : Word16;
      Pitch           : Word16;
      Start_Address   : Word16;
      ADSR_Level      : Word32;
      ADSR            : Word32;
      Current_Address : Word16;
      Key_On          : Boolean;
      Key_Off         : Boolean;
   end record;

   --  Arreglo de los 24 canales de audio de la PSX
   type Channel_Array is array (0 .. 23) of SPU_Channel;

   SPU_RAM_SIZE : constant := 16#0008_0000#;

   type SPU_RAM_Array is array (Word32 range 0 .. SPU_RAM_SIZE - 1) of Word8;

   type SPU_State is record
      Channels          : Channel_Array; -- ¡Agregado de vuelta!
      RAM               : SPU_RAM_Array;
      Control           : Word16;
      Status            : Word16;
      Transfer_Address  : Word16;
      Transfer_Control  : Word16;
      IRQ_Address       : Word16;
      Main_Volume_Left  : Word16;
      Main_Volume_Right : Word16;

      Reverb_Volume_Left  : Word16;
      Reverb_Volume_Right : Word16;
   end record;

   procedure Reset (SPU : out SPU_State);

   procedure Read_Register
     (SPU : in SPU_State; Address : in Word32; Value : out Word16);

   procedure Write_Register
     (SPU : in out SPU_State; Address : in Word32; Value : in Word16);

end PSX.SPU;
