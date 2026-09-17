with Ada.Text_IO;
with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with PSX.Types;
with Interfaces;

procedure PSX_CPU_SWL_SWR_Tests is

   use type Interfaces.Unsigned_32;

   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

   procedure Print_Bytes (Name : String; Base : PSX.Types.Word32) is
   begin
      Ada.Text_IO.Put_Line
        (Name
         & ": "
         & PSX.Types.Word8'Image (PSX.Memory.Read_8 (Memory, Base))
         & " "
         & PSX.Types.Word8'Image (PSX.Memory.Read_8 (Memory, Base + 1))
         & " "
         & PSX.Types.Word8'Image (PSX.Memory.Read_8 (Memory, Base + 2))
         & " "
         & PSX.Types.Word8'Image (PSX.Memory.Read_8 (Memory, Base + 3)));
   end Print_Bytes;

begin

   ------------------------------------------------------------------
   --  SWL
   ------------------------------------------------------------------

   for Offset in 0 .. 3 loop

      PSX.CPU.Reset (CPU);
      PSX.Memory.Reset (Memory);

      CPU.Registers (1) := 16#0000_0100#;
      CPU.Registers (2) := 16#1122_3344#;

      --  SWL R2, offset(R1)
      PSX.Memory.Write_32
        (Memory,
         16#0001_0000#,
         PSX.Types.Word32 (16#A822_0000#) + PSX.Types.Word32 (Offset));

      CPU.PC := 16#0001_0000#;
      CPU.Next_PC := 16#0001_0004#;

      PSX.CPU.Step.Step (CPU, Memory);

      Print_Bytes ("SWL offset" & Integer'Image (Offset), 16#0000_0100#);

   end loop;

   ------------------------------------------------------------------
   --  SWR
   ------------------------------------------------------------------

   for Offset in 0 .. 3 loop

      PSX.CPU.Reset (CPU);
      PSX.Memory.Reset (Memory);

      CPU.Registers (1) := 16#0000_0100#;
      CPU.Registers (2) := 16#1122_3344#;

      --  SWR R2, offset(R1)
      PSX.Memory.Write_32
        (Memory,
         16#0001_0000#,
         PSX.Types.Word32 (16#B822_0000#) + PSX.Types.Word32 (Offset));

      CPU.PC := 16#0001_0000#;
      CPU.Next_PC := 16#0001_0004#;

      PSX.CPU.Step.Step (CPU, Memory);

      Print_Bytes ("SWR offset" & Integer'Image (Offset), 16#0000_0100#);

   end loop;

   Ada.Text_IO.Put_Line ("PSX CPU SWL/SWR tests finished.");

end PSX_CPU_SWL_SWR_Tests;
