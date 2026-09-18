with PSX.Types;

package PSX.CDROM is

   subtype Word8 is PSX.Types.Word8;
   subtype Word16 is PSX.Types.Word16;
   subtype Word32 is PSX.Types.Word32;

   -- Estructura interna LLE para simular el chip controlador del CD-ROM
   type CDROM_State is record
      Index            :
        Word8;  -- Registro de página actual (0..3) mapeado en 0x1F801800
      Status_Reg       : Word8;  -- Registro de estado del chip
      Interrupt_Enable : Word8;  -- Máscara de interrupciones permitidas
      Interrupt_Flag   : Word8;  -- Banderas de interrupciones activas (IRQ 2)

      -- Búferes FIFO para comandos y respuestas
      Command_Param : array (0 .. 15) of Word8;
      Param_Count   : Natural;

      Response_Buffer : array (0 .. 15) of Word8;
      Response_Count  : Natural;
      Response_Index  : Natural;
   end record;

   procedure Reset (CD : out CDROM_State);

   procedure Read_Register
     (CD : in CDROM_State; Address : in Word32; Value : out Word8);

   procedure Write_Register
     (CD : in out CDROM_State; Address : in Word32; Value : in Word8);

end PSX.CDROM;
