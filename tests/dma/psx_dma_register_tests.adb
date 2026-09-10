with Interfaces;
with Ada.Text_IO;
with PSX.Memory;
with PSX.Types;

procedure PSX_DMA_REGISTER_TESTS is

   use type Interfaces.Unsigned_32;

   use Ada.Text_IO;

   Memory : PSX.Memory.Memory_State;
   Value  : PSX.Types.Word32;

begin
   Put_Line ("Testing PSX DMA registers...");

   PSX.Memory.Reset (Memory);

   --  DMA Channel 0 MADR
   PSX.Memory.Write_32 (Memory, 16#1F80_1080#, 16#0010_0000#);

   Value := PSX.Memory.Read_32 (Memory, 16#1F80_1080#);

   if Value = 16#0010_0000# then
      Put_Line ("PASS: DMA0 MADR");
   else
      Put_Line ("FAIL: DMA0 MADR");
   end if;

   --  DMA Channel 0 BCR
   PSX.Memory.Write_32 (Memory, 16#1F80_1084#, 16#0000_0010#);

   Value := PSX.Memory.Read_32 (Memory, 16#1F80_1084#);

   if Value = 16#0000_0010# then
      Put_Line ("PASS: DMA0 BCR");
   else
      Put_Line ("FAIL: DMA0 BCR");
   end if;

   --  DMA Channel 0 CHCR
   PSX.Memory.Write_32 (Memory, 16#1F80_1088#, 16#0100_0001#);

   Value := PSX.Memory.Read_32 (Memory, 16#1F80_1088#);

   if Value = 16#0100_0001# then
      Put_Line ("PASS: DMA0 CHCR");
   else
      Put_Line ("FAIL: DMA0 CHCR");
   end if;

   --  DPCR
   PSX.Memory.Write_32 (Memory, 16#1F80_10F0#, 16#0000_0008#);

   Value := PSX.Memory.Read_32 (Memory, 16#1F80_10F0#);

   if Value = 16#0000_0008# then
      Put_Line ("PASS: DMA DPCR");
   else
      Put_Line ("FAIL: DMA DPCR");
   end if;

   Put_Line ("DMA register tests finished.");

end PSX_DMA_REGISTER_TESTS;
