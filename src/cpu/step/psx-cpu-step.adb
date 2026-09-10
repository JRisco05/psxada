with Interfaces;
with PSX.CPU.Execute;
with PSX.CPU.Fetch;
with PSX.CPU.Instruction;
with PSX.Types;

package body PSX.CPU.Step is

   use type Interfaces.Unsigned_32;

   procedure Step
     (CPU : in out PSX.CPU.CPU_State; Memory : in out PSX.Memory.Memory_State)
   is
      Inst                  : PSX.CPU.Instruction.Instruction;
      Current_PC            : constant PSX.Types.Word32 := CPU.PC;
      Current_Next_PC       : constant PSX.Types.Word32 := CPU.Next_PC;
      Current_In_Delay_Slot : constant Boolean := CPU.In_Delay_Slot;
      Opcode_Value          : PSX.Types.Word32;
      Funct_Value           : PSX.Types.Word32;
      Is_Control_Transfer   : Boolean := False;
   begin

      --  Fetch the instruction at the current PC.
      Inst := PSX.CPU.Fetch.Fetch (CPU, Memory);

      Opcode_Value := PSX.CPU.Instruction.Opcode (Inst);
      Funct_Value := PSX.CPU.Instruction.Funct (Inst);

      --  Determine whether the current instruction
      --  is a control-transfer instruction.
      --
      --  Every MIPS branch/jump instruction has a delay slot,
      --  regardless of whether a conditional branch is taken.
      if Opcode_Value = 2
        or else Opcode_Value = 3
        or else Opcode_Value = 4
        or else Opcode_Value = 5
        or else Opcode_Value = 6
        or else Opcode_Value = 7
      then
         Is_Control_Transfer := True;

      elsif Opcode_Value = 1 then

         if PSX.CPU.Instruction.Rt (Inst) = 0
           or else PSX.CPU.Instruction.Rt (Inst) = 1
         then
            Is_Control_Transfer := True;
         end if;

      elsif Opcode_Value = 0 and then (Funct_Value = 8 or else Funct_Value = 9)
      then
         --  JR / JALR
         Is_Control_Transfer := True;
      end if;

      --  Prepare the sequential next instruction.
      --
      --  A branch or jump may replace this value during Execute.
      CPU.Next_PC := Current_Next_PC + PSX.Types.Word32 (4);

      --  Execute while CPU.PC still identifies the
      --  instruction currently being executed.
      PSX.CPU.Execute.Execute (CPU, Memory, Inst);

      --  A conditional branch that is not taken leaves
      --  Next_PC pointing to the sequential instruction.
      --  STEP must advance that value one more instruction,
      --  because the sequential instruction is the delay slot.
      if Is_Control_Transfer and then CPU.Next_PC = Current_Next_PC then
         CPU.Next_PC := Current_Next_PC + PSX.Types.Word32 (4);
      end if;

      --  Exception occurred.
      if CPU.Exception_Pending then

         --  If the exception happened in a delay slot,
         --  EPC must point to the branch/jump instruction.
         if Current_In_Delay_Slot then
            CPU.EPC := Current_PC - PSX.Types.Word32 (4);
         else
            CPU.EPC := Current_PC;
         end if;

         PSX.CPU.Enter_Exception (CPU);

      else

         --  Advance to the instruction scheduled before
         --  the current instruction executed.
         CPU.PC := Current_Next_PC;

         --  The next instruction is a delay slot if the
         --  current instruction was a control-transfer
         --  instruction.
         CPU.In_Delay_Slot := Is_Control_Transfer;

      end if;

   end Step;

end PSX.CPU.Step;
