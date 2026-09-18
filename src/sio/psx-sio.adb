package body PSX.SIO is

   ------------------
   --    RESET     --
   ------------------
   procedure Reset (SIO : out SIO_State) is
   begin
      -- Al encender, el SIO indica que está listo para transmitir datos
      -- Bit 2: TX Buffer Empty (1 = Vacío/Listo)
      -- Bit 1: TX Ready (1 = Listo)
      SIO.Status := 16#0006#;
      SIO.Control := 0;
      SIO.Baud_Rate := 0;
      SIO.TX_Buffer := 0;
      SIO.RX_Buffer := 0;
      SIO.Command_Step := 0;
   end Reset;

   --------------------
   -- WRITE REGISTER --
   --------------------
   procedure Write_Register
     (SIO : in out SIO_State; Address : in Word32; Value : in Word16) is
   begin
      case Address is
         when 16#1F801040# =>
            -- SIO_DATA (Escritura de comandos al mando)
            SIO.TX_Buffer := Value;
            -- Aquí procesaremos bit a bit el protocolo SPI del mando más adelante.
            null;

         when 16#1F801044# =>
            -- SIO_STAT
            -- El registro de estado suele ser de solo lectura en muchos bits,
            -- pero escribir aquí puede resetear banderas de error.
            null;

         when 16#1F80104A# =>
            -- SIO_CTRL
            SIO.Control := Value;

         when 16#1F80104E# =>
            -- SIO_BAUD
            SIO.Baud_Rate := Value;

         when others       =>
            null;
      end case;
   end Write_Register;

   -------------------
   -- READ REGISTER --
   -------------------
   procedure Read_Register
     (SIO : in SIO_State; Address : in Word32; Value : out Word16) is
   begin
      case Address is
         when 16#1F801040# =>
            -- SIO_DATA (Leer respuesta del mando)
            Value := SIO.RX_Buffer;

         when 16#1F801044# =>
            -- SIO_STAT
            -- Entregamos el estado simulando que el hardware responde al instante
            Value := SIO.Status;

         when 16#1F80104A# =>
            -- SIO_CTRL
            Value := SIO.Control;

         when 16#1F80104E# =>
            -- SIO_BAUD
            Value := SIO.Baud_Rate;

         when others       =>
            Value := 0;
      end case;
   end Read_Register;

end PSX.SIO;
