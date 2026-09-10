with Interfaces;
with Ada.Text_IO;
with PSX.CPU;
with PSX.CPU.Fetch;
with PSX.CPU.Instruction;
with PSX.CPU.Step;
with PSX.Memory;
with PSX.Types;
with PSX.Register;

procedure PSX_BIOS_Tests is

   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

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

   Ada.Text_IO.Put_Line ("BIOS loaded successfully.");
   Ada.Text_IO.Put_Line ("");

   --------------------------------------------------
   -- VERIFY RESET VECTOR
   --------------------------------------------------

   Print_Hex ("Reset PC     = ", CPU.PC);

   Print_Hex ("BIOS BFC00000 = ", PSX.Memory.Read_32 (Memory, 16#BFC0_0000#));

   Print_Hex ("BIOS 1FC00000 = ", PSX.Memory.Read_32 (Memory, 16#1FC0_0000#));

   Ada.Text_IO.Put_Line ("");
   Ada.Text_IO.Put_Line ("Starting BIOS execution...");
   Ada.Text_IO.Put_Line ("");

   --------------------------------------------------
   -- EXECUTE BIOS
   --------------------------------------------------

   for Step_Number in 0 .. 20000 loop

      declare
         Inst        : PSX.CPU.Instruction.Instruction;
         Old_PC      : constant PSX.Types.Word32 := CPU.PC;
         Old_Next_PC : constant PSX.Types.Word32 := CPU.Next_PC;
      begin

         --------------------------------------------------
         -- FETCH CURRENT INSTRUCTION FOR TRACE
         --------------------------------------------------

         Inst := PSX.CPU.Fetch.Fetch (CPU, Memory);

         Ada.Text_IO.Put_Line
           ("  T2       = " & Hex32 (PSX.Register.Read (CPU.Registers, 10)));

         Ada.Text_IO.Put_Line
           ("  T3       = " & Hex32 (PSX.Register.Read (CPU.Registers, 11)));
         Ada.Text_IO.Put_Line
           ("  V0       = " & Hex32 (PSX.Register.Read (CPU.Registers, 2)));

         Ada.Text_IO.Put_Line
           ("  V1       = " & Hex32 (PSX.Register.Read (CPU.Registers, 3)));

         Ada.Text_IO.Put_Line ("STEP " & Integer'Image (Step_Number));

         Print_Hex ("  PC       = ", Old_PC);

         Print_Hex ("  NEXT_PC  = ", Old_Next_PC);

         Print_Hex ("  RAW      = ", Inst.Raw);

         Print_Hex ("  OPCODE   = ", PSX.CPU.Instruction.Opcode (Inst));

         Print_Hex ("  RS       = ", PSX.CPU.Instruction.Rs (Inst));

         Print_Hex ("  RT       = ", PSX.CPU.Instruction.Rt (Inst));

         Print_Hex ("  RD       = ", PSX.CPU.Instruction.Rd (Inst));

         Print_Hex ("  FUNCT    = ", PSX.CPU.Instruction.Funct (Inst));

         Print_Hex ("  SHAMT    = ", PSX.CPU.Instruction.Shamt (Inst));

         Print_Hex ("  IMM      = ", PSX.CPU.Instruction.Immediate (Inst));

         Print_Hex ("  TARGET   = ", PSX.CPU.Instruction.Target (Inst));

         --------------------------------------------------
         -- EXECUTE ONE CPU STEP
         --------------------------------------------------

         PSX.CPU.Step.Step (CPU, Memory);

         --------------------------------------------------
         -- STATE AFTER STEP
         --------------------------------------------------

         Print_Hex ("  -> PC       = ", CPU.PC);

         Print_Hex ("  -> NEXT_PC  = ", CPU.Next_PC);

         Ada.Text_IO.Put_Line
           ("  -> DELAY    = " & Boolean'Image (CPU.In_Delay_Slot));

         Ada.Text_IO.Put_Line ("");

      exception

         when E : others =>

            Ada.Text_IO.Put_Line ("  !!! CPU EXECUTION ERROR !!!");

            Ada.Text_IO.Put_Line ("  BIOS execution stopped.");

            exit;

      end;

   end loop;

   Ada.Text_IO.Put_Line ("BIOS execution trace finished.");

end PSX_BIOS_Tests;
