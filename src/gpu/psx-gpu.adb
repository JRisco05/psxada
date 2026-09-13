with Interfaces;

package body PSX.GPU is

   use type Interfaces.Unsigned_8;
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

   end Reset;

   procedure Write_GP0 (GPU : in out GPU_State; Value : Word32) is
      Command : constant Word8 := Word8 (Interfaces.Shift_Right (Value, 24));

      Pixel_Index : Natural;
      Pixel_X     : Natural;
      Pixel_Y     : Natural;

   begin
      GPU.GP0 := Value;

      -- Segundo word del comando A0:
      -- bits 0..9   = width
      -- bits 16..24 = height
      if GPU.GP0_Command = 16#A0# and then GPU.GP0_Received_Words = 1 then

         GPU.GP0_Data (1) := Value;

         GPU.GP0_Width := Natural (Value and 16#0000_03FF#);

         GPU.GP0_Height :=
           Natural (Interfaces.Shift_Right (Value, 16) and 16#0000_01FF#);

         -- Total de words del comando:
         -- 1 command + 1 XY + pixel data.
         GPU.GP0_Expected_Words :=
           2 + ((GPU.GP0_Width * GPU.GP0_Height + 1) / 2);

         GPU.GP0_Received_Words := 2;

         return;
      end if;

      -- Recepción de datos de píxeles del comando A0.
      if GPU.GP0_Command = 16#A0#
        and then GPU.GP0_Received_Words >= 2
        and then GPU.GP0_Received_Words < GPU.GP0_Expected_Words
      then

         Pixel_Index := (GPU.GP0_Received_Words - 2) * 2;

         -- Pixel 1: bits 0..15
         if Pixel_Index < GPU.GP0_Width * GPU.GP0_Height then

            Pixel_X := GPU.GP0_X + (Pixel_Index mod GPU.GP0_Width);

            Pixel_Y := GPU.GP0_Y + (Pixel_Index / GPU.GP0_Width);

            Write_VRAM
              (GPU,
               Pixel_X mod VRAM_WIDTH,
               Pixel_Y mod VRAM_HEIGHT,
               Word16 (Value and 16#0000_FFFF#));

         end if;

         -- Pixel 2: bits 16..31
         if Pixel_Index + 1 < GPU.GP0_Width * GPU.GP0_Height then

            Pixel_X := GPU.GP0_X + ((Pixel_Index + 1) mod GPU.GP0_Width);

            Pixel_Y := GPU.GP0_Y + ((Pixel_Index + 1) / GPU.GP0_Width);

            Write_VRAM
              (GPU,
               Pixel_X mod VRAM_WIDTH,
               Pixel_Y mod VRAM_HEIGHT,
               Word16 (Interfaces.Shift_Right (Value, 16)));

         end if;

         GPU.GP0_Received_Words := GPU.GP0_Received_Words + 1;

         -- Transferencia terminada.
         if GPU.GP0_Received_Words = GPU.GP0_Expected_Words then
            GPU.GP0_Command := 0;
            GPU.GP0_Expected_Words := 0;
            GPU.GP0_Received_Words := 0;
         end if;

         return;
      end if;

      -- Inicio de un nuevo comando GP0.
      if GPU.GP0_Expected_Words = 0 then

         GPU.GP0_Command := Command;
         GPU.GP0_Received_Words := 1;
         GPU.GP0_Data (0) := Value;

         if Command = 16#A0# then

            GPU.GP0_X := Natural (Value and 16#0000_03FF#);

            GPU.GP0_Y :=
              Natural (Interfaces.Shift_Right (Value, 16) and 16#0000_01FF#);

            GPU.GP0_Expected_Words := 3;

         else
            GPU.GP0_Expected_Words := 1;
         end if;

      end if;

   end Write_GP0;

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
