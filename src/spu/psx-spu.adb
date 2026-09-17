package body PSX.SPU is

   procedure Reset (SPU : out SPU_State) is
   begin

      SPU.RAM := (others => 0);

      SPU.Control := 0;
      SPU.Status := 0;if Address = 16#1F801D80# then

   SPU.Main_Volume_Left := Value;

elsif Address = 16#1F801D82# then

   SPU.Main_Volume_Right := Value;

elsif Address = 16#1F801D84# then

   SPU.Reverb_Volume_Left := Value;

elsif Address = 16#1F801D86# then

   SPU.Reverb_Volume_Right := Value;

elsif Address >= 16#1F801C00#
  and then Address <= 16#1F801D7F#
then

   -- aquí permanece tu código actual de voices

end if;

      SPU.Transfer_Address := 0;
      SPU.Transfer_Control := 0;

      SPU.IRQ_Address := 0;

   end Reset;

   procedure Write_Register
     (SPU : in out SPU_State; Address : in Word32; Value : in Word16)
   is
      Voice_Index : Natural;
      Offset      : Word32;
   begin
      if Address >= 16#1F801C00# and then Address <= 16#1F801D7F# then
         Offset := Address - 16#1F801C00#;

         Voice_Index := Natural (Offset / 16#10#);

         case Offset mod 16#10# is

            when 16#00# =>
               SPU.Channels (Voice_Index).Volume_Left := Value;

            when 16#02# =>
               SPU.Channels (Voice_Index).Volume_Right := Value;

            when 16#04# =>
               SPU.Channels (Voice_Index).Pitch := Value;

            when 16#06# =>
               SPU.Channels (Voice_Index).Start_Address := Value;
            
            when 16#1F801D80# =>
               SPU.Main_Volume_Left := Value;
            
            when 16#1F801D82# =>
               SPU.Main_Volume_Right := Value;

            when 16#1F801D84# =>
               SPU.Reverb_Volume_Left := Value;
            
            when 16#1F801D86# =>
               SPU.Reverb_Volume_Right := Value;
            
             when  =>
               SPU.

            when others => 
               null;

         end case;
      
      
      
      


elsif Address >= 16#1F801C00#
  and then Address <= 16#1F801D7F#
then

   
   end Write_Register;

   procedure Read_Register
     (SPU : in SPU_State; Address : in Word32; Value : out Word16)
   is
      Voice_Index : Natural;
      Offset      : Word32;
   begin
      Value := 0;

      if Address >= 16#1F801C00# and then Address <= 16#1F801D7F# then
         Offset := Address - 16#1F801C00#;

         Voice_Index := Natural (Offset / 16#10#);

         case Offset mod 16#10# is

            when 16#00# =>
               Value := SPU.Channels (Voice_Index).Volume_Left;

            when 16#02# =>
               Value := SPU.Channels (Voice_Index).Volume_Right;

            when 16#04# =>
               Value := SPU.Channels (Voice_Index).Pitch;

            when 16#06# =>
               Value := SPU.Channels (Voice_Index).Start_Address;

            when others =>
               null;

         end case;
      end if;
   end Read_Register;

end PSX.SPU;
