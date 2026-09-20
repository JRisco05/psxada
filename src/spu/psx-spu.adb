with Interfaces;

package body PSX.SPU is

   use type Interfaces.Unsigned_16;

   -------------
   --  RESET  --
   -------------
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

      SPU.Main_Volume_Left := 0;
      SPU.Main_Volume_Right := 0;
      SPU.Reverb_Volume_Left := 0;
      SPU.Reverb_Volume_Right := 0;

      for I in SPU.Channels'Range loop
         SPU.Channels (I).Volume_Left := 0;
         SPU.Channels (I).Volume_Right := 0;
         SPU.Channels (I).Pitch := 0;
         SPU.Channels (I).Start_Address := 0;
         SPU.Channels (I).ADSR1 := 0;
         SPU.Channels (I).ADSR2 := 0;
         SPU.Channels (I).ADSR_Level := 0;
         SPU.Channels (I).Current_Address := 0;
         SPU.Channels (I).Key_On := False;
         SPU.Channels (I).Key_Off := False;
      end loop;
   end Reset;

   --------------------
   -- WRITE REGISTER --
   --------------------
   procedure Write_Register
     (SPU : in out SPU_State; Address : Word32; Value : Word16)
   is
      Voice_Index : Natural;
      Offset      : Word32;
      Selector    : Natural;
   begin
      if Address = 16#1F801D80# then
         SPU.Main_Volume_Left := Value;
      elsif Address = 16#1F801D82# then
         SPU.Main_Volume_Right := Value;
      elsif Address = 16#1F801D84# then
         SPU.Reverb_Volume_Left := Value;
      elsif Address = 16#1F801D86# then
         SPU.Reverb_Volume_Right := Value;

      elsif Address = 16#1F801D88# then
         SPU.Key_On := (SPU.Key_On and 16#FFFF_0000#) or Word32 (Value);

      elsif Address = 16#1F801D8A# then
         SPU.Key_On :=
           (SPU.Key_On and 16#0000_FFFF#)
           or Interfaces.Shift_Left (Word32 (Value), 16);

      elsif Address = 16#1F801D8C# then
         SPU.Key_Off := (SPU.Key_Off and 16#FFFF_0000#) or Word32 (Value);

      elsif Address = 16#1F801D8E# then
         SPU.Key_Off :=
           (SPU.Key_Off and 16#0000_FFFF#)
           or Interfaces.Shift_Left (Word32 (Value), 16);

      elsif Address = 16#1F801DA6# then
         SPU.Transfer_Control := Value;
      elsif Address = 16#1F801DAA# then
         SPU.Control := Value;

      elsif Address >= 16#1F801C00# and then Address <= 16#1F801D7F# then
         Offset := Address - 16#1F801C00#;
         Voice_Index := Natural (Offset / 16#10#);
         Selector := Natural (Offset mod 16#10#);

         case Selector is
            when 16#00# =>
               SPU.Channels (Voice_Index).Volume_Left := Value;

            when 16#02# =>
               SPU.Channels (Voice_Index).Volume_Right := Value;

            when 16#04# =>
               SPU.Channels (Voice_Index).Pitch := Value;

            when 16#06# =>
               SPU.Channels (Voice_Index).Start_Address := Value;

            when 16#08# =>
               SPU.Channels (Voice_Index).ADSR1 := Value;

            when 16#0A# =>
               SPU.Channels (Voice_Index).ADSR2 := Value;

            when 16#0E# =>
               SPU.Channels (Voice_Index).Current_Address := Value;

            when others =>
               null;
         end case;
      end if;
   end Write_Register;

   -------------------
   -- READ REGISTER --
   -------------------
   procedure Read_Register
     (SPU : SPU_State; Address : Word32; Value : out Word16)
   is
      Voice_Index : Natural;
      Offset      : Word32;
      Selector    : Natural;
   begin
      Value := 0;

      if Address = 16#1F801D80# then
         Value := SPU.Main_Volume_Left;
      elsif Address = 16#1F801D82# then
         Value := SPU.Main_Volume_Right;
      elsif Address = 16#1F801D84# then
         Value := SPU.Reverb_Volume_Left;
      elsif Address = 16#1F801D86# then
         Value := SPU.Reverb_Volume_Right;

      elsif Address = 16#1F801D88# then
         Value := Word16 (SPU.Key_On and 16#0000_FFFF#);

      elsif Address = 16#1F801D8A# then
         -- 🌟 SOLUCIÓN DEFINITIVA: El casteo envuelve TODA la operación de bits
         Value :=
           Word16 (Interfaces.Shift_Right (SPU.Key_On, 16) and 16#0000_FFFF#);

      elsif Address = 16#1F801D8C# then
         Value := Word16 (SPU.Key_Off and 16#0000_FFFF#);

      elsif Address = 16#1F801D8E# then
         -- 🌟 SOLUCIÓN DEFINITIVA: El casteo envuelve TODA la operación de bits
         Value :=
           Word16 (Interfaces.Shift_Right (SPU.Key_Off, 16) and 16#0000_FFFF#);

      elsif Address = 16#1F801DAA# then
         Value := SPU.Control;
      elsif Address = 16#1F801DAE# then
         Value := SPU.Status;

      elsif Address >= 16#1F801C00# and then Address <= 16#1F801D7F# then
         Offset := Address - 16#1F801C00#;
         Voice_Index := Natural (Offset / 16#10#);
         Selector := Natural (Offset mod 16#10#);

         case Selector is
            when 16#00# =>
               Value := SPU.Channels (Voice_Index).Volume_Left;

            when 16#02# =>
               Value := SPU.Channels (Voice_Index).Volume_Right;

            when 16#04# =>
               Value := SPU.Channels (Voice_Index).Pitch;

            when 16#06# =>
               Value := SPU.Channels (Voice_Index).Start_Address;

            when 16#08# =>
               Value := SPU.Channels (Voice_Index).ADSR1;

            when 16#0A# =>
               Value := SPU.Channels (Voice_Index).ADSR2;

            when 16#0C# =>
               Value := SPU.Channels (Voice_Index).ADSR_Level;

            when 16#0E# =>
               Value := SPU.Channels (Voice_Index).Current_Address;

            when others =>
               Value := 0;
         end case;
      end if;
   end Read_Register;

end PSX.SPU;
