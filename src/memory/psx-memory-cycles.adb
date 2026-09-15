with PSX.Types;

package body PSX.Memory.Cycles is

   function Load_Cycles (Address : PSX.Types.Word32) return Natural is
   begin

      -- Scratchpad RAM
      -- 1F800000 - 1F8003FF
      if Address >= 16#1F80_0000# and then Address <= 16#1F80_03FF# then
         return 1;

      -- I/O registers
      -- 1F800400 - 1F80FFFF
      elsif Address >= 16#1F80_0400# and then Address <= 16#1F80_FFFF# then
         return 5;

      -- Main RAM
      -- 00000000 - 001FFFFF
      elsif Address <= 16#001F_FFFF# then
         return 7;

      -- BIOS ROM
      -- 1FC00000 - 1FC7FFFF
      -- BFC00000 - BFC7FFFF
      elsif (Address >= 16#1FC0_0000# and then Address <= 16#1FC7_FFFF#)
        or else (Address >= 16#BFC0_0000# and then Address <= 16#BFC7_FFFF#)
      then
         return 27;

      -- Unknown / unmapped area.
      else
         return 1;
      end if;

   end Load_Cycles;

end PSX.Memory.Cycles;

