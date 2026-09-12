with Interfaces;
with PSX.Types;

package body PSX.GPU is

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
   end Reset;

   procedure Write_GP0 (GPU : in out GPU_State; Value : Word32) is
      Command : constant Word8 := Word8 (Interfaces.Shift_Right (Value, 24));
   begin
      GPU.GP0 := Value;

      --  A new GP0 command starts when no command
      --  is currently being received.
      if GPU.GP0_Expected_Words = 0 then

         GPU.GP0_Command := Command;
         GPU.GP0_Received_Words := 1;
         GPU.GP0_Data (0) := Value;

         case Command is

            --  CPU -> VRAM

            when 16#A0# =>
               GPU.GP0_Expected_Words := 3;

            when others =>
               GPU.GP0_Expected_Words := 1;

         end case;

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
