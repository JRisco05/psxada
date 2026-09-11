with Ada.Text_IO;
with PSX.GPU;
with PSX.Types;
with Interfaces;

procedure PSX_GPU_Tests is

   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_16;

   GPU : PSX.GPU.GPU_State;

   procedure Check
     (Name : String; Expected : PSX.Types.Word32; Actual : PSX.Types.Word32) is
   begin
      if Expected = Actual then
         Ada.Text_IO.Put_Line ("PASS: " & Name);
      else
         Ada.Text_IO.Put_Line ("FAIL: " & Name);
      end if;
   end Check;

   procedure Check
     (Name : String; Expected : PSX.Types.Word16; Actual : PSX.Types.Word16) is
   begin
      if Expected = Actual then
         Ada.Text_IO.Put_Line ("PASS: " & Name);
      else
         Ada.Text_IO.Put_Line ("FAIL: " & Name);
      end if;
   end Check;

begin

   Ada.Text_IO.Put_Line ("Testing PSX GPU...");

   PSX.GPU.Reset (GPU);

   Check ("GP0 reset", 0, GPU.GP0);

   Check ("GP1 reset", 0, GPU.GP1);

   Check ("GPU Status reset", 0, PSX.GPU.Read_Status (GPU));

   PSX.GPU.Write_GP0 (GPU, 16#1234_5678#);

   Check ("GP0 write", 16#1234_5678#, GPU.GP0);

   PSX.GPU.Write_GP1 (GPU, 16#89AB_CDEF#);

   Check ("GP1 write", 16#89AB_CDEF#, GPU.GP1);

   PSX.GPU.Write_VRAM (GPU, 0, 0, 16#7C00#);

   Check ("VRAM pixel 0,0", 16#7C00#, PSX.GPU.Read_VRAM (GPU, 0, 0));

   PSX.GPU.Write_VRAM (GPU, 100, 200, 16#03E0#);

   Check ("VRAM pixel 100,200", 16#03E0#, PSX.GPU.Read_VRAM (GPU, 100, 200));

   PSX.GPU.Write_VRAM (GPU, 1023, 511, 16#001F#);

   Check ("VRAM last pixel", 16#001F#, PSX.GPU.Read_VRAM (GPU, 1023, 511));

   Ada.Text_IO.Put_Line ("GPU tests finished.");

end PSX_GPU_Tests;
