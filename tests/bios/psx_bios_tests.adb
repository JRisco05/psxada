with Interfaces;
with Ada.Text_IO;
with PSX.CPU;
with PSX.CPU.Instruction;
with PSX.CPU.Step;
with PSX.Memory;
with PSX.Types;
with PSX.Register;
with PSX.GPU;

procedure PSX_BIOS_Tests is

   use type Interfaces.Unsigned_32;

   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;
   GPU    : PSX.GPU.GPU_State;

   -- Límite para que limpie la RAM real de la PS1
   MAX_STEPS : constant Integer := 5_000_000;

   -- Variable para recordar en qué instrucción se quedó o terminó
   Last_Step : Integer := 0;

   function Hex32 (Value : PSX.Types.Word32) return String is
      use Interfaces;
      Hex    : constant String := "0123456789ABCDEF";
      Result : String (1 .. 8);
      V      : Unsigned_32 := Value;
   begin
      for I in reverse Result'Range loop
         Result (I) := Hex (Integer (V and 16#F#) + 1);
         V := Interfaces.Shift_Right (V, 4);
      end loop;

      return "0x" & Result;
   end Hex32;

   procedure Hook_BIOS_TTY (CPU : PSX.CPU.CPU_State) is
      use Interfaces;
      Reg_A0   : constant PSX.Types.Word32 :=
        PSX.Register.Read (CPU.Registers, 4);
      Char_Val : Character;
   begin
      if Reg_A0 <= 255 then
         Char_Val := Character'Val (Reg_A0);
         Ada.Text_IO.Put (Char_Val); -- Imprime el texto de la BIOS en pantalla

      end if;
   end Hook_BIOS_TTY;

   procedure Print_Hex (Label : String; Value : PSX.Types.Word32) is
   begin
      Ada.Text_IO.Put_Line (Label & Hex32 (Value));
   end Print_Hex;

begin

   Ada.Text_IO.Put_Line ("Testing PSX BIOS execution...");
   Ada.Text_IO.Put_Line ("");

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);
   PSX.GPU.Reset (GPU);

   PSX.Memory.Load_BIOS (Memory, "bios/SCPH1001.BIN");

   Ada.Text_IO.Put_Line
     ("BIOS loaded successfully. Running in high-speed mode...");
   Ada.Text_IO.Put_Line
     ("-------------------------------------------------------");

   --------------------------------------------------
   -- EXECUTE BIOS AT REAL HARDWARE SPEED
   --------------------------------------------------
   for Step_Number in 0 .. MAX_STEPS loop

      if CPU.PC = 16#0000_0E28# then
         Print_Hex ("  LOOP PC = ", CPU.PC);

         Print_Hex ("  INST    = ", PSX.Memory.Read_32 (Memory, CPU.PC));

         Print_Hex ("  NEXT    = ", PSX.Memory.Read_32 (Memory, CPU.Next_PC));
      end if;

      -- AQUÍ SÍ: Guardamos el paso actual correctamente
      Last_Step := Step_Number;

      if (CPU.PC and 16#1FFF_FFFF#) = 16#0000_00A0#
        or else (CPU.PC and 16#1FFF_FFFF#) = 16#0000_00B0#
      then
         -- Verificamos si la función solicitada es imprimir caracteres
         if PSX.Register.Read (CPU.Registers, 9) = 16#3C#
           or else PSX.Register.Read (CPU.Registers, 2) = 16#3C#
         then
            Hook_BIOS_TTY (CPU);
         end if;
      end if;

      --------------------------------------------------
      -- EXECUTE STEP SILENTLY (Sin Prints lentos)
      --------------------------------------------------
      begin
         PSX.CPU.Step.Step (CPU, Memory, GPU);
      exception
         when others =>
            Ada.Text_IO.New_Line;
            Ada.Text_IO.Put_Line
              ("  !!! CPU CRASH AT STEP "
               & Integer'Image (Step_Number)
               & " !!!");
            Ada.Text_IO.Put_Line ("  PC Target: " & Hex32 (CPU.PC));
            exit;
      end;

   end loop;

   -- AQUÍ: Mostramos el total real de pasos ejecutados al terminar el bucle
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("-------------------------------------------------------");
   Ada.Text_IO.Put_Line ("Total steps executed: " & Integer'Image (Last_Step));
   Ada.Text_IO.Put_Line ("BIOS execution completed or hit step limit.");

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("=== ESTADO FINAL DE LA CPU ===");
   Print_Hex ("  PC Actual   = ", CPU.PC);
   Print_Hex ("  Next PC     = ", CPU.Next_PC);
   Print_Hex ("  Registro V0 = ", PSX.Register.Read (CPU.Registers, 2));
   Print_Hex ("  Registro T1 = ", PSX.Register.Read (CPU.Registers, 9));

end PSX_BIOS_Tests;
