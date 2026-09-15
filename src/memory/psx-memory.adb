with Interfaces;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Text_IO;
with PSX.Timers;

package body PSX.Memory is

   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;

   function Translate_RAM_Address
     (Address : PSX.Types.Word32) return PSX.Types.Word32 is
   begin
      --  KUSEG
      if Address <= 16#007F_FFFF# then
         return Address and 16#001F_FFFF#;

      --  KSEG0
      elsif Address >= 16#8000_0000# and then Address <= 16#807F_FFFF# then
         return (Address - 16#8000_0000#) and 16#001F_FFFF#;

      --  KSEG1
      elsif Address >= 16#A000_0000# and then Address <= 16#A07F_FFFF# then
         return (Address - 16#A000_0000#) and 16#001F_FFFF#;

      else
         return 16#FFFF_FFFF#;
      end if;
   end Translate_RAM_Address;

   function Is_BIOS_Address (Address : PSX.Types.Word32) return Boolean is
   begin
      return
        (Address >= 16#1FC0_0000# and then Address <= 16#1FC7_FFFF#)
        or else (Address >= 16#BFC0_0000# and then Address <= 16#BFC7_FFFF#);
   end Is_BIOS_Address;

   function BIOS_Offset (Address : PSX.Types.Word32) return PSX.Types.Word32 is
   begin
      if Address >= 16#1FC0_0000# and then Address <= 16#1FC7_FFFF# then
         return Address - 16#1FC0_0000#;

      else
         return Address - 16#BFC0_0000#;
      end if;
   end BIOS_Offset;

   procedure Reset (Memory : out Memory_State) is
   begin
      Memory.Data := (others => 0);
      Memory.Scratchpad := (others => 0);
      Memory.BIOS := (others => 0);
      Memory.DMA_Registers := (others => 0);

      PSX.Timers.Reset (Memory.Timers);
   end Reset;

   function Read_8
     (Memory : Memory_State; Address : PSX.Types.Word32) return PSX.Types.Word8
   is
      Physical_Address : constant PSX.Types.Word32 :=
        Translate_RAM_Address (Address);
   begin

      --  RAM
      if Physical_Address /= 16#FFFF_FFFF# then
         return Memory.Data (Physical_Address);

      --  Scratchpad
      elsif Address >= 16#1F80_0000# and then Address <= 16#1F80_03FF# then
         return Memory.Scratchpad (Address - 16#1F80_0000#);

      --  BIOS
      elsif Is_BIOS_Address (Address) then
         return Memory.BIOS (BIOS_Offset (Address));

      --  Unmapped
      else
         return 0;
      end if;

   end Read_8;

   function Read_16
     (Memory : Memory_State; Address : PSX.Types.Word32)
      return PSX.Types.Word16
   is
      Low : constant PSX.Types.Word16 :=
        PSX.Types.Word16 (Read_8 (Memory, Address));

      High : constant PSX.Types.Word16 :=
        PSX.Types.Word16 (Read_8 (Memory, Address + 1));
   begin
      return Low or Interfaces.Shift_Left (High, 8);
   end Read_16;

   function Read_32
     (Memory : Memory_State; Address : PSX.Types.Word32)
      return PSX.Types.Word32
   is
      Timer_Base : constant PSX.Types.Word32 := 16#1F80_1100#;
      Timer_End  : constant PSX.Types.Word32 := 16#1F80_1128#;

      DMA_Base : constant PSX.Types.Word32 := 16#1F80_1080#;
      DMA_End  : constant PSX.Types.Word32 := 16#1F80_10FF#;

      Index : PSX.Types.Word32;
   begin

      --  Timers
      if Address >= Timer_Base and then Address <= Timer_End then

         Index := (Address - Timer_Base) / 16;

         case (Address - Timer_Base) mod 16 is

            when 0      =>
               return PSX.Timers.Read_Counter (Memory.Timers, Natural (Index));

            when 4      =>
               return PSX.Timers.Read_Mode (Memory.Timers, Natural (Index));

            when 8      =>
               return PSX.Timers.Read_Target (Memory.Timers, Natural (Index));

            when others =>
               return 0;

         end case;

      --  DMA
      elsif Address >= DMA_Base and then Address <= DMA_End then

         Index := (Address - DMA_Base) / 4;
         return Memory.DMA_Registers (Index);

      --  RAM / BIOS / Scratchpad / Unmapped
      else

         declare
            B0 : constant PSX.Types.Word32 :=
              PSX.Types.Word32 (Read_8 (Memory, Address));

            B1 : constant PSX.Types.Word32 :=
              PSX.Types.Word32 (Read_8 (Memory, Address + 1));

            B2 : constant PSX.Types.Word32 :=
              PSX.Types.Word32 (Read_8 (Memory, Address + 2));

            B3 : constant PSX.Types.Word32 :=
              PSX.Types.Word32 (Read_8 (Memory, Address + 3));
         begin
            return
              B0
              or Interfaces.Shift_Left (B1, 8)
              or Interfaces.Shift_Left (B2, 16)
              or Interfaces.Shift_Left (B3, 24);
         end;

      end if;

   end Read_32;

   procedure Write_8
     (Memory  : in out Memory_State;
      Address : PSX.Types.Word32;
      Value   : PSX.Types.Word8)
   is
      Physical_Address : constant PSX.Types.Word32 :=
        Translate_RAM_Address (Address);
   begin

      --  RAM
      if Physical_Address /= 16#FFFF_FFFF# then
         Memory.Data (Physical_Address) := Value;

      --  Scratchpad
      elsif Address >= 16#1F80_0000# and then Address <= 16#1F80_03FF# then
         Memory.Scratchpad (Address - 16#1F80_0000#) := Value;

      --  BIOS
      --  Escritura ignorada: la BIOS es ROM.
      elsif Is_BIOS_Address (Address) then
         null;

      --  Unmapped
      else
         null;
      end if;

   end Write_8;

   procedure Write_16
     (Memory  : in out Memory_State;
      Address : PSX.Types.Word32;
      Value   : PSX.Types.Word16) is
   begin
      Write_8 (Memory, Address, PSX.Types.Word8 (Value and 16#00FF#));

      Write_8
        (Memory,
         Address + 1,
         PSX.Types.Word8 (Interfaces.Shift_Right (Value, 8)));
   end Write_16;

   procedure Write_32
     (Memory  : in out Memory_State;
      Address : PSX.Types.Word32;
      Value   : PSX.Types.Word32)
   is
      Timer_Base : constant PSX.Types.Word32 := 16#1F80_1100#;
      Timer_End  : constant PSX.Types.Word32 := 16#1F80_1128#;

      DMA_Base : constant PSX.Types.Word32 := 16#1F80_1080#;
      DMA_End  : constant PSX.Types.Word32 := 16#1F80_10FF#;

      Index : PSX.Types.Word32;
   begin

      --  Timers
      if Address >= Timer_Base and then Address <= Timer_End then

         Index := (Address - Timer_Base) / 16;

         case (Address - Timer_Base) mod 16 is

            when 0      =>
               PSX.Timers.Write_Counter
                 (Memory.Timers, Natural (Index), Value);

            when 4      =>
               PSX.Timers.Write_Mode (Memory.Timers, Natural (Index), Value);

            when 8      =>
               PSX.Timers.Write_Target (Memory.Timers, Natural (Index), Value);

            when others =>
               null;

         end case;

      --  DMA
      elsif Address >= DMA_Base and then Address <= DMA_End then

         Index := (Address - DMA_Base) / 4;
         Memory.DMA_Registers (Index) := Value;

      --  RAM / BIOS / Scratchpad / Unmapped
      else

         declare
            B0 : constant PSX.Types.Word8 :=
              PSX.Types.Word8 (Value and 16#FF#);

            B1 : constant PSX.Types.Word8 :=
              PSX.Types.Word8 (Interfaces.Shift_Right (Value, 8) and 16#FF#);

            B2 : constant PSX.Types.Word8 :=
              PSX.Types.Word8 (Interfaces.Shift_Right (Value, 16) and 16#FF#);

            B3 : constant PSX.Types.Word8 :=
              PSX.Types.Word8 (Interfaces.Shift_Right (Value, 24) and 16#FF#);
         begin
            Write_8 (Memory, Address, B0);
            Write_8 (Memory, Address + 1, B1);
            Write_8 (Memory, Address + 2, B2);
            Write_8 (Memory, Address + 3, B3);
         end;

      end if;

   end Write_32;

   procedure Load_BIOS (Memory : in out Memory_State; Path : String) is

      use Ada.Streams;
      use Ada.Streams.Stream_IO;

      File      : File_Type;
      Buffer    : Stream_Element_Array (1 .. 4096);
      Last      : Stream_Element_Offset;
      Position  : Stream_Element_Offset := 0;
      BIOS_Size : constant Stream_Element_Offset := 16#0008_0000#;

   begin
      Open (File => File, Mode => In_File, Name => Path);

      while not End_Of_File (File) loop

         Read (File => File, Item => Buffer, Last => Last);

         for I in Buffer'First .. Last loop

            if Position >= BIOS_Size then
               Close (File);
               raise Program_Error with "BIOS file is larger than 512 KiB";
            end if;

            Memory.BIOS (PSX.Types.Word32 (Position)) :=
              PSX.Types.Word8 (Buffer (I));

            Position := Position + 1;

         end loop;

      end loop;

      Close (File);

      if Position /= BIOS_Size then
         raise Program_Error with "BIOS file must be exactly 512 KiB";
      end if;

   exception
      when others =>
         if Is_Open (File) then
            Close (File);
         end if;

         raise;
   end Load_BIOS;

end PSX.Memory;
