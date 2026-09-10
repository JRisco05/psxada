with Interfaces;
with PSX.Memory;

package body PSX.DMA is

   use type Interfaces.Unsigned_32;

   DMA_BASE : constant Word32 := 16#1F80_1080#;

   DMA6_MADR : constant Word32 := DMA_BASE + 16#60#;
   DMA6_BCR  : constant Word32 := DMA_BASE + 16#64#;
   DMA6_CHCR : constant Word32 := DMA_BASE + 16#68#;

   procedure Reset (Memory : in out PSX.Memory.Memory_State) is
   begin
      Memory.DMA_Registers := (others => 0);
   end Reset;

   function Read_DMA_Register
     (Memory : PSX.Memory.Memory_State; Address : Word32) return Word32 is
   begin
      return Memory.DMA_Registers ((Address - DMA_BASE) / 4);
   end Read_DMA_Register;

   procedure Write_DMA_Register
     (Memory  : in out PSX.Memory.Memory_State;
      Address : Word32;
      Value   : Word32) is
   begin
      Memory.DMA_Registers ((Address - DMA_BASE) / 4) := Value;
   end Write_DMA_Register;

   procedure Process_OTC (Memory : in out PSX.Memory.Memory_State) is
      MADR : Word32;
      BCR  : Word32;
      CHCR : Word32;

      Address : Word32;
      Count   : Word32;
      Next    : Word32;
   begin
      MADR := Read_DMA_Register (Memory, DMA6_MADR);
      BCR := Read_DMA_Register (Memory, DMA6_BCR);
      CHCR := Read_DMA_Register (Memory, DMA6_CHCR);

      --  Channel 6 must be active.
      if (CHCR and 16#0100_0000#) = 0 then
         return;
      end if;

      --  OTC uses manual mode.
      if ((CHCR and 16#0000_0600#) /= 0) then
         return;
      end if;

      --  Number of words to transfer.
      Count := BCR and 16#0000_FFFF#;

      if Count = 0 then
         return;
      end if;

      Address := MADR;

      while Count > 1 loop

         Next := Address - 4;

         PSX.Memory.Write_32 (Memory, Address, Next);

         Address := Next;
         Count := Count - 1;

      end loop;

      --  Last OTC entry terminates the linked list.
      PSX.Memory.Write_32 (Memory, Address, 16#00FF_FFFF#);

      --  DMA finished.
      CHCR := CHCR and not 16#0100_0000#;

      Write_DMA_Register (Memory, DMA6_CHCR, CHCR);

   end Process_OTC;

   procedure Process (Memory : in out PSX.Memory.Memory_State) is
      CHCR : Word32;
   begin
      CHCR := Read_DMA_Register (Memory, DMA6_CHCR);

      if (CHCR and 16#0100_0000#) /= 0 then
         Process_OTC (Memory);
      end if;
   end Process;

end PSX.DMA;
