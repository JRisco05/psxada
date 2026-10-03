with Ada.Text_IO;
with PSX.Display;
with PSX.State;
with PSX.GPU;
with PSX.Types;
with Interfaces;
with System;

procedure Psxada is

   use Ada.Text_IO;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;

   -- El estado global de tu consola (contiene CPU, Memoria, GPU, etc.)
   PSX_System : PSX.State.PSX_State;

   -- Dimensiones de la VRAM real de la PS1
   Width  : constant := 1024;
   Height : constant := 512;

   -- Buffer de 32 bits que Metal necesita para pintar en tu Mac M2
   subtype Output_Index is Integer range 0 .. (Width * Height) - 1;
   Metal_Buffer : array (Output_Index) of PSX.Types.Word32;

   VRAM_Pixel : PSX.Types.Word16;
   R, G, B    : PSX.Types.Word32;

begin
   Put_Line ("Inicializando Emulador PSXADA...");
   PSX.State.Reset (PSX_System);

   -- 1. Abrimos tu ventana nativa de Metal adaptada al tamaño de la VRAM
   PSX.Display.Initialize_Window (Width, Height);

   Put_Line ("Ejecutando bucle principal de refresco de hardware...");

   -- 2. El bucle infinito del emulador controlado por la interfaz gráfica
   while PSX.Display.Process_Events = 1 loop

      ----------------------------------------------------------------
      -- 🌟 AQUÍ CORRERÍA TU PIPELINE EN CADA FRAME:
      --
      --  for Cycle in 1 .. 100_000 loop
      --     PSX.CPU.Step(PSX_System); -- Ejecuta instrucciones de la BIOS
      --  end loop;
      ----------------------------------------------------------------

      -- 3. CONVERSIÓN CRÍTICA: Traducimos la VRAM de la PS1 (16-bit) a Metal (32-bit BGRA)
      for Y in 0 .. Height - 1 loop
         for X in 0 .. Width - 1 loop
            -- Leemos el pixel actual directamente de tu estructura de la GPU
            VRAM_Pixel := PSX.GPU.Read_VRAM (PSX_System.GPU, X, Y);

            -- Desempaquetamos los componentes RGB de 5 bits de la PS1
            R := PSX.Types.Word32 (VRAM_Pixel and 16#001F#);
            G :=
              PSX.Types.Word32
                (Interfaces.Shift_Right (VRAM_Pixel, 5) and 16#001F#);
            B :=
              PSX.Types.Word32
                (Interfaces.Shift_Right (VRAM_Pixel, 10) and 16#001F#);

            -- Escalamos los colores de 5 bits (0..31) al rango de 8 bits de Metal (0..255)
            R := Interfaces.Shift_Left (R, 3);
            G := Interfaces.Shift_Left (G, 3);
            B := Interfaces.Shift_Left (B, 3);

            -- Ensamblamos el pixel definitivo en formato BGRA (8 bits por canal + Alfa opaco)
            Metal_Buffer (Y * Width + X) :=
              B
              or Interfaces.Shift_Left (G, 8)
              or Interfaces.Shift_Left (R, 16)
              or 16#FF00_0000#; -- Alfa opaco
         end loop;
      end loop;

      -- 4. Subimos la VRAM real convertida a la GPU de tu Mac M2
      PSX.Display.Update_Frame (Metal_Buffer'Address, Metal_Buffer'Size);

      -- Sincronizamos el refresco vertical de la pantalla (~60 FPS)
      delay 0.016;
   end loop;

   Put_Line ("Emulador cerrado correctamente.");

   -- Prueba inyectando un rectángulo rojo simulando la BIOS:
   PSX.GPU.Write_GP0
     (PSX_System.GPU, 16#02_00_7C_00#); -- Comando 02 (Color Rojo)
   PSX.GPU.Write_GP0 (PSX_System.GPU, 16#0000_0000#);    -- X=0, Y=0
   PSX.GPU.Write_GP0 (PSX_System.GPU, 16#0100_0100#);    -- Ancho=256, Alto=256

end Psxada;
