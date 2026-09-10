with Interfaces;
with PSX.Memory;

package body PSX.DMA is

   use type Interfaces.Unsigned_32;

   procedure Reset (DMA : out DMA_State) is
   begin
      DMA.Channels :=
        (others =>
           (Base_Address => 0, Block_Control => 0, Channel_Control => 0));

      DMA.DPCR := 0;
      DMA.DICR := 0;
   end Reset;

   function Channel_Enabled (DMA : DMA_State; Index : Natural) return Boolean
   is
      Shift : constant Natural := Index * 4;
   begin
      return (Interfaces.Shift_Right (DMA.DPCR, Shift) and 16#8#) /= 0;
   end Channel_Enabled;

   function Channel_Active (DMA : DMA_State; Index : Natural) return Boolean is
   begin
      return (DMA.Channels (Index).Channel_Control and 16#0100_0000#) /= 0;
   end Channel_Active;

   function Sync_Mode (DMA : DMA_State; Index : Natural) return Word32 is
   begin
      return
        Interfaces.Shift_Right (DMA.Channels (Index).Channel_Control, 9)
        and 16#3#;
   end Sync_Mode;

   function Block_Size (DMA : DMA_State; Index : Natural) return Word32 is
   begin
      return DMA.Channels (Index).Block_Control and 16#FFFF#;
   end Block_Size;

   function Block_Count (DMA : DMA_State; Index : Natural) return Word32 is
   begin
      return Interfaces.Shift_Right (DMA.Channels (Index).Block_Control, 16);
   end Block_Count;

   procedure Transfer_Channel
     (DMA    : in out DMA_State;
      Memory : in out PSX.Memory.Memory_State;
      Index  : Natural)
   is
      Channel : DMA_Channel renames DMA.Channels (Index);

      Address : Word32 := Channel.Base_Address;
      Count   : Word32 := 0;
      Total   : Word32 := 0;

      Step : Word32 := 4;
   begin

      --  Only implement normal CPU-memory transfers for now.
      --  This gives us the foundation for the real DMA controller.

      if Sync_Mode (DMA, Index) /= 0 then
         return;
      end if;

      if Block_Size (DMA, Index) = 0 then
         return;
      end if;

      Total := Block_Size (DMA, Index);

      while Count < Total loop

         --  DMA direction:
         --  bit 0 = 0 : device -> RAM
         --  bit 0 = 1 : RAM -> device
         --
         --  Device endpoints are not implemented yet.
         --  Therefore, for now, only safely consume the DMA request.

         if (Channel.Channel_Control and 16#1#) = 0 then
            null;
         else
            null;
         end if;

         Count := Count + 1;
         Address := Address + Step;

      end loop;

      --  Clear START/ACTIVE.
      Channel.Channel_Control := Channel.Channel_Control and not 16#0100_0000#;

   end Transfer_Channel;

   procedure Process
     (DMA : in out DMA_State; Memory : in out PSX.Memory.Memory_State) is
   begin

      for I in 0 .. Channel_Count - 1 loop

         if Channel_Enabled (DMA, I) and then Channel_Active (DMA, I) then
            Transfer_Channel (DMA, Memory, I);
         end if;

      end loop;

   end Process;

end PSX.DMA;
