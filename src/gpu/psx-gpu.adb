package body PSX.GPU is

   procedure Reset (GPU : out GPU_State) is
   begin
      GPU.GP0 := 0;
      GPU.GP1 := 0;
      GPU.Status := 0;
      GPU.VRAM := (others => 0);
   end Reset;

   procedure Write_GP0 (GPU : in out GPU_State; Value : Word32) is
   begin
      GPU.GP0 := Value;
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
