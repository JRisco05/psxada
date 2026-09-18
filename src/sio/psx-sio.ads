with PSX.Types;

package PSX.SIO is

   subtype Word16 is PSX.Types.Word16;
   subtype Word32 is PSX.Types.Word32;

   type SIO_State is record
      Status    : Word16; -- Status Register (0x1F801044)
      Control   : Word16; -- Control Register (0x1F80104A)
      Baud_Rate : Word16; -- Baudrate Divider (0x1F80104E)

      -- Búferes internos para simular la comunicación SPI con el mando 1
      TX_Buffer    : Word16;
      RX_Buffer    : Word16;
      Command_Step : Natural;
   end record;

   procedure Reset (SIO : out SIO_State);

   procedure Read_Register
     (SIO : in SIO_State; Address : in Word32; Value : out Word16);

   procedure Write_Register
     (SIO : in out SIO_State; Address : in Word32; Value : in Word16);

end PSX.SIO;
