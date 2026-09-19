package body PSX.SPU is

   procedure Reset (SPU : out SPU_State) is
   begin
      SPU.RAM := (others => 0);

      SPU.Control := 0;
      SPU.Status := 0;
      SPU.Transfer_Address := 0;
      SPU.Transfer_Control := 0;
      SPU.IRQ_Address := 0;
      SPU.Key_On := 0;
      SPU.Key_Off := 0;

      -- 🌟 Inicialización limpia de volúmenes para evitar basura en los tests
      SPU.Main_Volume_Left := 0;
      SPU.Main_Volume_Right := 0;
      SPU.Reverb_Volume_Left := 0;
      SPU.Reverb_Volume_Right := 0;

      for I in SPU.Channels'Range loop
         SPU.Channels (I).Volume_Left := 0;
         SPU.Channels (I).Volume_Right := 0;
         SPU.Channels (I).Pitch := 0;
         SPU.Channels (I).Start_Address := 0;
         SPU.Channels (I).ADSR_Level := 0;
         SPU.Channels (I).ADSR := 0;
         SPU.Channels (I).Current_Address := 0;
         SPU.Channels (I).Key_On := False;
         SPU.Channels (I).Key_Off := False;
      end loop;
   end Reset;

      procedure Write_Register
     (SPU : in out SPU_State; Address : in Word32; Value : in Word16)
   is
      Voice_Index : Natural;
      Offset      : Word32;
      Selector    : Natural; -- 🌟 Variable auxiliar para resolver el tipo del case
   begin
      --  1. Primero comprobamos las direcciones de volumen GLOBAL
      if Address = 16#1F801D80# then
         SPU.Main_Volume_Left := Value;
      elsif Address = 16#1F801D82# then
         SPU.Main_Volume_Right := Value;
      elsif Address = 16#1F801D84# then
         SPU.Reverb_Volume_Left := Value;
      elsif Address = 16#1F801D86# then
         SPU.Reverb_Volume_Right := Value;

      --  🌟 Registros de control globales
      elsif Address = 16#1F801DA6# then
         SPU.Transfer_Control := Value;
      elsif Address = 16#1F801DAA# then
         SPU.Control := Value;

      --  2. Si no es volumen global, comprobamos el rango de las 24 VOCES
      elsif Address >= 16#1F801C00# and then Address <= 16#1F801D7F# then
         Offset := Address - 16#1F801C00#;
         Voice_Index := Natural (Offset / 16#10#);
         Selector    := Natural (Offset mod 16#10#); -- 🌟 Convertimos explícitamente a Natural

         case Selector is
            when 16#00# =>
               SPU.Channels (Voice_Index).Volume_Left := Value;
            when 16#02# =>
               SPU.Channels (Voice_Index).Volume_Right := Value;
            when 16#04# =>
               SPU.Channels (Voice_Index).Pitch := Value;
            when 16#06# =>
               SPU.Channels (Voice_Index).Start_Address := Value;
            when others =>
               null;
         end case;
      end if;
   end Write_Register;


   procedure Read_Register
     (SPU : in SPU_State; Address : in Word32; Value : out Word16)
   is
      Voice_Index : Natural;
      Offset      : Word32;
      Selector    : Natural; -- 🌟 Variable auxiliar para resolver el tipo del case
   begin
      Value := 0; -- Valor de seguridad por defecto

      --  1. Primero comprobamos las lecturas de volumen GLOBAL
      if Address = 16#1F801D80# then
         Value := SPU.Main_Volume_Left;
      elsif Address = 16#1F801D82# then
         Value := SPU.Main_Volume_Right;
      elsif Address = 16#1F801D84# then
         Value := SPU.Reverb_Volume_Left;
      elsif Address = 16#1F801D86# then
         Value := SPU.Reverb_Volume_Right;

      --  🌟 Registros de control y Estado global
      elsif Address = 16#1F801DAA# then
         Value := SPU.Control;
      elsif Address = 16#1F801DAE# then
         Value := SPU.Status;

      --  2. Si no, comprobamos si la CPU quiere leer los datos de las 24 VOCES
      elsif Address >= 16#1F801C00# and then Address <= 16#1F801D7F# then
         Offset := Address - 16#1F801C00#;
         Voice_Index := Natural (Offset / 16#10#);
         Selector    := Natural (Offset mod 16#10#); -- 🌟 Convertimos explícitamente a Natural

         case Selector is
            when 16#00# =>
               Value := SPU.Channels (Voice_Index).Volume_Left;
            when 16#02# =>
               Value := SPU.Channels (Voice_Index).Volume_Right;
            when 16#04# =>
               Value := SPU.Channels (Voice_Index).Pitch;
            when 16#06# =>
               Value := SPU.Channels (Voice_Index).Start_Address;
            when others =>
               Value := 0;
         end case;
      end if;
   end Read_Register;

end PSX.SPU;
