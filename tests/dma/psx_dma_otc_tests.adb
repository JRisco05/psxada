with Ada.Text_IO;
with PSX.DMA;
with PSX.Memory;
with PSX.Types;

procedure PSX_DMA_OTC_TESTS is

   use Ada.Text_IO;
   use type PSX.Types.Word32;

   Memory : PSX.Memory.Memory_State;

   Start_Address : constant PSX.Types.Word32 := 16#0001_000C#;

   Value : PSX.Types.Word32;

begin
   Put_Line ("Testing PSX DMA OTC...");

   PSX.Memory.Reset (Memory);

   --  DMA channel 6
   --  MADR = start address
   PSX.Memory.Write_32 (Memory, 16#1F80_10E0#, Start_Address);

   --  BCR = 4 words
   PSX.Memory.Write_32 (Memory, 16#1F80_10E4#, 16#0000_0004#);

   --  CHCR = active, decrement
   PSX.Memory.Write_32 (Memory, 16#1F80_10E8#, 16#0100_0002#);

   --  Execute DMA
   PSX.DMA.Process (Memory);

   --  Expected OTC chain:
   --
   --  0x1000C -> 0x10008
   --  0x10008 -> 0x10004
   --  0x10004 -> 0x10000
   --  0x10000 -> 0x00FFFFFF

   Value := PSX.Memory.Read_32 (Memory, 16#0001_000C#);

   if Value = 16#0001_0008# then
      Put_Line ("PASS: OTC entry 0");
   else
      Put_Line ("FAIL: OTC entry 0");
   end if;

   Value := PSX.Memory.Read_32 (Memory, 16#0001_0008#);

   if Value = 16#0001_0004# then
      Put_Line ("PASS: OTC entry 1");
   else
      Put_Line ("FAIL: OTC entry 1");
   end if;

   Value := PSX.Memory.Read_32 (Memory, 16#0001_0004#);

   if Value = 16#0001_0000# then
      Put_Line ("PASS: OTC entry 2");
   else
      Put_Line ("FAIL: OTC entry 2");
   end if;

   Value := PSX.Memory.Read_32 (Memory, 16#0001_0000#);

   if Value = 16#00FF_FFFF# then
      Put_Line ("PASS: OTC terminator");
   else
      Put_Line ("FAIL: OTC terminator");
   end if;

   Value := PSX.Memory.Read_32 (Memory, 16#1F80_10E8#);

   if (Value and 16#0100_0000#) = 0 then
      Put_Line ("PASS: OTC DMA completed");
   else
      Put_Line ("FAIL: OTC DMA still active");
   end if;

   Put_Line ("DMA OTC tests finished.");

end PSX_DMA_OTC_TESTS;
