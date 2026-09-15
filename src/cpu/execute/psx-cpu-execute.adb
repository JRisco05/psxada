with Interfaces;
with Ada.Unchecked_Conversion;
with PSX.Types;
with PSX.Register;
with PSX.CPU.MulDiv;

package body PSX.CPU.Execute is
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;
   use type Interfaces.Integer_32;
   use type Interfaces.Unsigned_64;
   use type Interfaces.Integer_64;
   use type PSX.Register.Register_Index;

   function Sign_Extend_16 (Value : PSX.Types.Word16) return PSX.Types.Word32
   is
   begin
      if Interfaces.Unsigned_16 (Value) >= 16#8000# then
         return 16#FFFF_0000# or PSX.Types.Word32 (Value);
      else
         return PSX.Types.Word32 (Value);
      end if;
   end Sign_Extend_16;

   function Sign_Extend_8 (Value : PSX.Types.Word8) return PSX.Types.Word32 is
   begin
      if Interfaces.Unsigned_8 (Value) >= 16#80# then
         return 16#FFFF_FF00# or PSX.Types.Word32 (Value);
      else
         return PSX.Types.Word32 (Value);
      end if;
   end Sign_Extend_8;

   function Zero_Extend_16 (Value : PSX.Types.Word16) return PSX.Types.Word32
   is
   begin
      return PSX.Types.Word32 (Value);
   end Zero_Extend_16;

   function To_Signed_32
     (Value : PSX.Types.Word32) return Interfaces.Integer_32 is
   begin
      if Value >= 16#8000_0000# then
         return
           Interfaces.Integer_32 (Value - 16#8000_0000#)
           + Interfaces.Integer_32'First;
      else
         return Interfaces.Integer_32 (Value);
      end if;
   end To_Signed_32;

   function To_Word32 is new
     Ada.Unchecked_Conversion (Interfaces.Integer_32, PSX.Types.Word32);

   function Multiply_Signed
     (Left : PSX.Types.Word32; Right : PSX.Types.Word32)
      return PSX.Types.Word64
   is
      Left_Negative : constant Boolean := (Left and 16#8000_0000#) /= 0;

      Right_Negative : constant Boolean := (Right and 16#8000_0000#) /= 0;

      Left_Magnitude  : PSX.Types.Word32;
      Right_Magnitude : PSX.Types.Word32;

      Product : PSX.Types.Word64;

   begin

      if Left_Negative then
         Left_Magnitude := not Left + 1;
      else
         Left_Magnitude := Left;
      end if;

      if Right_Negative then
         Right_Magnitude := not Right + 1;
      else
         Right_Magnitude := Right;
      end if;

      Product :=
        PSX.Types.Word64 (Left_Magnitude) * PSX.Types.Word64 (Right_Magnitude);

      if Left_Negative xor Right_Negative then
         return not Product + 1;
      else
         return Product;
      end if;

   end Multiply_Signed;

   procedure Execute
     (CPU    : in out PSX.CPU.CPU_State;
      Memory : in out PSX.Memory.Memory_State;
      Inst   : PSX.CPU.Instruction.Instruction)

   is
      Opcode_Value : constant PSX.Types.Word32 :=
        PSX.CPU.Instruction.Opcode (Inst);

      Funct_Value : constant PSX.Types.Word32 :=
        PSX.CPU.Instruction.Funct (Inst);

      Rs_Index : constant PSX.Register.Register_Index :=
        PSX.Register.Register_Index (PSX.CPU.Instruction.Rs (Inst));

      Rt_Index : constant PSX.Register.Register_Index :=
        PSX.Register.Register_Index (PSX.CPU.Instruction.Rt (Inst));

      Rd_Index : constant PSX.Register.Register_Index :=
        PSX.Register.Register_Index (PSX.CPU.Instruction.Rd (Inst));

      Shamt_Value : constant Natural :=
        Natural (PSX.CPU.Instruction.Shamt (Inst));

      Rs_Value : constant PSX.Types.Word32 :=
        PSX.Register.Read (CPU.Registers, Rs_Index);

      Rt_Value : constant PSX.Types.Word32 :=
        PSX.Register.Read (CPU.Registers, Rt_Index);

      Immediate_Value : constant PSX.Types.Word32 :=
        PSX.CPU.Instruction.Immediate (Inst);

      Effective_Address : constant PSX.Types.Word32 :=
        Rs_Value + Sign_Extend_16 (PSX.Types.Word16 (Immediate_Value));

   begin

      --  R-Type instructions
      if Opcode_Value = 0 then

         case Funct_Value is

            --  SLL

            when 0      =>

               PSX.Register.Write
                 (CPU.Registers,
                  Rd_Index,
                  Interfaces.Shift_Left (Rt_Value, Shamt_Value));

            --  SRL

            when 2      =>

               PSX.Register.Write
                 (CPU.Registers,
                  Rd_Index,
                  Interfaces.Shift_Right (Rt_Value, Shamt_Value));

            --  SRA

            when 3      =>

               PSX.Register.Write
                 (CPU.Registers,
                  Rd_Index,
                  Interfaces.Shift_Right_Arithmetic (Rt_Value, Shamt_Value));

            --  SLLV

            when 4      =>

               PSX.Register.Write
                 (CPU.Registers,
                  Rd_Index,
                  Interfaces.Shift_Left
                    (Rt_Value, Natural (Rs_Value and 16#0000_001F#)));

            --  SRLV

            when 6      =>

               PSX.Register.Write
                 (CPU.Registers,
                  Rd_Index,
                  Interfaces.Shift_Right
                    (Rt_Value, Natural (Rs_Value and 16#0000_001F#)));

            --  SRAV

            when 7      =>

               PSX.Register.Write
                 (CPU.Registers,
                  Rd_Index,
                  Interfaces.Shift_Right_Arithmetic
                    (Rt_Value, Natural (Rs_Value and 16#0000_001F#)));

            --  JR

            when 8      =>

               CPU.Next_PC := PSX.Register.Read (CPU.Registers, Rs_Index);

            --  JALR

            when 9      =>

               PSX.Register.Write (CPU.Registers, Rd_Index, CPU.PC + 8);

               CPU.Next_PC := Rs_Value;

            --  SYSCALL

            when 12     =>

               CPU.Cause := Syscall;
               CPU.EPC := CPU.PC;
               CPU.Exception_Pending := True;

            --  BREAK

            when 13     =>

               CPU.Cause := PSX.CPU.Break;
               CPU.EPC := CPU.PC;
               CPU.Exception_Pending := True;

            --  MFHI

            when 16     =>

               PSX.Register.Write (CPU.Registers, Rd_Index, CPU.HI);

            --  MTHI

            when 17     =>

               CPU.HI := Rs_Value;

            --  MFLO

            when 18     =>

               PSX.Register.Write (CPU.Registers, Rd_Index, CPU.LO);

            --  MTLO

            when 19     =>

               CPU.LO := Rs_Value;

            --  MULT

            when 24     =>

               PSX.CPU.MulDiv.Start_Multiply (CPU, Rs_Value, Rt_Value, True);

            --  MULTU

            when 25     =>

               PSX.CPU.MulDiv.Start_Multiply (CPU, Rs_Value, Rt_Value, False);

            --  DIV

            when 26     =>

               PSX.CPU.MulDiv.Start_Divide (CPU, Rs_Value, Rt_Value, True);

            --  DIVU

            when 27     =>

               PSX.CPU.MulDiv.Start_Divide (CPU, Rs_Value, Rt_Value, False);

            --  ADD

            when 32     =>

               declare
                  A : constant Interfaces.Integer_64 :=
                    Interfaces.Integer_64 (To_Signed_32 (Rs_Value));

                  B : constant Interfaces.Integer_64 :=
                    Interfaces.Integer_64 (To_Signed_32 (Rt_Value));

                  Result : constant Interfaces.Integer_64 := A + B;
               begin
                  if Result
                    > Interfaces.Integer_64 (Interfaces.Integer_32'Last)
                    or else
                      Result
                      < Interfaces.Integer_64 (Interfaces.Integer_32'First)
                  then
                     CPU.Cause := PSX.CPU.Overflow;
                     CPU.EPC := CPU.PC;
                     CPU.Exception_Pending := True;
                  else
                     PSX.Register.Write
                       (CPU.Registers,
                        Rd_Index,
                        To_Word32 (Interfaces.Integer_32 (Result)));
                  end if;
               end;

            --  ADDU

            when 33     =>

               PSX.Register.Write
                 (CPU.Registers, Rd_Index, Rs_Value + Rt_Value);

            --  SUB

            when 34     =>

               declare
                  A : constant Interfaces.Integer_64 :=
                    Interfaces.Integer_64 (To_Signed_32 (Rs_Value));

                  B : constant Interfaces.Integer_64 :=
                    Interfaces.Integer_64 (To_Signed_32 (Rt_Value));

                  Result : constant Interfaces.Integer_64 := A - B;
               begin
                  if Result
                    > Interfaces.Integer_64 (Interfaces.Integer_32'Last)
                    or else
                      Result
                      < Interfaces.Integer_64 (Interfaces.Integer_32'First)
                  then
                     CPU.Cause := PSX.CPU.Overflow;
                     CPU.EPC := CPU.PC;
                     CPU.Exception_Pending := True;
                  else
                     PSX.Register.Write
                       (CPU.Registers,
                        Rd_Index,
                        To_Word32 (Interfaces.Integer_32 (Result)));
                  end if;
               end;

            --  SUBU

            when 35     =>

               PSX.Register.Write
                 (CPU.Registers, Rd_Index, Rs_Value - Rt_Value);

            --  AND

            when 36     =>

               PSX.Register.Write
                 (CPU.Registers, Rd_Index, Rs_Value and Rt_Value);

            --  OR

            when 37     =>

               PSX.Register.Write
                 (CPU.Registers, Rd_Index, Rs_Value or Rt_Value);

            --  XOR

            when 38     =>

               PSX.Register.Write
                 (CPU.Registers, Rd_Index, Rs_Value xor Rt_Value);

            --  NOR

            when 39     =>

               PSX.Register.Write
                 (CPU.Registers, Rd_Index, not (Rs_Value or Rt_Value));

            --  SLT

            when 42     =>

               if To_Signed_32 (Rs_Value) < To_Signed_32 (Rt_Value) then
                  PSX.Register.Write (CPU.Registers, Rd_Index, 1);
               else
                  PSX.Register.Write (CPU.Registers, Rd_Index, 0);
               end if;

            --  SLTU

            when 43     =>

               if Rs_Value < Rt_Value then
                  PSX.Register.Write (CPU.Registers, Rd_Index, 1);
               else
                  PSX.Register.Write (CPU.Registers, Rd_Index, 0);
               end if;

            when others =>
               null;

         end case;
      end if;

      --  COP0
      if Opcode_Value = 16 then

         --  RFE
         if Inst.Raw = 16#4200_0010# then

            PSX.CPU.Return_From_Exception (CPU);

         --  MTC0
         elsif PSX.CPU.Instruction.Rs (Inst) = 4 then

            --  COP0 Status register ($12)
            if Rd_Index = 12 then
               CPU.Status := Rt_Value;
            end if;
         end if;
      end if;

      --  I-Type instructions
      if Opcode_Value = 8 then

         --  ADDI rt, rs, immediate
         declare
            A : constant Interfaces.Integer_64 :=
              Interfaces.Integer_64 (To_Signed_32 (Rs_Value));

            B : constant Interfaces.Integer_64 :=
              Interfaces.Integer_64
                (To_Signed_32
                   (Sign_Extend_16 (PSX.Types.Word16 (Immediate_Value))));

            Result : constant Interfaces.Integer_64 := A + B;
         begin
            if Result > Interfaces.Integer_64 (Interfaces.Integer_32'Last)
              or else
                Result < Interfaces.Integer_64 (Interfaces.Integer_32'First)
            then
               CPU.Cause := PSX.CPU.Overflow;
               CPU.EPC := CPU.PC;
               CPU.Exception_Pending := True;
            else
               PSX.Register.Write
                 (CPU.Registers,
                  Rt_Index,
                  To_Word32 (Interfaces.Integer_32 (Result)));
            end if;
         end;

      elsif Opcode_Value = 9 then

         --  ADDIU rt, rs, immediate
         PSX.Register.Write
           (CPU.Registers,
            Rt_Index,
            Rs_Value + Sign_Extend_16 (PSX.Types.Word16 (Immediate_Value)));

      end if;

      --  SLTI rt, rs, immediate
      if Opcode_Value = 10 then

         if To_Signed_32 (Rs_Value)
           < To_Signed_32 (Sign_Extend_16 (PSX.Types.Word16 (Immediate_Value)))
         then

            PSX.Register.Write (CPU.Registers, Rt_Index, 1);

         else

            PSX.Register.Write (CPU.Registers, Rt_Index, 0);

         end if;

      end if;

      --  SLTIU rt, rs, immediate
      if Opcode_Value = 11 then

         if Rs_Value < Sign_Extend_16 (PSX.Types.Word16 (Immediate_Value)) then

            PSX.Register.Write (CPU.Registers, Rt_Index, 1);

         else

            PSX.Register.Write (CPU.Registers, Rt_Index, 0);

         end if;

      end if;

      --  ANDI
      if Opcode_Value = 12 then

         PSX.Register.Write
           (CPU.Registers,
            Rt_Index,
            Rs_Value and Zero_Extend_16 (PSX.Types.Word16 (Immediate_Value)));
      end if;

      --  ORI
      if Opcode_Value = 13 then

         PSX.Register.Write
           (CPU.Registers,
            Rt_Index,
            Rs_Value or Zero_Extend_16 (PSX.Types.Word16 (Immediate_Value)));

      end if;

      --  XORI
      if Opcode_Value = 14 then

         PSX.Register.Write
           (CPU.Registers,
            Rt_Index,
            Rs_Value xor Zero_Extend_16 (PSX.Types.Word16 (Immediate_Value)));

      end if;

      --  LUI
      if Opcode_Value = 15 then

         PSX.Register.Write
           (CPU.Registers,
            Rt_Index,
            Interfaces.Shift_Left (Immediate_Value, 16));

      end if;

      --  BEQ
      if Opcode_Value = 4 then

         --  Por defecto: no tomado.
         CPU.Next_PC := CPU.PC + 4;

         --  Si son iguales: branch tomado.
         if Rs_Value = Rt_Value then

            CPU.Next_PC :=
              CPU.PC
              + 4
              + Interfaces.Shift_Left
                  (Sign_Extend_16 (PSX.Types.Word16 (Immediate_Value)), 2);

         end if;

      end if;

      --  BNE

      if Opcode_Value = 5 then

         --  Por defecto: branch no tomado.
         CPU.Next_PC := CPU.PC + 4;

         --  Si son diferentes: branch tomado.
         if Rs_Value /= Rt_Value then

            CPU.Next_PC :=
              CPU.PC
              + 4
              + Interfaces.Shift_Left
                  (Sign_Extend_16 (PSX.Types.Word16 (Immediate_Value)), 2);

         end if;

      end if;

      --  BLEZ

      if Opcode_Value = 6 then

         --  Por defecto: branch no tomado.
         CPU.Next_PC := CPU.PC + 4;

         --  Si es menor o igual a cero: branch tomado.
         if To_Signed_32 (Rs_Value) <= 0 then

            CPU.Next_PC :=
              CPU.PC
              + 4
              + Interfaces.Shift_Left
                  (Sign_Extend_16 (PSX.Types.Word16 (Immediate_Value)), 2);

         end if;

      end if;

      --  BGTZ

      if Opcode_Value = 7 then

         --  Por defecto: branch no tomado.
         CPU.Next_PC := CPU.PC + 4;

         --  Si es mayor que cero: branch tomado.
         if To_Signed_32 (Rs_Value) > 0 then

            CPU.Next_PC :=
              CPU.PC
              + 4
              + Interfaces.Shift_Left
                  (Sign_Extend_16 (PSX.Types.Word16 (Immediate_Value)), 2);

         end if;

      end if;

      --  BLTZ

      if Opcode_Value = 1 and PSX.CPU.Instruction.Rt (Inst) = 0 then

         --  Por defecto: branch no tomado.
         CPU.Next_PC := CPU.PC + 4;

         --  Si es menor que cero: branch tomado.
         if To_Signed_32 (Rs_Value) < 0 then

            CPU.Next_PC :=
              CPU.PC
              + 4
              + Interfaces.Shift_Left
                  (Sign_Extend_16 (PSX.Types.Word16 (Immediate_Value)), 2);

         end if;

      end if;

      --  BGEZ

      if Opcode_Value = 1 and PSX.CPU.Instruction.Rt (Inst) = 1 then

         --  Por defecto: branch no tomado.
         CPU.Next_PC := CPU.PC + 4;

         --  Si es mayor o igual que cero: branch tomado.
         if To_Signed_32 (Rs_Value) >= 0 then

            CPU.Next_PC :=
              CPU.PC
              + 4
              + Interfaces.Shift_Left
                  (Sign_Extend_16 (PSX.Types.Word16 (Immediate_Value)), 2);

         end if;

      end if;

      --  J
      if Opcode_Value = 2 then
         CPU.Next_PC :=
           (CPU.PC + 4 and 16#F000_0000#)
           or Interfaces.Shift_Left (PSX.CPU.Instruction.Target (Inst), 2);
      end if;

      --  JAL
      if Opcode_Value = 3 then
         --  Return address is the instruction after the delay slot.
         PSX.Register.Write (CPU.Registers, 31, CPU.PC + 8);

         --  Schedule the jump target.
         CPU.Next_PC :=
           (CPU.PC + 4 and 16#F000_0000#)
           or Interfaces.Shift_Left (PSX.CPU.Instruction.Target (Inst), 2);
      end if;

      --  LB
      if Opcode_Value = 32 then

         PSX.Register.Write
           (CPU.Registers,
            Rt_Index,
            Sign_Extend_8 (PSX.Memory.Read_8 (Memory, Effective_Address)));

      end if;

      --  LBU
      if Opcode_Value = 36 then

         PSX.Register.Write
           (CPU.Registers,
            Rt_Index,
            PSX.Types.Word32 (PSX.Memory.Read_8 (Memory, Effective_Address)));

      end if;

      --  LH
      if Opcode_Value = 33 then

         PSX.Register.Write
           (CPU.Registers,
            Rt_Index,
            Sign_Extend_16 (PSX.Memory.Read_16 (Memory, Effective_Address)));

      end if;

      --  LHU
      if Opcode_Value = 37 then

         PSX.Register.Write
           (CPU.Registers,
            Rt_Index,
            PSX.Types.Word32 (PSX.Memory.Read_16 (Memory, Effective_Address)));

      end if;

      --  LW
      if Opcode_Value = 35 then

         PSX.Register.Write
           (CPU.Registers,
            Rt_Index,
            PSX.Memory.Read_32 (Memory, Effective_Address));

      end if;

      --  SB
      if Opcode_Value = 40 then

         PSX.Memory.Write_8
           (Memory,
            Effective_Address,
            PSX.Types.Word8 (Rt_Value and 16#0000_00FF#));

      end if;

      --  SH
      if Opcode_Value = 41 then

         PSX.Memory.Write_16
           (Memory,
            Effective_Address,
            PSX.Types.Word16 (Rt_Value and 16#0000_FFFF#));

      end if;

      --  SW
      if Opcode_Value = 43 then

         PSX.Memory.Write_32 (Memory, Effective_Address, Rt_Value);

      end if;

   end Execute;

end PSX.CPU.Execute;
