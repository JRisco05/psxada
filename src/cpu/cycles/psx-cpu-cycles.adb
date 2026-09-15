with PSX.CPU.Instruction;
with Interfaces;

package body PSX.CPU.Cycles is

   use type Interfaces.Unsigned_32;

   function Get (Inst : PSX.CPU.Instruction.Instruction) return Natural is
      Opcode : constant PSX.CPU.Instruction.Word32 :=
        PSX.CPU.Instruction.Opcode (Inst);

      Funct : constant PSX.CPU.Instruction.Word32 :=
        PSX.CPU.Instruction.Funct (Inst);
   begin

      -- R-type instructions.
      if Opcode = 0 then

         case Funct is

            -- JR / JALR

            when 16#08# | 16#09# =>
               return 1;

            -- SYSCALL / BREAK

            when 16#0C# | 16#0D# =>
               return 1;

            -- MULT / MULTU

            when 16#18# | 16#19# =>
               return 1;

            -- DIV / DIVU

            when 16#1A# | 16#1B# =>
               return 1;

            when others          =>
               return 1;

         end case;

      -- Conditional branches.
      elsif Opcode = 1
        or else Opcode = 4
        or else Opcode = 5
        or else Opcode = 6
        or else Opcode = 7
      then
         return 1;

      -- J / JAL.
      elsif Opcode = 2 or else Opcode = 3 then
         return 1;

      -- Immediate ALU instructions.
      elsif Opcode = 8
        or else Opcode = 9
        or else Opcode = 10
        or else Opcode = 11
        or else Opcode = 12
        or else Opcode = 13
        or else Opcode = 14
        or else Opcode = 15
      then
         return 1;

      -- Loads.
      elsif Opcode = 16#20#
        or else Opcode = 16#21#
        or else Opcode = 16#22#
        or else Opcode = 16#23#
        or else Opcode = 16#24#
        or else Opcode = 16#25#
        or else Opcode = 16#26# -- LWR
      then
         return 0;

      -- Stores.
      elsif Opcode = 16#28#
        or else Opcode = 16#29#
        or else Opcode = 16#2A#
        or else Opcode = 16#2B#
        or else Opcode = 16#2E# -- SWR
      then
         return 0;

      else
         return 1;
      end if;

   end Get;

end PSX.CPU.Cycles;
