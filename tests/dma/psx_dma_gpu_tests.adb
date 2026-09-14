with Ada.Text_IO;
with PSX.DMA;
with PSX.GPU;
with PSX.Memory;
with PSX.Types;

procedure PSX_DMA_GPU_TESTS is

   use Ada.Text_IO;
   use type PSX.Types.Word32;
   use type PSX.Types.Word16;

   Memory : PSX.Memory.Memory_State;
   GPU    : PSX.GPU.GPU_State;

   Source_Address : constant PSX.Types.Word32 := 16#0001_0000#;

begin

   Put_Line ("Testing PSX DMA GPU...");

   PSX.Memory.Reset (Memory);
   PSX.GPU.Reset (GPU);

   --  GPU DMA Channel 2
   --
   --  Source RAM:
   --  0x10000
   --
   --  Transfer:
   --  3 words
   --
   --  A0 command:
   --  X=100, Y=200
   PSX.Memory.Write_32 (Memory, Source_Address, 16#A0C8_0064#);

   --  Width=2, Height=1
   PSX.Memory.Write_32 (Memory, Source_Address + 4, 16#0001_0002#);

   --  Pixel 0 = 7C00
   --  Pixel 1 = 03E0
   PSX.Memory.Write_32 (Memory, Source_Address + 8, 16#03E0_7C00#);

   --  MADR
   PSX.Memory.Write_32 (Memory, 16#1F80_10A0#, Source_Address);

   --  BCR = 3 words
   PSX.Memory.Write_32 (Memory, 16#1F80_10A4#, 16#0000_0003#);

   --  CHCR = active, RAM -> GPU, manual mode
   PSX.Memory.Write_32 (Memory, 16#1F80_10A8#, 16#0100_0000#);

   --  Execute DMA
   PSX.DMA.Process (Memory, GPU);

   --  Verify VRAM
   if PSX.GPU.Read_VRAM (GPU, 100, 200) = 16#7C00# then
      Put_Line ("PASS: DMA GPU pixel 0");
   else
      Put_Line ("FAIL: DMA GPU pixel 0");
   end if;

   if PSX.GPU.Read_VRAM (GPU, 101, 200) = 16#03E0# then
      Put_Line ("PASS: DMA GPU pixel 1");
   else
      Put_Line ("FAIL: DMA GPU pixel 1");
   end if;

   --  Verify DMA completed
   if (PSX.Memory.Read_32 (Memory, 16#1F80_10A8#) and 16#0100_0000#) = 0 then
      Put_Line ("PASS: GPU DMA completed");
   else
      Put_Line ("FAIL: GPU DMA still active");
   end if;

   Put_Line ("DMA GPU tests finished.");

end PSX_DMA_GPU_TESTS;
