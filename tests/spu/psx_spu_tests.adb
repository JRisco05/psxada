with Interfaces;
with PSX.SPU;
with Ada.Text_IO;

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

   --  Reset del SPU
   PSX.SPU.Reset (SPU);

   Check (SPU.Control = 0, "SPU Control reset");

   Check (SPU.Status = 0, "SPU Status reset");

   Check (SPU.Transfer_Address = 0, "SPU Transfer Address reset");

   Check (SPU.Transfer_Control = 0, "SPU Transfer Control reset");

   Check (SPU.IRQ_Address = 0, "SPU IRQ Address reset");

   --  Verificar que la RAM del SPU está inicializada en cero
   Check (SPU.RAM (0) = 0, "SPU RAM address 0 reset");

   Check (SPU.RAM (16#0001_0000#) = 0, "SPU RAM address 0x10000 reset");

   Check (SPU.RAM (16#0007_FFFF#) = 0, "SPU RAM last address reset");

   --  Escritura y lectura de la RAM
   SPU.RAM (16#0000_0000#) := 16#12#;
   SPU.RAM (16#0001_0000#) := 16#34#;
   SPU.RAM (16#0007_FFFF#) := 16#AB#;

   Check (SPU.RAM (16#0000_0000#) = 16#12#, "SPU RAM write/read address 0");

   Check
     (SPU.RAM (16#0001_0000#) = 16#34#, "SPU RAM write/read address 0x10000");

   Check (SPU.RAM (16#0007_FFFF#) = 16#AB#, "SPU RAM write/read last address");

   --  Verificar que las posiciones son independientes
   Check (SPU.RAM (16#0000_0001#) = 0, "SPU RAM independent address 1");

   Check (SPU.RAM (16#0001_0001#) = 0, "SPU RAM independent address 2");

   --  Verificar los 24 canales

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

   --  Verificar independencia entre canales

   SPU.Channels (0).Volume_Left := 16#1234#;
   SPU.Channels (23).Volume_Left := 16#ABCD#;

   Check (SPU.Channels (0).Volume_Left = 16#1234#, "Channel 0 independent");

   Check (SPU.Channels (23).Volume_Left = 16#ABCD#, "Channel 23 independent");

   Check (SPU.Channels (1).Volume_Left = 0, "Channel 1 unaffected");

   Check (SPU.Channels (22).Volume_Left = 0, "Channel 22 unaffected");

   --  Voice 1

   PSX.SPU.Write_Register (SPU, 16#1F801C10#, 16#1111#);

   Check
     (SPU.Channels (1).Volume_Left = 16#1111#, "Voice 1 Volume Left register");

   --  Voice 23

   PSX.SPU.Write_Register (SPU, 16#1F801D70#, 16#AAAA#);

   Check
     (SPU.Channels (23).Volume_Left = 16#AAAA#,
      "Voice 23 Volume Left register");

   declare
      Value : Interfaces.Unsigned_16;
   begin

      PSX.SPU.Read_Register (SPU, 16#1F801C00#, Value);

      Check (Value = 16#1234#, "Read Voice 0 Volume Left");

      PSX.SPU.Read_Register (SPU, 16#1F801D70#, Value);

      Check (Value = 16#AAAA#, "Read Voice 23 Volume Left");

   end;

   --  Código de verificación de lectura corregido:
   declare
      Value :
        PSX.SPU.Word16; --  O simplemente Word16 si usas "use PSX.SPU;" arriba
   begin

      --  🌟 ¡PASO CRÍTICO!: Primero escribimos los valores en el SPU
      PSX.SPU.Write_Register (SPU, 16#1F801D80#, 16#1111#);
      PSX.SPU.Write_Register (SPU, 16#1F801D82#, 16#2222#);
      PSX.SPU.Write_Register (SPU, 16#1F801D84#, 16#3333#);
      PSX.SPU.Write_Register (SPU, 16#1F801D86#, 16#4444#);

      PSX.SPU.Read_Register (SPU, 16#1F801D80#, Value);

      Check (Value = 16#1111#, "Read Main Volume Left");

      PSX.SPU.Read_Register (SPU, 16#1F801D82#, Value);

      Check (Value = 16#2222#, "Read Main Volume Right");

      PSX.SPU.Read_Register (SPU, 16#1F801D84#, Value);

      Check (Value = 16#3333#, "Read Reverb Volume Left");

      PSX.SPU.Read_Register (SPU, 16#1F801D86#, Value);

      Check (Value = 16#4444#, "Read Reverb Volume Right");

   end;
   --  🌟 Pruebas incrementales de registros de Control y Estado
   declare
      Control_Value : PSX.SPU.Word16;
   begin
      -- Escribimos un patrón de bits en el registro de Control
      PSX.SPU.Write_Register (SPU, 16#1F801DAA#, 16#A5A5#);

      -- Lo leemos de vuelta para verificar la línea de bus
      PSX.SPU.Read_Register (SPU, 16#1F801DAA#, Control_Value);
      Check (Control_Value = 16#A5A5#, "Write/Read SPU Control register");
   end;

   --  🌟 Verificación de registros KON/KOFF corregida para Ada
   declare
      Test_Value : PSX.SPU.Word16;
   begin
      --  KON low: voces 0 y 15
      PSX.SPU.Write_Register (SPU, 16#1F801D88#, 16#8001#);
      PSX.SPU.Read_Register (SPU, 16#1F801D88#, Test_Value);
      Check (Test_Value = 16#8001#, "KON low voices 0 and 15");

      --  KON high: voces 16 y 23
      PSX.SPU.Write_Register (SPU, 16#1F801D8A#, 16#0081#);
      PSX.SPU.Read_Register (SPU, 16#1F801D8A#, Test_Value);
      Check (Test_Value = 16#0081#, "KON high voices 16 and 23");

      --  KOFF low: voces 0 y 15
      PSX.SPU.Write_Register (SPU, 16#1F801D8C#, 16#8001#);
      PSX.SPU.Read_Register (SPU, 16#1F801D8C#, Test_Value);
      Check (Test_Value = 16#8001#, "KOFF low voices 0 and 15");

      --  KOFF high: voces 16 y 23
      PSX.SPU.Write_Register (SPU, 16#1F801D8E#, 16#0081#);
      PSX.SPU.Read_Register (SPU, 16#1F801D8E#, Test_Value);
      Check (Test_Value = 16#0081#, "KOFF high voices 16 and 23");
   end;

   declare
      Test_Value : PSX.SPU.Word16;
   begin
      -- 1. Escribimos y leemos ADSR1 (ADSR Low: 0x1F801C08)
      PSX.SPU.Write_Register (SPU, 16#1F801C08#, 16#1234#);
      PSX.SPU.Read_Register (SPU, 16#1F801C08#, Test_Value);
      Check (Test_Value = 16#1234#, "Voice 0 ADSR1 register");

      -- 2. Escribimos y leemos ADSR2 (ADSR High: 0x1F801C0A)
      PSX.SPU.Write_Register (SPU, 16#1F801C0A#, 16#5678#);
      PSX.SPU.Read_Register (SPU, 16#1F801C0A#, Test_Value);
      Check (Test_Value = 16#5678#, "Voice 0 ADSR2 register");

      -- 3. Verificación de Solo Lectura en ADSR_Level (0x1F801C0C)
      -- Intentamos sabotear el registro escribiendo un valor
      PSX.SPU.Write_Register (SPU, 16#1F801C0C#, 16#9ABC#);
      PSX.SPU.Read_Register (SPU, 16#1F801C0C#, Test_Value);
      Check (Test_Value = 0, "Voice 0 ADSR_Level is strict Read-Only");

      -- 4. Escribimos y leemos Repeat/Current Address (0x1F801C0E)
      PSX.SPU.Write_Register (SPU, 16#1F801C0E#, 16#2468#);
      PSX.SPU.Read_Register (SPU, 16#1F801C0E#, Test_Value);
      Check (Test_Value = 16#2468#, "Voice 0 Repeat Address register");
   end;


   New_Line;
   Put_Line ("SPU basic tests completed.");

end PSX_SPU_Tests;
