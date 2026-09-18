package body PSX.CDROM is

   ------------------
   --    RESET     --
   ------------------
   procedure Reset (CD : out CDROM_State) is
   begin
      CD.Index            := 0;
      CD.Status_Reg       := 16#18#; -- Bit 3 y 4 activos indican que la FIFO de parámetros está vacía y lista
      CD.Interrupt_Enable := 0;
      CD.Interrupt_Flag   := 0;
      CD.Param_Count      := 0;
      CD.Response_Count   := 0;
      CD.Response_Index   := 0;
      CD.Response_Buffer  := (others => 0);
      CD.Command_Param    := (others => 0);
   end Reset;

   --------------------
   -- WRITE REGISTER --
   --------------------
   procedure Write_Register
     (CD : in out CDROM_State; Address : in Word32; Value : in Word8)
   is
   begin
      case Address is
         when 16#1F801800# =>
            -- La CPU escribe aquí para cambiar el Índice de página (Bits 0 y 1)
            CD.Index := Value and 16#03#;

         when 16#1F801801# =>
            case CD.Index is
               when 0 =>
                  -- Ejecutar Comando de CD-ROM (GetStatus, Read, etc.)
                  -- Por ahora solo guardamos un estado simulado básico para la BIOS
                  CD.Response_Buffer(0) := 16#02#; -- Estado: Lector cerrado
                  CD.Response_Count     := 1;
                  CD.Response_Index     := 0;
                  CD.Interrupt_Flag     := 16#03#; -- INT3: Comando completado con éxito
               when others =>
                  null;
            end case;

         when 16#1F801802# =>
            case CD.Index is
               when 0 => -- Escribir parámetros del comando (Minuto, Segundo, Frame)
                  if CD.Param_Count < 16 then
                     CD.Command_Param(CD.Param_Count) := Value;
                     CD.Param_Count := CD.Param_Count + 1;
                  end if;
               when 1 => -- Registro de habilitación de interrupciones
                  CD.Interrupt_Enable := Value;
               when others =>
                  null;
            end case;

         when 16#1F801803# =>
            case CD.Index is
               when 1 => -- Confirmar/Limpiar interrupciones (Acknowledge)
                  CD.Interrupt_Flag := CD.Interrupt_Flag and (not Value);
               when others =>
                  null;
            end case;

         when others =>
            null;
      end case;
   end Write_Register;

   -------------------
   -- READ REGISTER --
   -------------------
   procedure Read_Register
     (CD : in CDROM_State; Address : in Word32; Value : out Word8)
   is
   begin
      Value := 0;
      case Address is
         when 16#1F801800# =>
            -- Leer el índice actual combinado con el estado de transmisión
            Value := CD.Index or CD.Status_Reg;

         when 16#1F801801# =>
            -- Leer bytes de la cola de respuesta
            if CD.Response_Count > 0 and then CD.Response_Index < CD.Response_Count then
               Value := CD.Response_Buffer(CD.Response_Index);
               CD.Response_Index := CD.Response_Index + 1;
            end if;

         when 16#1F801802# =>
            -- Datos del búfer de datos crudos (Data FIFO)
            Value := 0;

         when 16#1F801803# =>
            case CD.Index is
               when 0, 2 => -- Leer bandera de interrupciones activas
                  Value := CD.Interrupt_Flag or 16#E0#; -- Bits superiores suelen leerse como 1
               when 1 => -- Leer máscara de interrupciones
                  Value := CD.Interrupt_Enable or 16#E0#;
               when others =>
                  Value := 0;
            end case;

         when others =>
            Value := 0;
      end case;
   end Read_Register;

end PSX.CDROM;
