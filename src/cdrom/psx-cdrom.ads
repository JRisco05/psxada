with PSX.Types;

package PSX.CDROM is

   subtype Word8 is PSX.Types.Word8;
   subtype Word16 is PSX.Types.Word16;
   subtype Word32 is PSX.Types.Word32;

   type Buffer_16_Bytes is array (0 .. 15) of Word8;

   type CDROM_State is record
      Index            : Word8;
      Status_Reg       : Word8;
      Interrupt_Enable : Word8;
      Interrupt_Flag   : Word8;

      Command_Param : Buffer_16_Bytes;
      Param_Count   : Natural;

      Response_Buffer : Buffer_16_Bytes;
      Response_Count  : Natural;
      Response_Index  : Natural;
   end record;

   procedure Reset (CD : out CDROM_State);

   -- 🌟 CORREGIDO: Cambiado a procedure con 'in out' para poder vaciar la FIFO
   procedure Read_Register
     (CD : in out CDROM_State; Address : Word32; Value : out Word8);

   procedure Write_Register
     (CD : in out CDROM_State; Address : Word32; Value : Word8);

end PSX.CDROM;
