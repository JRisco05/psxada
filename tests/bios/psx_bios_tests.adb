--  with Interfaces;
--  with Ada.Text_IO;
--  with PSX.CPU;
--  with PSX.CPU.Fetch;
--  with PSX.CPU.Instruction;
--  with PSX.CPU.Step;
--  with PSX.Memory;
--  with PSX.Types;
--  with PSX.Register;

--  procedure PSX_BIOS_Tests is

--     CPU    : PSX.CPU.CPU_State;
--     Memory : PSX.Memory.Memory_State;

--     function Hex32 (Value : PSX.Types.Word32) return String is
--        use Interfaces;

--        Hex    : constant String := "0123456789ABCDEF";
--        Result : String (1 .. 8);
--        V      : Unsigned_32 := Value;
--     begin
--        for I in reverse Result'Range loop
--           Result (I) := Hex (Integer (V and 16#F#) + 1);
--           V := Interfaces.Shift_Right (V, 4);
--        end loop;

--        return "0x" & Result;
--     end Hex32;

--     procedure Print_Hex (Label : String; Value : PSX.Types.Word32) is
--     begin
--        Ada.Text_IO.Put_Line (Label & Hex32 (Value));
--     end Print_Hex;

--  begin

--     Ada.Text_IO.Put_Line ("Testing PSX BIOS execution...");
--     Ada.Text_IO.Put_Line ("");

--     PSX.CPU.Reset (CPU);
--     PSX.Memory.Reset (Memory);

--     PSX.Memory.Load_BIOS (Memory, "bios/SCPH1001.BIN");

--     Ada.Text_IO.Put_Line ("BIOS loaded successfully.");
--     Ada.Text_IO.Put_Line ("");

--     --------------------------------------------------
--     --  VERIFY RESET VECTOR
--     --------------------------------------------------

--     Print_Hex ("Reset PC     = ", CPU.PC);

--     Print_Hex ("BIOS BFC00000 = ", PSX.Memory.Read_32 (Memory, 16#BFC0_0000#));

--     Print_Hex ("BIOS 1FC00000 = ", PSX.Memory.Read_32 (Memory, 16#1FC0_0000#));

--     Ada.Text_IO.Put_Line ("");
--     Ada.Text_IO.Put_Line ("Starting BIOS execution...");
--     Ada.Text_IO.Put_Line ("");

--     --------------------------------------------------
--     --  EXECUTE BIOS
--     --------------------------------------------------

--     for Step_Number in 0 .. 20000 loop

--        declare
--           Inst        : PSX.CPU.Instruction.Instruction;
--           Old_PC      : constant PSX.Types.Word32 := CPU.PC;
--           Old_Next_PC : constant PSX.Types.Word32 := CPU.Next_PC;
--        begin

--           --------------------------------------------------
--           --  FETCH CURRENT INSTRUCTION FOR TRACE
--           --------------------------------------------------

--           Inst := PSX.CPU.Fetch.Fetch (CPU, Memory);

--           Ada.Text_IO.Put_Line
--             ("  T2       = " & Hex32 (PSX.Register.Read (CPU.Registers, 10)));

--           Ada.Text_IO.Put_Line
--             ("  T3       = " & Hex32 (PSX.Register.Read (CPU.Registers, 11)));
--           Ada.Text_IO.Put_Line
--             ("  V0       = " & Hex32 (PSX.Register.Read (CPU.Registers, 2)));

--           Ada.Text_IO.Put_Line
--             ("  V1       = " & Hex32 (PSX.Register.Read (CPU.Registers, 3)));

--           Ada.Text_IO.Put_Line ("STEP " & Integer'Image (Step_Number));

--           Print_Hex ("  PC       = ", Old_PC);

--           Print_Hex ("  NEXT_PC  = ", Old_Next_PC);

--           Print_Hex ("  RAW      = ", Inst.Raw);

--           Print_Hex ("  OPCODE   = ", PSX.CPU.Instruction.Opcode (Inst));

--           Print_Hex ("  RS       = ", PSX.CPU.Instruction.Rs (Inst));

--           Print_Hex ("  RT       = ", PSX.CPU.Instruction.Rt (Inst));

--           Print_Hex ("  RD       = ", PSX.CPU.Instruction.Rd (Inst));

--           Print_Hex ("  FUNCT    = ", PSX.CPU.Instruction.Funct (Inst));

--           Print_Hex ("  SHAMT    = ", PSX.CPU.Instruction.Shamt (Inst));

--           Print_Hex ("  IMM      = ", PSX.CPU.Instruction.Immediate (Inst));

--           Print_Hex ("  TARGET   = ", PSX.CPU.Instruction.Target (Inst));

--           --------------------------------------------------
--           --  EXECUTE ONE CPU STEP
--           --------------------------------------------------

--           PSX.CPU.Step.Step (CPU, Memory);

--           --------------------------------------------------
--           --  STATE AFTER STEP
--           --------------------------------------------------

--           Print_Hex ("  -> PC       = ", CPU.PC);

--           Print_Hex ("  -> NEXT_PC  = ", CPU.Next_PC);

--           Ada.Text_IO.Put_Line
--             ("  -> DELAY    = " & Boolean'Image (CPU.In_Delay_Slot));

--           Ada.Text_IO.Put_Line ("");

--        exception

--           when E : others =>

--              Ada.Text_IO.Put_Line ("  !!! CPU EXECUTION ERROR !!!");

--              Ada.Text_IO.Put_Line ("  BIOS execution stopped.");

--              exit;

--        end;

--     end loop;

--     Ada.Text_IO.Put_Line ("BIOS execution trace finished.");

--  end PSX_BIOS_Tests;

with Interfaces;
with Ada.Text_IO;
with PSX.CPU;
with PSX.CPU.Instruction;
with PSX.CPU.Step;
with PSX.Memory;
with PSX.Types;
with PSX.Register;

procedure PSX_BIOS_Tests is

   use type Interfaces.Unsigned_32;

   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

   --  Aumentamos drásticamente el límite para que limpie la RAM real de la PS1
   MAX_STEPS : constant Integer := 5_000_000;

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

   --  Rutina para capturar el texto interno que la BIOS de PS1 quiere imprimir
   procedure Hook_BIOS_TTY (CPU : PSX.CPU.CPU_State) is
      use Interfaces;
      --  En la PS1, la función de impresión de caracteres usa el Registro 9 ($t1) como comando
      --  y el Registro 4 ($a0) contiene el carácter en formato ASCII
      Reg_A0   : constant PSX.Types.Word32 :=
        PSX.Register.Read (CPU.Registers, 4);
      Char_Val : Character;
   begin
      --  Mapeamos el número de registro a un carácter ASCII legible
      if Reg_A0 <= 255 then
         Char_Val := Character'Val (Reg_A0);
         Ada.Text_IO.Put
           (Char_Val); -- Imprime directo la letra de la BIOS en tu pantalla

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

   PSX.Memory.Load_BIOS (Memory, "bios/SCPH1001.BIN");

   Ada.Text_IO.Put_Line
     ("BIOS loaded successfully. Running in high-speed mode...");
   Ada.Text_IO.Put_Line
     ("-------------------------------------------------------");

   --------------------------------------------------
   --  EXECUTE BIOS AT REAL HARDWARE SPEED
   --------------------------------------------------

   for Step_Number in 0 .. MAX_STEPS loop

      --  1. PARCHE DE VELOCIDAD: Forzamos que los registros de hardware reporten "LISTO"
      --  Si la BIOS consulta la GPU (0x1F801814), le respondemos en la memoria que no está ocupada
      --  para que no se quede atrapada en loops posteriores.
      --  (Nota: Ajusta esto según cómo manejes las lecturas físicas en tu módulo de memoria)

      --  2. INTERCEPTAR RADO DE ACCIONES DE LA BIOS (TTY HOOK)
      --  La BIOS de PS1 ejecuta llamadas del sistema (Syscalls) saltando a la dirección 0x000000A0 o 0x000000B0

      --  Buscamos si la CPU está saltando a las rutinas de la BIOS (A0, B0 o C0)
      --  Usamos una máscara para ignorar los bits altos (KSEG0 / KSEG1)
      if (CPU.PC and 16#1FFF_FFFF#) = 16#0000_00A0#
        or else (CPU.PC and 16#1FFF_FFFF#) = 16#0000_00B0#
      then
         --  Verificamos si la función solicitada en V0 o T1 es la de imprimir caracteres
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
         PSX.CPU.Step.Step (CPU, Memory);
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

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("-------------------------------------------------------");
   Ada.Text_IO.Put_Line
     ("BIOS execution execution completed or hit step limit.");

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("=== ESTADO FINAL DE LA CPU ===");
   Print_Hex ("  PC Actual   = ", CPU.PC);
   Print_Hex ("  Next PC     = ", CPU.Next_PC);
   Print_Hex ("  Registro V0 = ", PSX.Register.Read (CPU.Registers, 2));
   Print_Hex ("  Registro T1 = ", PSX.Register.Read (CPU.Registers, 9));

end PSX_BIOS_Tests;
