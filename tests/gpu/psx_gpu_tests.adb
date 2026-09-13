with Ada.Text_IO;
with PSX.GPU;
with PSX.Types;
with Interfaces;

procedure PSX_GPU_Tests is

   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_16;
   --  use type Interfaces.Unsigned_8;

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

   PSX.GPU.Reset (GPU);

   PSX.GPU.Write_GP0 (GPU, 16#A0C8_0064#);

   Check ("GP0 command A0", 16#A0#, PSX.Types.Word32 (GPU.GP0_Command));

   Check ("GP0 A0 X", 100, PSX.Types.Word32 (GPU.GP0_X));

   Check ("GP0 A0 Y", 200, PSX.Types.Word32 (GPU.GP0_Y));

   PSX.GPU.Write_GP0 (GPU, 16#000A_0014#);

   Check ("GP0 A0 Width", 20, PSX.Types.Word32 (GPU.GP0_Width));

   Check ("GP0 A0 Height", 10, PSX.Types.Word32 (GPU.GP0_Height));

   PSX.GPU.Write_GP1 (GPU, 16#89AB_CDEF#);

   Check ("GP1 write", 16#89AB_CDEF#, GPU.GP1);

   PSX.GPU.Write_GP1 (GPU, 16#89AB_CDEF#);

   Check ("GP1 write", 16#89AB_CDEF#, GPU.GP1);

   PSX.GPU.Write_VRAM (GPU, 0, 0, 16#7C00#);

   Check ("VRAM pixel 0,0", 16#7C00#, PSX.GPU.Read_VRAM (GPU, 0, 0));

   PSX.GPU.Write_VRAM (GPU, 100, 200, 16#03E0#);

   Check ("VRAM pixel 100,200", 16#03E0#, PSX.GPU.Read_VRAM (GPU, 100, 200));

   PSX.GPU.Write_VRAM (GPU, 1023, 511, 16#001F#);

   Check ("VRAM last pixel", 16#001F#, PSX.GPU.Read_VRAM (GPU, 1023, 511));

   -- Test GP0 A0: CPU -> VRAM
   PSX.GPU.Reset (GPU);

   -- A0: X=100, Y=200
   PSX.GPU.Write_GP0 (GPU, 16#A0C8_0064#);

   -- Width=2, Height=1
   PSX.GPU.Write_GP0 (GPU, 16#0001_0002#);

   -- Pixel 0 = 7C00
   -- Pixel 1 = 03E0
   PSX.GPU.Write_GP0 (GPU, 16#03E0_7C00#);

   Check ("GP0 A0 pixel 0", 16#7C00#, PSX.GPU.Read_VRAM (GPU, 100, 200));

   Check ("GP0 A0 pixel 1", 16#03E0#, PSX.GPU.Read_VRAM (GPU, 101, 200));

   -- Test GP0 A0: transferencia de varias filas
   PSX.GPU.Reset (GPU);

   -- A0: X=100, Y=200
   PSX.GPU.Write_GP0 (GPU, 16#A0C8_0064#);

   -- Width=3, Height=2
   PSX.GPU.Write_GP0 (GPU, 16#0002_0003#);

   -- 6 píxeles = 3 words
   PSX.GPU.Write_GP0 (GPU, 16#2222_1111#);
   PSX.GPU.Write_GP0 (GPU, 16#4444_3333#);
   PSX.GPU.Write_GP0 (GPU, 16#6666_5555#);

   Check ("GP0 A0 multi pixel 0", 16#1111#, PSX.GPU.Read_VRAM (GPU, 100, 200));

   Check ("GP0 A0 multi pixel 1", 16#2222#, PSX.GPU.Read_VRAM (GPU, 101, 200));

   Check ("GP0 A0 multi pixel 2", 16#3333#, PSX.GPU.Read_VRAM (GPU, 102, 200));

   Check ("GP0 A0 multi pixel 3", 16#4444#, PSX.GPU.Read_VRAM (GPU, 100, 201));

   Check ("GP0 A0 multi pixel 4", 16#5555#, PSX.GPU.Read_VRAM (GPU, 101, 201));

   Check ("GP0 A0 multi pixel 5", 16#6666#, PSX.GPU.Read_VRAM (GPU, 102, 201));

   Ada.Text_IO.Put_Line ("GPU tests finished.");

end PSX_GPU_Tests;
