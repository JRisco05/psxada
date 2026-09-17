with Interfaces;
with Ada.Text_IO;
with PSX.CPU;
with PSX.CPU.Step;
with PSX.Memory;
with PSX.Types;
with PSX.Register;
with PSX.GPU;
with PSX.SPU;
with PSX.GTE;
with PSX.DMA; -- 1. AGREGADO: Importamos tu modulo DMA

procedure PSX_BIOS_Tests is

   use type Interfaces.Unsigned_32;

   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;
   GPU    : PSX.GPU.GPU_State;
   SPU    : PSX.SPU.SPU_State;
   GTE    : PSX.GTE.GTE_State;

   --  Límite para que limpie la RAM real de la PS1
   MAX_STEPS : constant Integer := 20_000_000;

   --  Variables de control de bucles e historial
   Last_Step       : Integer := 0;
   Loop_Count      : Integer := 0;
   First_Loop_Step : Integer := -1;

   Prev_PC   : PSX.Types.Word32 := 0;
   Prev_Inst : PSX.Types.Word32 := 0;

   Consecutive_Nops : Integer := 0;

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
         Ada.Text_IO.Put (Char_Val);
      end if;
   end Hook_BIOS_TTY;

   procedure Print_Hex (Label : String; Value : PSX.Types.Word32) is
   begin
      Ada.Text_IO.Put_Line (Label & Hex32 (Value));
   end Print_Hex;

begin

   Ada.Text_IO.Put_Line ("Testing PSX BIOS with full hardware chain...");
   Ada.Text_IO.Put_Line ("");

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);
   PSX.GPU.Reset (GPU);
   PSX.SPU.Reset (SPU);
   PSX.GTE.Reset (GTE);

   --  2. AGREGADO: Inicializamos los registros de tu DMA pasandole la memoria
   PSX.DMA.Reset (Memory);

   PSX.Memory.Load_BIOS (Memory, "bios/SCPH1001.BIN");

   Ada.Text_IO.Put_Line
     ("BIOS loaded successfully. Running in high-speed mode...");
   Ada.Text_IO.Put_Line
     ("-------------------------------------------------------");

   --------------------------------------------------
   --  EXECUTE BIOS AT REAL HARDWARE SPEED
   --------------------------------------------------

   for Step_Number in 0 .. MAX_STEPS loop

      Last_Step := Step_Number;

      --  1. HISTORIAL: Leemos la instrucción antes del paso
      Prev_PC := CPU.PC;
      begin
         Prev_Inst := PSX.Memory.Read_32 (Memory, CPU.PC);
      exception
         when others =>
            Prev_Inst := 16#DEAD_BEEF#;
      end;

      --  2. CONTADOR: Conteo de NOPs reales
      if Prev_Inst = 0 then
         Consecutive_Nops := Consecutive_Nops + 1;
      else
         Consecutive_Nops := 0;
      end if;

      --  3. ALARMA DE CONGELAMIENTO (ZONA VACÍA)
      if Consecutive_Nops >= 100 then
         Ada.Text_IO.New_Line;
         Ada.Text_IO.Put_Line
           ("  !!! DETECTADA CAMINATA INFINITA DE NOPS !!!");
         Ada.Text_IO.Put_Line
           ("  El problema empezo cerca del PASO: "
            & Integer'Image (Step_Number - 100));
         Print_Hex ("  PC antes de caer en el vacio = ", Prev_PC - (100 * 4));
         Print_Hex ("  PC Actual en el colapso      = ", CPU.PC);

         Ada.Text_IO.New_Line;
         Ada.Text_IO.Put_Line ("=== DIAGNOSTICO DE REGISTROS ===");
         Print_Hex ("  Reg RA (31) = ", PSX.Register.Read (CPU.Registers, 31));
         Print_Hex ("  Reg SP (29) = ", PSX.Register.Read (CPU.Registers, 29));
         Print_Hex ("  Reg T0 (8)  = ", PSX.Register.Read (CPU.Registers, 8));
         Print_Hex ("  Reg T1 (9)  = ", PSX.Register.Read (CPU.Registers, 9));

         exit;
      end if;

      --  4. DETECTAR EL BUCLE DE ESPERA FAMOSO (0xE28)
      if (CPU.PC and 16#1FFF_FFFF#) = 16#0000_0E28# then
         if First_Loop_Step = -1 then
            First_Loop_Step := Step_Number;
         end if;
         Loop_Count := Loop_Count + 1;
      end if;

      --  5. HOOK DE LA BIOS PARA TEXTO (TTY)
      if (CPU.PC and 16#1FFF_FFFF#) = 16#0000_00A0#
        or else (CPU.PC and 16#1FFF_FFFF#) = 16#0000_00B0#
      then
         if PSX.Register.Read (CPU.Registers, 9) = 16#3C#
           or else PSX.Register.Read (CPU.Registers, 2) = 16#3C#
         then
            Hook_BIOS_TTY (CPU);
         end if;
      end if;

      --------------------------------------------------
      --  EXECUTE STEP SILENTLY (Sin Prints lentos)
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

   --  Mostramos el total real de pasos ejecutados al terminar
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("-------------------------------------------------------");
   Ada.Text_IO.Put_Line ("Total steps executed: " & Integer'Image (Last_Step));
   Ada.Text_IO.Put_Line ("Times at 0x00000E28: " & Integer'Image (Loop_Count));
   Ada.Text_IO.Put_Line ("BIOS execution completed or hit step limit.");

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("=== ESTADO FINAL DE LA CPU ===");
   Print_Hex ("  PC Actual   = ", CPU.PC);
   Print_Hex ("  Next PC     = ", CPU.Next_PC);
   Print_Hex ("  Registro V0 = ", PSX.Register.Read (CPU.Registers, 2));
   Print_Hex ("  Registro T1 = ", PSX.Register.Read (CPU.Registers, 9));

end PSX_BIOS_Tests;
