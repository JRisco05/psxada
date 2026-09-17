with Ada.Text_IO;
with Interfaces;
with PSX.CPU;
with PSX.CPU.Execute;
with PSX.CPU.Instruction;
with PSX.Register;
with PSX.Memory;
with PSX.CPU.Fetch;

use type PSX.CPU.Exception_Code;

procedure Psx_Cpu_Execute_Tests is

   use type Interfaces.Unsigned_32;

   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;
   Inst   : PSX.CPU.Instruction.Instruction;

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Ada.Text_IO.Put_Line ("FAIL: " & Message);
         raise Program_Error;
      end if;
   end Assert;

begin
   Ada.Text_IO.Put_Line ("Testing PSX.CPU.Execute...");
   Ada.Text_IO.New_Line;

   --------------------------------------------------
   --  R0 invariant
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 123);

   --  ADD R0, R1, R1
   Inst.Raw := 16#0021_0020#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert
     (PSX.Register.Read (CPU.Registers, 0) = 0, "R0 remains zero after ADD");

   Ada.Text_IO.Put_Line ("PASS: R0 invariant");

   --------------------------------------------------
   --  SLL
   --------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   PSX.Register.Write (CPU.Registers, 2, 1);

   --  SLL R1, R2, 4
   Inst.Raw := 16#0002_0900#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 1) = 16, "SLL R1,R2,4");

   Ada.Text_IO.Put_Line ("PASS: SLL");

   --------------------------------------------------
   --  SRL
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 2, 16);

   --  SRL R1, R2, 2
   Inst.Raw := 16#0002_0882#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 1) = 4, "SRL R1,R2,2");

   Ada.Text_IO.Put_Line ("PASS: SRL");

   --------------------------------------------------
   --  SRA
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 2, 16#8000_0000#);

   --  SRA R1, R2, 1
   Inst.Raw := 16#0002_0843#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 16#C000_0000#, "SRA R1,R2,1");

   Ada.Text_IO.Put_Line ("PASS: SRA");

   --------------------------------------------------
   --  SLLV
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 2); --  Rs = shift amount
   PSX.Register.Write (CPU.Registers, 2, 3); --  Rt = value

   --  SLLV R3, R2, R1
   Inst.Raw := 16#0022_18C4#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 3) = 12, "SLLV positive");

   Ada.Text_IO.Put_Line ("PASS: SLLV positive");

   --------------------------------------------------
   --  SLLV zero shift
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 0);
   PSX.Register.Write (CPU.Registers, 2, 16#1234_5678#);

   --  SLLV R3, R2, R1
   Inst.Raw := 16#0022_18C4#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 3) = 16#1234_5678#, "SLLV zero");

   Ada.Text_IO.Put_Line ("PASS: SLLV zero");

   --------------------------------------------------
   --  SLLV shift 31
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 31);
   PSX.Register.Write (CPU.Registers, 2, 1);

   --  SLLV R3, R2, R1
   Inst.Raw := 16#0022_18C4#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 3) = 16#8000_0000#, "SLLV 31");

   Ada.Text_IO.Put_Line ("PASS: SLLV 31");

   --------------------------------------------------
   --  SRLV
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 2); --  Rs = shift amount
   PSX.Register.Write (CPU.Registers, 2, 16#0000_000C#); --  Rt = value

   --  SRLV R3, R2, R1
   Inst.Raw := 16#0022_18C6#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 3) = 3, "SRLV positive");

   Ada.Text_IO.Put_Line ("PASS: SRLV positive");

   --------------------------------------------------
   --  SRLV zero shift
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 0);
   PSX.Register.Write (CPU.Registers, 2, 16#1234_5678#);

   --  SRLV R3, R2, R1
   Inst.Raw := 16#0022_18C6#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 3) = 16#1234_5678#, "SRLV zero");

   Ada.Text_IO.Put_Line ("PASS: SRLV zero");

   --------------------------------------------------
   --  SRLV shift 31
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 31);
   PSX.Register.Write (CPU.Registers, 2, 16#8000_0000#);

   --  SRLV R3, R2, R1
   Inst.Raw := 16#0022_18C6#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 3) = 1, "SRLV 31");

   Ada.Text_IO.Put_Line ("PASS: SRLV 31");

   --------------------------------------------------
   --  SRAV
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 2); --  Rs = shift amount
   PSX.Register.Write (CPU.Registers, 2, 16#FFFF_FFF0#); --  Rt = -16

   --  SRAV R3, R2, R1
   Inst.Raw := 16#0022_18C7#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert
     (PSX.Register.Read (CPU.Registers, 3) = 16#FFFF_FFFC#, "SRAV negative");

   Ada.Text_IO.Put_Line ("PASS: SRAV negative");

   --------------------------------------------------
   --  SRAV zero shift
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 0);
   PSX.Register.Write (CPU.Registers, 2, 16#8000_0000#);

   --  SRAV R3, R2, R1
   Inst.Raw := 16#0022_18C7#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 3) = 16#8000_0000#, "SRAV zero");

   Ada.Text_IO.Put_Line ("PASS: SRAV zero");

   --------------------------------------------------
   --  SRAV positive
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 3);
   PSX.Register.Write (CPU.Registers, 2, 40);

   --  SRAV R3, R2, R1
   Inst.Raw := 16#0022_18C7#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 3) = 5, "SRAV positive");

   Ada.Text_IO.Put_Line ("PASS: SRAV positive");

   --------------------------------------------------
   --  ADD
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 2, 10);
   PSX.Register.Write (CPU.Registers, 3, 20);

   --  ADD R1, R2, R3
   Inst.Raw := 16#0043_0820#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 1) = 30, "ADD R1,R2,R3");

   Ada.Text_IO.Put_Line ("PASS: ADD");

   --------------------------------------------------
   --  ADD overflow
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   CPU.PC := 16#0001_0000#;

   PSX.Register.Write (CPU.Registers, 2, 16#7FFF_FFFF#);
   PSX.Register.Write (CPU.Registers, 3, 1);
   PSX.Register.Write (CPU.Registers, 1, 16#1234_5678#);

   --  ADD R1, R2, R3
   Inst.Raw := 16#0043_0820#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Exception_Pending, "ADD overflow exception");
   Assert (CPU.Cause = PSX.CPU.Overflow, "ADD overflow cause");
   --  Assert (CPU.EPC = 16#0001_0000#, "ADD overflow EPC");
   Ada.Text_IO.Put_Line
     ("DEBUG EPC = " & Interfaces.Unsigned_32'Image (CPU.EPC));

   Assert (CPU.EPC = 16#0001_0000#, "ADD overflow EPC");

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 16#1234_5678#,
      "ADD overflow modified destination");

   Ada.Text_IO.Put_Line ("PASS: ADD overflow");

   --------------------------------------------------
   --  ADDU
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 10);
   PSX.Register.Write (CPU.Registers, 2, 20);

   --  ADDU R3, R1, R2
   Inst.Raw := 16#0022_1821#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 3) = 30, "ADDU positive");

   Ada.Text_IO.Put_Line ("PASS: ADDU positive");

   --------------------------------------------------
   --  ADDU overflow
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 16#FFFF_FFFF#);
   PSX.Register.Write (CPU.Registers, 2, 1);

   --  ADDU R3, R1, R2
   Inst.Raw := 16#0022_1821#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 3) = 0, "ADDU overflow");

   Ada.Text_IO.Put_Line ("PASS: ADDU overflow");

   --------------------------------------------------
   --  SUB
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 2, 30);
   PSX.Register.Write (CPU.Registers, 3, 10);

   --  SUB R1, R2, R3
   Inst.Raw := 16#0043_0822#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 1) = 20, "SUB R1,R2,R3");

   Ada.Text_IO.Put_Line ("PASS: SUB");

   --------------------------------------------------
   --  SUB overflow
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   CPU.PC := 16#0002_0000#;

   PSX.Register.Write (CPU.Registers, 2, 16#8000_0000#);
   PSX.Register.Write (CPU.Registers, 3, 1);
   PSX.Register.Write (CPU.Registers, 1, 16#1234_5678#);

   --  SUB R1, R2, R3
   Inst.Raw := 16#0043_0822#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Exception_Pending, "SUB overflow exception");
   Assert (CPU.Cause = PSX.CPU.Overflow, "SUB overflow cause");
   Assert (CPU.EPC = 16#0002_0000#, "SUB overflow EPC");
   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 16#1234_5678#,
      "SUB overflow modified destination");

   Ada.Text_IO.Put_Line ("PASS: SUB overflow");

   --------------------------------------------------
   --  SUBU
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 2, 30);
   PSX.Register.Write (CPU.Registers, 3, 10);

   --  SUBU R1, R2, R3
   Inst.Raw := 16#0043_0823#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 1) = 20, "SUBU positive");

   Ada.Text_IO.Put_Line ("PASS: SUBU positive");

   --------------------------------------------------
   --  SUBU underflow
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 2, 0);
   PSX.Register.Write (CPU.Registers, 3, 1);

   --  SUBU R1, R2, R3
   Inst.Raw := 16#0043_0823#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 16#FFFF_FFFF#, "SUBU underflow");

   Ada.Text_IO.Put_Line ("PASS: SUBU underflow");

   --------------------------------------------------
   --  AND
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 2, 16#0F0F_0F0F#);
   PSX.Register.Write (CPU.Registers, 3, 16#00FF_00FF#);

   --  AND R1, R2, R3
   Inst.Raw := 16#0043_0824#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 16#000F_000F#, "AND R1,R2,R3");

   Ada.Text_IO.Put_Line ("PASS: AND");

   --------------------------------------------------
   --  OR
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 2, 16#0F0F_0F0F#);
   PSX.Register.Write (CPU.Registers, 3, 16#00FF_00FF#);

   --  OR R1, R2, R3
   Inst.Raw := 16#0043_0825#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 16#0FFF_0FFF#, "OR R1,R2,R3");

   Ada.Text_IO.Put_Line ("PASS: OR");

   --------------------------------------------------
   --  XOR
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 2, 16#0F0F_0F0F#);
   PSX.Register.Write (CPU.Registers, 3, 16#00FF_00FF#);

   --  XOR R1, R2, R3
   Inst.Raw := 16#0043_0826#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 16#0FF0_0FF0#, "XOR R1,R2,R3");

   Ada.Text_IO.Put_Line ("PASS: XOR");

   --------------------------------------------------
   --  NOR
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 2, 16#0F0F_0F0F#);
   PSX.Register.Write (CPU.Registers, 3, 16#00FF_00FF#);

   --  NOR R1, R2, R3
   Inst.Raw := 16#0043_0827#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 16#F000_F000#, "NOR R1,R2,R3");

   Ada.Text_IO.Put_Line ("PASS: NOR");

   --------------------------------------------------
   --  JR
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   CPU.PC := 16#8000_1000#;

   PSX.Register.Write (CPU.Registers, 31, 16#8000_2000#);

   --  JR R31
   Inst.Raw := 16#03E0_0008#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#8000_2000#, "JR R31");

   Ada.Text_IO.Put_Line ("PASS: JR");

   --------------------------------------------------
   --  JALR
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   CPU.PC := 16#8000_1000#;

   PSX.Register.Write (CPU.Registers, 4, 16#8000_2000#);

   --  JALR R31, R4
   Inst.Raw := 16#0080_F809#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#8000_2000#, "JALR PC");

   Assert
     (PSX.Register.Read (CPU.Registers, 31) = 16#8000_1008#,
      "JALR return address");

   Ada.Text_IO.Put_Line ("PASS: JALR");

   --------------------------------------------------
   --  ADDI
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   --  R2 = 10
   PSX.Register.Write (CPU.Registers, 2, 10);

   --  ADDI R1, R2, 5
   Inst.Raw := 16#2041_0005#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 1) = 15, "ADDI positive");

   Ada.Text_IO.Put_Line ("PASS: ADDI positive");

   --  ADDI R1, R2, -5
   Inst.Raw := 16#2041_FFFB#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 1) = 5, "ADDI negative");

   Ada.Text_IO.Put_Line ("PASS: ADDI negative");

   --------------------------------------------------
   --  ADDI overflow
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   CPU.PC := 16#0003_0000#;

   PSX.Register.Write (CPU.Registers, 2, 16#7FFF_FFFF#);
   PSX.Register.Write (CPU.Registers, 3, 16#1234_5678#);

   --  ADDI R3, R2, 1
   Inst.Raw := 16#2043_0001#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Exception_Pending, "ADDI overflow exception");
   Assert (CPU.Cause = PSX.CPU.Overflow, "ADDI overflow cause");
   Assert (CPU.EPC = 16#0003_0000#, "ADDI overflow EPC");
   Assert
     (PSX.Register.Read (CPU.Registers, 3) = 16#1234_5678#,
      "ADDI overflow modified destination");

   Ada.Text_IO.Put_Line ("PASS: ADDI overflow");

   --------------------------------------------------
   --  ADDIU
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 2, 10);
   PSX.Register.Write (CPU.Registers, 3, 20);

   --  ADDIU R1, R2, 20
   Inst.Raw := 16#2441_0014#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 1) = 30, "ADDIU R1,R2,20");

   Assert (CPU.Exception_Pending = False, "ADDIU exception");

   Ada.Text_IO.Put_Line ("PASS: ADDIU");

   --------------------------------------------------
   --  ADDIU overflow
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 2, 16#7FFF_FFFF#);
   PSX.Register.Write (CPU.Registers, 3, 16#1234_5678#);

   --  ADDIU R3, R2, 1
   Inst.Raw := 16#2443_0001#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert
     (PSX.Register.Read (CPU.Registers, 3) = 16#8000_0000#,
      "ADDIU overflow result");

   Assert (CPU.Exception_Pending = False, "ADDIU overflow exception");

   Ada.Text_IO.Put_Line ("PASS: ADDIU overflow");

   --------------------------------------------------
   --  ANDI
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   --  R2 = 16#0000_FF0F#
   PSX.Register.Write (CPU.Registers, 2, 16#0000_FF0F#);

   --  ANDI R1, R2, 16#00FF#
   Inst.Raw := 16#3041_00FF#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 1) = 16#0000_000F#, "ANDI");

   Ada.Text_IO.Put_Line ("PASS: ANDI");

   --------------------------------------------------
   --  ORI
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   --  R2 = 16#0000_F000#
   PSX.Register.Write (CPU.Registers, 2, 16#0000_F000#);

   --  ORI R1, R2, 16#000F#
   Inst.Raw := 16#3441_000F#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 1) = 16#0000_F00F#, "ORI");

   Ada.Text_IO.Put_Line ("PASS: ORI");

   --------------------------------------------------
   --  XORI
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   --  R2 = 16#0000_FF00#
   PSX.Register.Write (CPU.Registers, 2, 16#0000_FF00#);

   --  XORI R1, R2, 16#00FF#
   Inst.Raw := 16#3841_00FF#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 1) = 16#0000_FFFF#, "XORI");

   Ada.Text_IO.Put_Line ("PASS: XORI");

   --------------------------------------------------
   --  LUI
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   --  LUI R1, 16#1234#
   Inst.Raw := 16#3C01_1234#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 1) = 16#1234_0000#, "LUI");

   Ada.Text_IO.Put_Line ("PASS: LUI");

   --------------------------------------------------
   --  BEQ taken
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 10);

   PSX.Register.Write (CPU.Registers, 2, 10);

   CPU.PC := 16#1000#;

   --  BEQ R1, R2, 2
   Inst.Raw := 16#1022_0002#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#100C#, "BEQ taken");

   Ada.Text_IO.Put_Line ("PASS: BEQ taken");

   --------------------------------------------------
   --  BEQ not taken
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 10);

   PSX.Register.Write (CPU.Registers, 2, 20);

   CPU.PC := 16#1000#;

   --  BEQ R1, R2, 2
   Inst.Raw := 16#1022_0002#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#1004#, "BEQ not taken");

   Ada.Text_IO.Put_Line ("PASS: BEQ not taken");

   --------------------------------------------------
   --  BEQ negative offset
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 10);

   PSX.Register.Write (CPU.Registers, 2, 10);

   CPU.PC := 16#1000#;

   --  BEQ R1, R2, -2
   Inst.Raw := 16#1022_FFFE#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#0FFC#, "BEQ negative offset");

   Ada.Text_IO.Put_Line ("PASS: BEQ negative offset");

   --------------------------------------------------
   --  BNE taken
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 10);
   PSX.Register.Write (CPU.Registers, 2, 20);

   CPU.PC := 16#1000#;

   --  BNE R1, R2, 2
   Inst.Raw := 16#1422_0002#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#100C#, "BNE taken");

   Ada.Text_IO.Put_Line ("PASS: BNE taken");

   --------------------------------------------------
   --  BNE not taken
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 10);
   PSX.Register.Write (CPU.Registers, 2, 10);

   CPU.PC := 16#1000#;

   Inst.Raw := 16#1422_0002#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#1004#, "BNE not taken");

   Ada.Text_IO.Put_Line ("PASS: BNE not taken");

   --------------------------------------------------
   --  BNE negative offset
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 10);
   PSX.Register.Write (CPU.Registers, 2, 20);

   CPU.PC := 16#1000#;

   --  BNE R1, R2, -2
   Inst.Raw := 16#1422_FFFE#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#0FFC#, "BNE negative offset");

   Ada.Text_IO.Put_Line ("PASS: BNE negative offset");

   --------------------------------------------------
   --  BLEZ zero
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 0);

   CPU.PC := 16#1000#;

   --  BLEZ R1, 2
   Inst.Raw := 16#1820_0002#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#100C#, "BLEZ zero");

   Ada.Text_IO.Put_Line ("PASS: BLEZ zero");

   --------------------------------------------------
   --  BLEZ negative
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 16#FFFF_FFFF#);

   CPU.PC := 16#1000#;

   --  BLEZ R1, 2
   Inst.Raw := 16#1820_0002#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#100C#, "BLEZ negative");

   Ada.Text_IO.Put_Line ("PASS: BLEZ negative");

   --------------------------------------------------
   --  BLEZ positive
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 1);

   CPU.PC := 16#1000#;

   --  BLEZ R1, 2
   Inst.Raw := 16#1820_0002#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#1004#, "BLEZ positive");

   Ada.Text_IO.Put_Line ("PASS: BLEZ positive");

   --------------------------------------------------
   --  BGTZ positive
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 1);

   CPU.PC := 16#1000#;

   --  BGTZ R1, 2
   Inst.Raw := 16#1C20_0002#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#100C#, "BGTZ positive");

   Ada.Text_IO.Put_Line ("PASS: BGTZ positive");

   --------------------------------------------------
   --  BGTZ zero
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 0);

   CPU.PC := 16#1000#;

   --  BGTZ R1, 2
   Inst.Raw := 16#1C20_0002#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#1004#, "BGTZ zero");

   Ada.Text_IO.Put_Line ("PASS: BGTZ zero");

   --------------------------------------------------
   --  BGTZ negative
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 16#FFFF_FFFF#);

   CPU.PC := 16#1000#;

   --  BGTZ R1, 2
   Inst.Raw := 16#1C20_0002#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#1004#, "BGTZ negative");

   Ada.Text_IO.Put_Line ("PASS: BGTZ negative");

   --------------------------------------------------
   --  J
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   CPU.PC := 16#1000_0000#;

   --   J 0x00001234
   Inst.Raw := 16#0800_048D#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#1000_1234#, "J");

   Ada.Text_IO.Put_Line ("PASS: J");

   --------------------------------------------------
   --  JAL
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   CPU.PC := 16#1000_0000#;

   --  JAL 0x00001234
   Inst.Raw := 16#0C00_048D#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#1000_1234#, "JAL PC");

   Assert (PSX.Register.Read (CPU.Registers, 31) = 16#1000_0008#, "JAL R31");

   Ada.Text_IO.Put_Line ("PASS: JAL");

   --------------------------------------------------
   --  SLT
   --------------------------------------------------
   --  SLT R3, R1, R2
   --  5 < 10 -> 1

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 5);
   PSX.Register.Write (CPU.Registers, 2, 10);

   Inst.Raw := 16#0022_182A#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 3) = 1, "SLT positive");

   Ada.Text_IO.Put_Line ("PASS: SLT positive");

   --------------------------------------------------
   --  SLT false
   --------------------------------------------------
   --  SLT R3, R1, R2
   --  10 < 5 -> 0

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 10);
   PSX.Register.Write (CPU.Registers, 2, 5);

   Inst.Raw := 16#0022_182A#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 3) = 0, "SLT false");

   Ada.Text_IO.Put_Line ("PASS: SLT false");

   --------------------------------------------------
   --  SLT negative
   --------------------------------------------------
   --  SLT R3, R1, R2
   --  -1 < 1 -> 1

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 16#FFFF_FFFF#);

   PSX.Register.Write (CPU.Registers, 2, 1);

   Inst.Raw := 16#0022_182A#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 3) = 1, "SLT negative");

   Ada.Text_IO.Put_Line ("PASS: SLT negative");

   --------------------------------------------------
   --  SLTU positive
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 5);
   PSX.Register.Write (CPU.Registers, 2, 10);

   --  SLTU R3, R1, R2
   Inst.Raw := 16#0022_182B#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 3) = 1, "SLTU positive");

   Ada.Text_IO.Put_Line ("PASS: SLTU positive");

   --------------------------------------------------
   --  SLTU false
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 10);
   PSX.Register.Write (CPU.Registers, 2, 5);

   --  SLTU R3, R1, R2
   Inst.Raw := 16#0022_182B#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 3) = 0, "SLTU false");

   Ada.Text_IO.Put_Line ("PASS: SLTU false");

   --------------------------------------------------
   --  SLTU unsigned difference
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 16#FFFF_FFFF#);
   PSX.Register.Write (CPU.Registers, 2, 1);

   --  SLTU R3, R1, R2
   Inst.Raw := 16#0022_182B#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert
     (PSX.Register.Read (CPU.Registers, 3) = 0, "SLTU unsigned difference");

   Ada.Text_IO.Put_Line ("PASS: SLTU unsigned difference");

   --------------------------------------------------
   --  MULT positive
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 2);
   PSX.Register.Write (CPU.Registers, 2, 3);

   --  MULT R1, R2
   Inst.Raw := 16#0022_0018#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.LO = 6, "MULT positive LO");
   Assert (CPU.HI = 0, "MULT positive HI");

   Ada.Text_IO.Put_Line ("PASS: MULT positive");

   --------------------------------------------------
   --  MULT negative
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 16#FFFF_FFFE#);
   PSX.Register.Write (CPU.Registers, 2, 3);

   --  MULT R1, R2
   Inst.Raw := 16#0022_0018#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.LO = 16#FFFF_FFFA#, "MULT negative LO");
   Assert (CPU.HI = 16#FFFF_FFFF#, "MULT negative HI");

   Ada.Text_IO.Put_Line ("PASS: MULT negative");

   --------------------------------------------------
   --  MULT negative x negative
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 16#FFFF_FFFE#);
   PSX.Register.Write (CPU.Registers, 2, 16#FFFF_FFFD#);

   --  MULT R1, R2
   Inst.Raw := 16#0022_0018#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.LO = 6, "MULT negative negative LO");
   Assert (CPU.HI = 0, "MULT negative negative HI");

   Ada.Text_IO.Put_Line ("PASS: MULT negative negative");

   --------------------------------------------------
   --  MULT zero
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 0);
   PSX.Register.Write (CPU.Registers, 2, 123);

   --  MULT R1, R2
   Inst.Raw := 16#0022_0018#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.LO = 0, "MULT zero LO");
   Assert (CPU.HI = 0, "MULT zero HI");

   Ada.Text_IO.Put_Line ("PASS: MULT zero");

   --------------------------------------------------
   --  MULTU positive
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 2);
   PSX.Register.Write (CPU.Registers, 2, 3);

   --  MULTU R1, R2
   Inst.Raw := 16#0022_0019#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.LO = 6, "MULTU positive LO");
   Assert (CPU.HI = 0, "MULTU positive HI");

   Ada.Text_IO.Put_Line ("PASS: MULTU positive");

   --------------------------------------------------
   --  MULTU unsigned
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 16#FFFF_FFFF#);
   PSX.Register.Write (CPU.Registers, 2, 2);

   --  MULTU R1, R2
   Inst.Raw := 16#0022_0019#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.LO = 16#FFFF_FFFE#, "MULTU unsigned LO");
   Assert (CPU.HI = 1, "MULTU unsigned HI");

   Ada.Text_IO.Put_Line ("PASS: MULTU unsigned");

   --------------------------------------------------
   --  MULTU zero
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 0);
   PSX.Register.Write (CPU.Registers, 2, 16#FFFF_FFFF#);

   --  MULTU R1, R2
   Inst.Raw := 16#0022_0019#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.LO = 0, "MULTU zero LO");
   Assert (CPU.HI = 0, "MULTU zero HI");

   Ada.Text_IO.Put_Line ("PASS: MULTU zero");

   --------------------------------------------------
   --  MFHI
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   CPU.HI := 16#1234_5678#;

   --  MFHI R3
   Inst.Raw := 16#0000_1810#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 3) = 16#1234_5678#, "MFHI");

   Ada.Text_IO.Put_Line ("PASS: MFHI");

   --------------------------------------------------
   --  MFLO
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   CPU.LO := 16#8765_4321#;

   --  MFLO R3
   Inst.Raw := 16#0000_1812#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 3) = 16#8765_4321#, "MFLO");

   Ada.Text_IO.Put_Line ("PASS: MFLO");

   --------------------------------------------------
   --  MTHI
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 3, 16#1234_5678#);

   --  MTHI R3
   Inst.Raw := 16#0060_0011#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.HI = 16#1234_5678#, "MTHI");

   Ada.Text_IO.Put_Line ("PASS: MTHI");

   --------------------------------------------------
   --  MTLO
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 3, 16#8765_4321#);

   --  MTLO R3
   Inst.Raw := 16#0060_0013#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.LO = 16#8765_4321#, "MTLO");

   Ada.Text_IO.Put_Line ("PASS: MTLO");

   --------------------------------------------------
   --  DIV positive
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 10);
   PSX.Register.Write (CPU.Registers, 2, 3);

   --  DIV R1, R2
   Inst.Raw := 16#0022_001A#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.LO = 3, "DIV positive quotient");
   Assert (CPU.HI = 1, "DIV positive remainder");

   Ada.Text_IO.Put_Line ("PASS: DIV positive");

   --------------------------------------------------
   --  DIV negative
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 16#FFFF_FFF6#);
   PSX.Register.Write (CPU.Registers, 2, 3);

   --  DIV R1, R2
   Inst.Raw := 16#0022_001A#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.LO = 16#FFFF_FFFD#, "DIV negative quotient");
   Assert (CPU.HI = 16#FFFF_FFFF#, "DIV negative remainder");

   Ada.Text_IO.Put_Line ("PASS: DIV negative");

   --------------------------------------------------
   --  DIV negative negative
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 16#FFFF_FFF6#);
   PSX.Register.Write (CPU.Registers, 2, 16#FFFF_FFFD#);

   --  DIV R1, R2
   Inst.Raw := 16#0022_001A#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.LO = 3, "DIV negative negative quotient");
   Assert (CPU.HI = 16#FFFF_FFFF#, "DIV negative negative remainder");

   Ada.Text_IO.Put_Line ("PASS: DIV negative negative");

   --------------------------------------------------
   --  DIV remainder
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 17);
   PSX.Register.Write (CPU.Registers, 2, 5);

   --  DIV R1, R2
   Inst.Raw := 16#0022_001A#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.LO = 3, "DIV remainder quotient");
   Assert (CPU.HI = 2, "DIV remainder");

   Ada.Text_IO.Put_Line ("PASS: DIV remainder");

   --------------------------------------------------
   --  DIV zero
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 123);
   PSX.Register.Write (CPU.Registers, 2, 0);

   --  DIV R1, R2
   Inst.Raw := 16#0022_001A#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Exception_Pending = False, "DIV zero exception");

   Ada.Text_IO.Put_Line ("PASS: DIV zero");

   --------------------------------------------------
   --  DIVU positive
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 20);
   PSX.Register.Write (CPU.Registers, 2, 6);

   --  DIVU R1, R2
   Inst.Raw := 16#0022_001B#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.LO = 3, "DIVU positive quotient");
   Assert (CPU.HI = 2, "DIVU positive remainder");

   Ada.Text_IO.Put_Line ("PASS: DIVU positive");

   --------------------------------------------------
   --  DIVU unsigned
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 16#FFFF_FFFF#);
   PSX.Register.Write (CPU.Registers, 2, 2);

   --  DIVU R1, R2
   Inst.Raw := 16#0022_001B#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.LO = 16#7FFF_FFFF#, "DIVU unsigned quotient");
   Assert (CPU.HI = 1, "DIVU unsigned remainder");

   Ada.Text_IO.Put_Line ("PASS: DIVU unsigned");

   --------------------------------------------------
   --  DIVU zero
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 123);
   PSX.Register.Write (CPU.Registers, 2, 0);

   --  DIVU R1, R2
   Inst.Raw := 16#0022_001B#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Exception_Pending = False, "DIVU zero exception");

   Ada.Text_IO.Put_Line ("PASS: DIVU zero");

   --------------------------------------------------
   --  SYSCALL
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   CPU.PC := 16#8000_1000#;

   --  SYSCALL
   --  opcode = 0
   --  funct = 12
   Inst.Raw := 16#0000_000C#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Exception_Pending = True, "SYSCALL exception pending");

   Assert (CPU.Cause = PSX.CPU.Syscall, "SYSCALL cause");

   Assert (CPU.EPC = 16#8000_1000#, "SYSCALL EPC");

   Ada.Text_IO.Put_Line ("PASS: SYSCALL");

   --------------------------------------------------
   --  BREAK
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   CPU.PC := 16#8000_1000#;

   --  BREAK
   Inst.Raw := 16#0000_000D#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Exception_Pending, "BREAK exception");
   Assert (CPU.Cause = PSX.CPU.Break, "BREAK cause");
   Assert (CPU.EPC = 16#8000_1000#, "BREAK EPC");

   Ada.Text_IO.Put_Line ("PASS: BREAK");

   --------------------------------------------------
   --  SLTI
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 10);

   --  SLTI R2, R1, 20
   Inst.Raw := 16#2822_0014#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 2) = 1, "SLTI positive");

   Ada.Text_IO.Put_Line ("PASS: SLTI positive");

   --------------------------------------------------
   --  SLTI false
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 20);

   --  SLTI R2, R1, 10
   Inst.Raw := 16#2822_000A#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 2) = 0, "SLTI false");

   Ada.Text_IO.Put_Line ("PASS: SLTI false");

   --------------------------------------------------
   --  SLTI negative
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 16#FFFF_FFFF#);

   --  SLTI R2, R1, 1
   Inst.Raw := 16#2822_0001#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 2) = 1, "SLTI negative");

   Ada.Text_IO.Put_Line ("PASS: SLTI negative");

   --------------------------------------------------
   --  SLTIU
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 10);

   --  SLTIU R2, R1, 20
   Inst.Raw := 16#2C22_0014#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 2) = 1, "SLTIU positive");

   Ada.Text_IO.Put_Line ("PASS: SLTIU positive");

   --------------------------------------------------
   --  SLTIU false
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 20);

   --  SLTIU R2, R1, 10
   Inst.Raw := 16#2C22_000A#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (PSX.Register.Read (CPU.Registers, 2) = 0, "SLTIU false");

   Ada.Text_IO.Put_Line ("PASS: SLTIU false");

   --------------------------------------------------
   --  SLTIU unsigned difference
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 16#FFFF_FFFF#);

   --  SLTIU R2, R1, 1
   Inst.Raw := 16#2C22_0001#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert
     (PSX.Register.Read (CPU.Registers, 2) = 0, "SLTIU unsigned difference");

   Ada.Text_IO.Put_Line ("PASS: SLTIU unsigned difference");

   --------------------------------------------------
   --  BLTZ taken
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 16#FFFF_FFFF#);

   CPU.PC := 16#0000_1000#;

   --  BLTZ R1, +2
   Inst.Raw := 16#0420_0002#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#0000_100C#, "BLTZ taken");

   Ada.Text_IO.Put_Line ("PASS: BLTZ taken");

   --------------------------------------------------
   --  BLTZ not taken
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 1);

   CPU.PC := 16#0000_1000#;

   --  BLTZ R1, +2
   Inst.Raw := 16#0420_0002#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#0000_1004#, "BLTZ not taken");

   Ada.Text_IO.Put_Line ("PASS: BLTZ not taken");

   --------------------------------------------------
   --  BLTZ negative offset
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 16#FFFF_FFFF#);

   CPU.PC := 16#0000_1010#;

   --  BLTZ R1, -2
   Inst.Raw := 16#0420_FFFE#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#0000_100C#, "BLTZ negative offset");

   Ada.Text_IO.Put_Line ("PASS: BLTZ negative offset");

   --------------------------------------------------
   --  BGEZ taken
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 0);

   CPU.PC := 16#0000_1000#;

   --  BGEZ R1, +2
   Inst.Raw := 16#0421_0002#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#0000_100C#, "BGEZ taken");

   Ada.Text_IO.Put_Line ("PASS: BGEZ taken");

   --------------------------------------------------
   --  BGEZ not taken
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 16#FFFF_FFFF#);

   CPU.PC := 16#0000_1000#;

   --  BGEZ R1, +2
   Inst.Raw := 16#0421_0002#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#0000_1004#, "BGEZ not taken");

   Ada.Text_IO.Put_Line ("PASS: BGEZ not taken");

   --------------------------------------------------
   --  BGEZ negative offset
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   PSX.Register.Write (CPU.Registers, 1, 5);

   CPU.PC := 16#0000_1010#;

   --  BGEZ R1, -2
   Inst.Raw := 16#0421_FFFE#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Next_PC = 16#0000_100C#, "BGEZ negative offset");

   Ada.Text_IO.Put_Line ("PASS: BGEZ negative offset");

   --------------------------------------------------
   --  Exception Status
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   CPU.Status := 16#0000_003F#;
   CPU.PC := 16#8001_0000#;

   PSX.CPU.Enter_Exception (CPU);

   Assert (CPU.Status = 16#0000_003C#, "Exception Status stack");

   Assert (CPU.PC = 16#8000_0080#, "Exception vector");

   Assert
     ((CPU.Status and 16#0000_0003#) = 0, "Exception current IE/KU cleared");

   Assert (CPU.Exception_Pending = False, "Exception pending cleared");

   Ada.Text_IO.Put_Line ("PASS: Exception Status");

   --------------------------------------------------
   --  MTC0
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   --  T4 = value to write into COP0 Status ($12)
   PSX.Register.Write (CPU.Registers, 12, 16#0000_003F#);

   --  MTC0 $t4, $12
   --  opcode = 16
   --  rs     = 4
   --  rt     = 12
   --  rd     = 12
   Inst.Raw := 16#408C_6000#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Status = 16#0000_003F#, "MTC0 $t4,$12 writes Status");

   Ada.Text_IO.Put_Line ("PASS: MTC0 $t4,$12");

   --------------------------------------------------
   --  RFE
   --------------------------------------------------

   PSX.CPU.Reset (CPU);

   CPU.Status := 16#0000_003C#;

   --  RFE
   Inst.Raw := 16#4200_0010#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Status = 16#0000_000F#, "RFE Status restore");

   Ada.Text_IO.Put_Line ("PASS: RFE");

   --  ============================================================
   --  EXCEPTION / RFE TESTS
   --  ============================================================

   --  1. Enter Exception
   PSX.CPU.Reset (CPU);

   CPU.Status := 16#0000_001B#;
   CPU.PC := 16#8001_0000#;
   CPU.EPC := CPU.PC;
   CPU.Cause := PSX.CPU.Overflow;
   CPU.Exception_Pending := True;

   PSX.CPU.Enter_Exception (CPU);

   Assert (CPU.Status = 16#0000_002C#, "Enter Exception Status");

   Assert (CPU.PC = 16#8000_0080#, "Enter Exception Vector");

   Assert (CPU.EPC = 16#8001_0000#, "Enter Exception EPC");

   Assert (CPU.Cause = PSX.CPU.Overflow, "Enter Exception Cause");

   Assert (CPU.Exception_Pending = False, "Enter Exception Pending");

   Ada.Text_IO.Put_Line ("PASS: Enter Exception");

   --  2. RFE
   CPU.Status := 16#0000_002C#;

   Inst.Raw := 16#4200_0010#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Status = 16#0000_000B#, "RFE Status");

   Ada.Text_IO.Put_Line ("PASS: RFE");

   --  3. Enter Exception -> RFE
   PSX.CPU.Reset (CPU);

   CPU.Status := 16#0000_001B#;
   CPU.PC := 16#8001_0000#;
   CPU.EPC := CPU.PC;
   CPU.Cause := PSX.CPU.Overflow;
   CPU.Exception_Pending := True;

   --  Enter exception
   PSX.CPU.Enter_Exception (CPU);

   Assert (CPU.Status = 16#0000_002C#, "Exception Cycle - Enter");

   --  Return from exception
   Inst.Raw := 16#4200_0010#;

   PSX.CPU.Execute.Execute (CPU, Memory, Inst);

   Assert (CPU.Status = 16#0000_000B#, "Exception Cycle - RFE");

   Ada.Text_IO.Put_Line ("PASS: Enter Exception -> RFE");

   --------------------------------------------------
   --  FETCH
   --------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0000_1000#;

   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#0022_1820#);

   Inst := PSX.CPU.Fetch.Fetch (CPU, Memory);

   Assert (Inst.Raw = 16#0022_1820#, "FETCH instruction");

   Assert (CPU.PC = 16#0000_1000#, "FETCH does not modify PC");

   Ada.Text_IO.Put_Line ("PASS: FETCH");

   ----------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("All execution tests passed.");

end Psx_Cpu_Execute_Tests;
