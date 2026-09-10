with Interfaces;
with Ada.Text_IO;
with PSX.Memory;
with PSX.Types;

use type Interfaces.Unsigned_8;
use type Interfaces.Unsigned_16;
use type Interfaces.Unsigned_32;

procedure PSX_Memory_Tests is

   use Ada.Text_IO;

   Memory : PSX.Memory.Memory_State;

   procedure Check (Condition : Boolean; Name : String) is
   begin
      if Condition then
         Put_Line ("PASS: " & Name);
      else
         Put_Line ("FAIL: " & Name);
         raise Program_Error;
      end if;
   end Check;

begin

   Put_Line ("Testing PSX.Memory...");
   New_Line;

   PSX.Memory.Reset (Memory);

   --  Write/Read 8
   PSX.Memory.Write_8 (Memory, 16#0001_0000#, 16#AB#);

   Check (PSX.Memory.Read_8 (Memory, 16#0001_0000#) = 16#AB#, "Write/Read 8");

   --  Write/Read 16
   PSX.Memory.Write_16 (Memory, 16#0001_0010#, 16#1234#);

   Check
     (PSX.Memory.Read_16 (Memory, 16#0001_0010#) = 16#1234#, "Write/Read 16");

   --  Write/Read 32
   PSX.Memory.Write_32 (Memory, 16#0001_0020#, 16#1234_5678#);

   Check
     (PSX.Memory.Read_32 (Memory, 16#0001_0020#) = 16#1234_5678#,
      "Write/Read 32");

   --  Little-endian 16
   Check
     (PSX.Memory.Read_8 (Memory, 16#0001_0010#) = 16#34#,
      "Little endian 16 low byte");

   Check
     (PSX.Memory.Read_8 (Memory, 16#0001_0011#) = 16#12#,
      "Little endian 16 high byte");

   --  Little-endian 32
   Check
     (PSX.Memory.Read_8 (Memory, 16#0001_0020#) = 16#78#,
      "Little endian 32 byte 0");

   Check
     (PSX.Memory.Read_8 (Memory, 16#0001_0021#) = 16#56#,
      "Little endian 32 byte 1");

   Check
     (PSX.Memory.Read_8 (Memory, 16#0001_0022#) = 16#34#,
      "Little endian 32 byte 2");

   Check
     (PSX.Memory.Read_8 (Memory, 16#0001_0023#) = 16#12#,
      "Little endian 32 byte 3");

   --  Overwrite
   PSX.Memory.Write_32 (Memory, 16#0001_0030#, 16#1111_2222#);

   PSX.Memory.Write_32 (Memory, 16#0001_0030#, 16#3333_4444#);

   Check
     (PSX.Memory.Read_32 (Memory, 16#0001_0030#) = 16#3333_4444#,
      "Memory overwrite");

   --  Independent addresses
   PSX.Memory.Write_8 (Memory, 16#0001_0040#, 16#AA#);

   PSX.Memory.Write_8 (Memory, 16#0001_0041#, 16#BB#);

   Check
     (PSX.Memory.Read_8 (Memory, 16#0001_0040#) = 16#AA#,
      "Independent address 1");

   Check
     (PSX.Memory.Read_8 (Memory, 16#0001_0041#) = 16#BB#,
      "Independent address 2");

   --  Scratchpad

   PSX.Memory.Write_8 (Memory, 16#1F80_0000#, 16#AA#);

   Check
     (PSX.Memory.Read_8 (Memory, 16#1F80_0000#) = 16#AA#,
      "Scratchpad Write/Read 8");

   PSX.Memory.Write_32 (Memory, 16#1F80_0010#, 16#1234_5678#);

   Check
     (PSX.Memory.Read_32 (Memory, 16#1F80_0010#) = 16#1234_5678#,
      "Scratchpad Write/Read 32");

   Check
     (PSX.Memory.Read_8 (Memory, 16#1F80_0010#) = 16#78#,
      "Scratchpad little endian byte 0");

   Check
     (PSX.Memory.Read_8 (Memory, 16#1F80_0013#) = 16#12#,
      "Scratchpad little endian byte 3");

   --  RAM mirrors

   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#1234_5678#);

   Check
     (PSX.Memory.Read_32 (Memory, 16#0020_1000#) = 16#1234_5678#,
      "RAM mirror KUSEG");

   Check
     (PSX.Memory.Read_32 (Memory, 16#8000_1000#) = 16#1234_5678#,
      "RAM mirror KSEG0");

   Check
     (PSX.Memory.Read_32 (Memory, 16#A000_1000#) = 16#1234_5678#,
      "RAM mirror KSEG1");

   --  Write through KSEG0, read through physical address

   PSX.Memory.Write_32 (Memory, 16#8000_2000#, 16#AABB_CCDD#);

   Check
     (PSX.Memory.Read_32 (Memory, 16#0000_2000#) = 16#AABB_CCDD#,
      "KSEG0 write to physical RAM");

   --  Write through KSEG1, read through KSEG0

   PSX.Memory.Write_32 (Memory, 16#A000_3000#, 16#5566_7788#);

   Check
     (PSX.Memory.Read_32 (Memory, 16#8000_3000#) = 16#5566_7788#,
      "KSEG1 to KSEG0 mirror");

   --  BIOS ROM

   --  Simulamos contenido de BIOS directamente en el estado
   --  para probar el comportamiento de la región ROM.

   Memory.BIOS (16#0000_0000#) := 16#78#;
   Memory.BIOS (16#0000_0001#) := 16#56#;
   Memory.BIOS (16#0000_0002#) := 16#34#;
   Memory.BIOS (16#0000_0003#) := 16#12#;

   Check
     (PSX.Memory.Read_32 (Memory, 16#1FC0_0000#) = 16#1234_5678#,
      "BIOS Read 32");

   Check
     (PSX.Memory.Read_8 (Memory, 16#1FC0_0000#) = 16#78#,
      "BIOS Read 8 byte 0");

   Check
     (PSX.Memory.Read_8 (Memory, 16#1FC0_0003#) = 16#12#,
      "BIOS Read 8 byte 3");

   --  BIOS debe ignorar escrituras.

   PSX.Memory.Write_8 (Memory, 16#1FC0_0000#, 16#AA#);

   Check
     (PSX.Memory.Read_8 (Memory, 16#1FC0_0000#) = 16#78#,
      "BIOS ignores Write 8");

   PSX.Memory.Write_32 (Memory, 16#1FC0_0010#, 16#DEAD_BEEF#);

   Check
     (PSX.Memory.Read_32 (Memory, 16#1FC0_0010#) = 0, "BIOS ignores Write 32");

   --  Fuera del rango de BIOS.

   Check
     (PSX.Memory.Read_8 (Memory, 16#1FC8_0000#) = 0, "Address outside BIOS");

   Check
     (PSX.Memory.Read_32 (Memory, 16#BFC0_0000#) = 16#1234_5678#,
      "BIOS KSEG1 mirror");

   New_Line;
   Put_Line ("All memory tests passed.");

end PSX_Memory_Tests;
