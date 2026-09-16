with Interfaces;
with Ada.Text_IO;
with PSX.SPU;

procedure PSX_SPU_Tests is

   use Ada.Text_IO;
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;

   SPU : PSX.SPU.SPU_State;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Put_Line ("PASS: " & Message);
      else
         Put_Line ("FAIL: " & Message);
      end if;
   end Check;

begin

   Put_Line ("Testing PSX.SPU...");
   New_Line;

   -- Reset del SPU
   PSX.SPU.Reset (SPU);

   Check (SPU.Control = 0, "SPU Control reset");

   Check (SPU.Status = 0, "SPU Status reset");

   Check (SPU.Transfer_Address = 0, "SPU Transfer Address reset");

   Check (SPU.Transfer_Control = 0, "SPU Transfer Control reset");

   Check (SPU.IRQ_Address = 0, "SPU IRQ Address reset");

   -- Verificar que la RAM del SPU está inicializada en cero
   Check (SPU.RAM (0) = 0, "SPU RAM address 0 reset");

   Check (SPU.RAM (16#0001_0000#) = 0, "SPU RAM address 0x10000 reset");

   Check (SPU.RAM (16#0007_FFFF#) = 0, "SPU RAM last address reset");

   -- Escritura y lectura de la RAM
   SPU.RAM (16#0000_0000#) := 16#12#;
   SPU.RAM (16#0001_0000#) := 16#34#;
   SPU.RAM (16#0007_FFFF#) := 16#AB#;

   Check (SPU.RAM (16#0000_0000#) = 16#12#, "SPU RAM write/read address 0");

   Check
     (SPU.RAM (16#0001_0000#) = 16#34#, "SPU RAM write/read address 0x10000");

   Check (SPU.RAM (16#0007_FFFF#) = 16#AB#, "SPU RAM write/read last address");

   -- Verificar que las posiciones son independientes
   Check (SPU.RAM (16#0000_0001#) = 0, "SPU RAM independent address 1");

   Check (SPU.RAM (16#0001_0001#) = 0, "SPU RAM independent address 2");

   -- Verificar los 24 canales

   Check (SPU.Channels'Length = 24, "SPU has 24 channels");

   Check (SPU.Channels (0).Volume_Left = 0, "Channel 0 Volume Left reset");

   Check (SPU.Channels (0).Volume_Right = 0, "Channel 0 Volume Right reset");

   Check (SPU.Channels (0).Pitch = 0, "Channel 0 Pitch reset");

   Check (SPU.Channels (0).Start_Address = 0, "Channel 0 Start Address reset");

   Check (not SPU.Channels (0).Key_On, "Channel 0 Key On reset");

   Check (not SPU.Channels (0).Key_Off, "Channel 0 Key Off reset");

   Check (SPU.Channels (23).Volume_Left = 0, "Channel 23 Volume Left reset");

   Check (SPU.Channels (23).Volume_Right = 0, "Channel 23 Volume Right reset");

   Check (SPU.Channels (23).Pitch = 0, "Channel 23 Pitch reset");

   Check
     (SPU.Channels (23).Start_Address = 0, "Channel 23 Start Address reset");

   -- Verificar independencia entre canales

   SPU.Channels (0).Volume_Left := 16#1234#;
   SPU.Channels (23).Volume_Left := 16#ABCD#;

   Check (SPU.Channels (0).Volume_Left = 16#1234#, "Channel 0 independent");

   Check (SPU.Channels (23).Volume_Left = 16#ABCD#, "Channel 23 independent");

   Check (SPU.Channels (1).Volume_Left = 0, "Channel 1 unaffected");

   Check (SPU.Channels (22).Volume_Left = 0, "Channel 22 unaffected");

      -- Voice 1

   PSX.SPU.Write_Register
     (SPU,
      16#1F801C10#,
      16#1111#);

   Check
     (SPU.Channels (1).Volume_Left = 16#1111#,
      "Voice 1 Volume Left register");

   -- Voice 23

   PSX.SPU.Write_Register
     (SPU,
      16#1F801D70#,
      16#AAAA#);

   Check
     (SPU.Channels (23).Volume_Left = 16#AAAA#,
      "Voice 23 Volume Left register");

         declare
      Value : Interfaces.Unsigned_16;
   begin

      PSX.SPU.Read_Register
        (SPU,
         16#1F801C00#,
         Value);

      Check
        (Value = 16#1234#,
         "Read Voice 0 Volume Left");

      PSX.SPU.Read_Register
        (SPU,
         16#1F801D70#,
         Value);

      Check
        (Value = 16#AAAA#,
         "Read Voice 23 Volume Left");

   end;

   New_Line;
   Put_Line ("SPU basic tests completed.");

end PSX_SPU_Tests;
