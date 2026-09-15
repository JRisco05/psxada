with Interfaces;

package body PSX.GPU is

   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;

   procedure Reset (GPU : out GPU_State) is
   begin
      GPU.GP0 := 0;
      GPU.GP1 := 0;
      GPU.Status := 0;
      GPU.VRAM := (others => 0);

      GPU.GP0_Command := 0;
      GPU.GP0_Expected_Words := 0;
      GPU.GP0_Received_Words := 0;
      GPU.GP0_Data := (others => 0);

      GPU.GP0_X := 0;
      GPU.GP0_Y := 0;
      GPU.GP0_Width := 0;
      GPU.GP0_Height := 0;

      GPU.GP0_Read_Active := False;
      GPU.GP0_Read_X := 0;
      GPU.GP0_Read_Y := 0;
      GPU.GP0_Read_Width := 0;
      GPU.GP0_Read_Height := 0;
      GPU.GP0_Read_Index := 0;

      GPU.GP0_Color := 0;

   end Reset;

   procedure Write_GP0 (GPU : in out GPU_State; Value : Word32) is
      Command : constant Word8 := Word8 (Interfaces.Shift_Right (Value, 24));

      Pixel_Index : Natural;
      Pixel_X     : Natural;
      Pixel_Y     : Natural;

      -- Variables temporales para el bucle de dibujo del comando 02
      Fill_X, Fill_Y, Fill_W, Fill_H : Natural;
      Color_16                       : Word16;

   begin
      GPU.GP0 := Value;

      --------------------------------------------------------------
      -- C0: VRAM -> CPU (Segunda palabra: Ancho y Alto)
      --------------------------------------------------------------
      if GPU.GP0_Command = 16#C0# and then GPU.GP0_Received_Words = 1 then

         GPU.GP0_Data (1) := Value;

         GPU.GP0_Read_Width := Natural (Value and 16#0000_FFFF#);
         GPU.GP0_Read_Height :=
           Natural (Interfaces.Shift_Right (Value, 16) and 16#0000_FFFF#);

         GPU.GP0_Read_Index := 0;
         GPU.GP0_Read_Active := True;

         GPU.GP0_Command := 0;
         GPU.GP0_Expected_Words := 0;
         GPU.GP0_Received_Words := 0;

         return;
      end if;

      --------------------------------------------------------------
      -- A0: CPU -> VRAM (Segunda palabra: Ancho y Alto)
      --------------------------------------------------------------
      if GPU.GP0_Command = 16#A0# and then GPU.GP0_Received_Words = 1 then

         GPU.GP0_Data (1) := Value;

         GPU.GP0_Width := Natural (Value and 16#0000_FFFF#);
         GPU.GP0_Height :=
           Natural (Interfaces.Shift_Right (Value, 16) and 16#0000_FFFF#);

         GPU.GP0_Expected_Words :=
           2 + ((GPU.GP0_Width * GPU.GP0_Height + 1) / 2);
         GPU.GP0_Received_Words := 2;

         return;
      end if;

      --------------------------------------------------------------
      -- 02: Relleno de Rectángulo rápido (Segunda palabra: X e Y)
      --------------------------------------------------------------
      if GPU.GP0_Command = 16#02# and then GPU.GP0_Received_Words = 1 then

         GPU.GP0_Data (1) := Value;
         GPU.GP0_X := Natural (Value and 16#0000_03FF#);
         GPU.GP0_Y :=
           Natural (Interfaces.Shift_Right (Value, 16) and 16#0000_01FF#);

         GPU.GP0_Received_Words := 2;
         return;
      end if;

      --------------------------------------------------------------
      -- 02: Relleno de Rectángulo rápido (Tercera palabra: Ancho y Alto)
      -- ¡Aquí es donde se ejecuta el dibujo!
      --------------------------------------------------------------
      if GPU.GP0_Command = 16#02# and then GPU.GP0_Received_Words = 2 then

         GPU.GP0_Data (2) := Value;
         GPU.GP0_Width := Natural (Value and 16#0000_FFFF#);
         GPU.GP0_Height :=
           Natural (Interfaces.Shift_Right (Value, 16) and 16#0000_FFFF#);

         -- SOLUCIÓN: Tomamos los 16 bits bajos del color guardado de forma directa
         Color_16 := Word16 (GPU.GP0_Color and 16#FFFF#);

         -- Dibujamos el rectángulo completo en la VRAM píxel por píxel
         for Y_Offset in 0 .. GPU.GP0_Height - 1 loop
            for X_Offset in 0 .. GPU.GP0_Width - 1 loop
               Fill_X := (GPU.GP0_X + X_Offset) mod VRAM_WIDTH;
               Fill_Y := (GPU.GP0_Y + Y_Offset) mod VRAM_HEIGHT;
               Write_VRAM (GPU, Fill_X, Fill_Y, Color_16);
            end loop;
         end loop;

         -- Limpiamos estado
         GPU.GP0_Command := 0;
         GPU.GP0_Expected_Words := 0;
         GPU.GP0_Received_Words := 0;

         return;
      end if;

      --------------------------------------------------------------
      -- A0: Recepción de datos de píxeles (Tercera palabra en adelante)
      --------------------------------------------------------------
      if GPU.GP0_Command = 16#A0#
        and then GPU.GP0_Received_Words >= 2
        and then GPU.GP0_Received_Words < GPU.GP0_Expected_Words
      then

         Pixel_Index := (GPU.GP0_Received_Words - 2) * 2;

         if Pixel_Index < GPU.GP0_Width * GPU.GP0_Height then
            Pixel_X := GPU.GP0_X + (Pixel_Index mod GPU.GP0_Width);
            Pixel_Y := GPU.GP0_Y + (Pixel_Index / GPU.GP0_Width);

            Write_VRAM
              (GPU,
               Pixel_X mod VRAM_WIDTH,
               Pixel_Y mod VRAM_HEIGHT,
               Word16 (Value and 16#0000_FFFF#));
         end if;

         if Pixel_Index + 1 < GPU.GP0_Width * GPU.GP0_Height then
            Pixel_X := GPU.GP0_X + ((Pixel_Index + 1) mod GPU.GP0_Width);
            Pixel_Y := GPU.GP0_Y + ((Pixel_Index + 1) / GPU.GP0_Width);

            Write_VRAM
              (GPU,
               Pixel_X mod VRAM_WIDTH,
               Pixel_Y mod VRAM_HEIGHT,
               Word16 (Interfaces.Shift_Right (Value, 16) and 16#0000_FFFF#));
         end if;

         GPU.GP0_Received_Words := GPU.GP0_Received_Words + 1;

         if GPU.GP0_Received_Words = GPU.GP0_Expected_Words then
            GPU.GP0_Command := 0;
            GPU.GP0_Expected_Words := 0;
            GPU.GP0_Received_Words := 0;
         end if;

         return;
      end if;

      --------------------------------------------------------------
      -- Inicio de un nuevo comando GP0 (Primera palabra)
      --------------------------------------------------------------
      if GPU.GP0_Expected_Words = 0 then

         GPU.GP0_Command := Command;
         GPU.GP0_Received_Words := 1;
         GPU.GP0_Data (0) := Value;

         if Command = 16#02# then
            -- Guardamos los bits de color de la primera palabra (RGB)
            GPU.GP0_Color := Value and 16#00FF_FFFF#;
            GPU.GP0_Expected_Words := 3;

         elsif Command = 16#A0# then
            GPU.GP0_X := Natural (Value and 16#0000_03FF#);
            GPU.GP0_Y :=
              Natural (Interfaces.Shift_Right (Value, 16) and 16#0000_01FF#);
            GPU.GP0_Expected_Words := 3;

         elsif Command = 16#C0# then
            -- RESTAURADO: Extraemos correctamente origen X e Y en el comando C0
            GPU.GP0_Read_X := Natural (Value and 16#0000_03FF#);
            GPU.GP0_Read_Y :=
              Natural (Interfaces.Shift_Right (Value, 16) and 16#0000_01FF#);
            GPU.GP0_Expected_Words := 2;

         else
            GPU.GP0_Expected_Words := 1;
         end if;

      end if;

   end Write_GP0;

   function Read_GP0 (GPU : in out GPU_State) return Word32 is
      Pixel_Index : Natural;
      Pixel_X     : Natural;
      Pixel_Y     : Natural;
      Pixel_0     : Word16;
      Pixel_1     : Word16;
      Result      : Word32;
   begin

      if not GPU.GP0_Read_Active then
         return 0;
      end if;

      Pixel_Index := GPU.GP0_Read_Index * 2;

      Pixel_X := GPU.GP0_Read_X + (Pixel_Index mod GPU.GP0_Read_Width);
      Pixel_Y := GPU.GP0_Read_Y + (Pixel_Index / GPU.GP0_Read_Width);

      Pixel_0 :=
        Read_VRAM (GPU, Pixel_X mod VRAM_WIDTH, Pixel_Y mod VRAM_HEIGHT);

      if Pixel_Index + 1 < GPU.GP0_Read_Width * GPU.GP0_Read_Height then
         Pixel_X :=
           GPU.GP0_Read_X + ((Pixel_Index + 1) mod GPU.GP0_Read_Width);
         Pixel_Y := GPU.GP0_Read_Y + ((Pixel_Index + 1) / GPU.GP0_Read_Width);

         Pixel_1 :=
           Read_VRAM (GPU, Pixel_X mod VRAM_WIDTH, Pixel_Y mod VRAM_HEIGHT);
      else
         Pixel_1 := 0;
      end if;

      Result :=
        Word32 (Pixel_0) or Interfaces.Shift_Left (Word32 (Pixel_1), 16);

      GPU.GP0_Read_Index := GPU.GP0_Read_Index + 1;

      if GPU.GP0_Read_Index
        >= ((GPU.GP0_Read_Width * GPU.GP0_Read_Height + 1) / 2)
      then
         GPU.GP0_Read_Active := False;
         GPU.GP0_Read_Index := 0;
      end if;

      return Result;
   end Read_GP0;

   procedure Write_GP1 (GPU : in out GPU_State; Value : Word32) is
   begin
      GPU.GP1 := Value;
   end Write_GP1;

   function Read_Status (GPU : GPU_State) return Word32 is
   begin
      return GPU.Status;
   end Read_Status;

   procedure Write_VRAM
     (GPU : in out GPU_State; X : Natural; Y : Natural; Value : Word16)
   is
      Index : constant Natural := Y * VRAM_WIDTH + X;
   begin
      if X < VRAM_WIDTH and then Y < VRAM_HEIGHT then
         GPU.VRAM (Index) := Value;
      end if;
   end Write_VRAM;

   function Read_VRAM (GPU : GPU_State; X : Natural; Y : Natural) return Word16
   is
      Index : constant Natural := Y * VRAM_WIDTH + X;
   begin
      if X < VRAM_WIDTH and then Y < VRAM_HEIGHT then
         return GPU.VRAM (Index);
      end if;
      return 0;
   end Read_VRAM;

end PSX.GPU;
