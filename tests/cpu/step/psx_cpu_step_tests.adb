with Ada.Text_IO;
with PSX.CPU;
with PSX.Memory;
with PSX.Register;
with Interfaces;
with PSX.CPU.Step;
with PSX.CPU.Fetch;
with PSX.CPU.Instruction;
with PSX.Timers;

procedure Psx_Cpu_Step_Tests is

   Inst : PSX.CPU.Instruction.Instruction;

   use Ada.Text_IO;
   use type Interfaces.Unsigned_32;
   use type PSX.CPU.Exception_Code;

   CPU    : PSX.CPU.CPU_State;
   Memory : PSX.Memory.Memory_State;

   procedure Check (Condition : Boolean; Name : String) is
   begin
      if Condition then
         Put_Line ("PASS: " & Name);
      else
         Put_Line ("FAIL: " & Name);
         raise Program_Error;
      end if;
   end Check;

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Ada.Text_IO.Put_Line ("FAIL: " & Message);
         raise Program_Error;
      end if;
   end Assert;

begin

   Ada.Text_IO.Put_Line ("Testing PSX.CPU.Step...");
   Ada.Text_IO.New_Line;

   PSX.CPU.Reset (CPU);

   Check (CPU.PC = 16#BFC0_0000#, "RESET PC");

   Check (CPU.Next_PC = 16#BFC0_0004#, "RESET NEXT_PC");

   Check (not CPU.In_Delay_Slot, "RESET DELAY SLOT");

   ----------
   --  BIOS reset vector fetch

   PSX.Memory.Reset (Memory);

   PSX.CPU.Reset (CPU);

   PSX.Memory.Load_BIOS (Memory, "tests/memory/test_bios.bin");

   Inst := PSX.CPU.Fetch.Fetch (CPU, Memory);

   Check (Inst.Raw = 16#2401_000A#, "FETCH BIOS RESET VECTOR");

   --------------------------------------------------
   --  CPU STEP: EXECUTE CODE FROM BIOS
   --------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   PSX.Memory.Load_BIOS (Memory, "tests/memory/test_bios.bin");

   --  BFC00000:
   --  ADDIU R1, R0, 10
   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 10,
      "STEP BIOS executes ADDIU R1");

   Assert
     (CPU.PC = 16#BFC0_0004#, "STEP BIOS advances PC after first instruction");

   Assert
     (CPU.Next_PC = 16#BFC0_0008#,
      "STEP BIOS advances Next_PC after first instruction");

   --  BFC00004:
   --  ADDIU R2, R0, 20
   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (PSX.Register.Read (CPU.Registers, 2) = 20,
      "STEP BIOS executes ADDIU R2");

   Assert (CPU.PC = 16#BFC0_0008#, "STEP BIOS reaches third instruction");

   --  BFC00008:
   --  ADD R3, R1, R2
   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (PSX.Register.Read (CPU.Registers, 3) = 30, "STEP BIOS executes ADD");

   Assert (CPU.PC = 16#BFC0_000C#, "STEP BIOS advances after ADD");

   Ada.Text_IO.Put_Line ("PASS: STEP BIOS CODE EXECUTION");

   --------------------------------------------------
   --  CPU STEP: ADD
   --------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   --  ADD R1, R2, R3
   PSX.Register.Write (CPU.Registers, 2, 10);
   PSX.Register.Write (CPU.Registers, 3, 20);

   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#0043_0820#);

   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 30, "STEP executes instruction");

   Assert (CPU.PC = 16#0000_1004#, "STEP advances PC");

   Assert (CPU.Next_PC = 16#0000_1008#, "STEP advances Next_PC");

   Ada.Text_IO.Put_Line ("PASS: STEP ADD");

   --------------------------------------------------
   --  CPU STEP: JUMP
   --------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   --  J 0x00002000
   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#0800_0800#);

   --  Delay slot: ADD R1, R2, R3
   PSX.Register.Write (CPU.Registers, 2, 10);
   PSX.Register.Write (CPU.Registers, 3, 20);

   PSX.Memory.Write_32 (Memory, 16#0000_1004#, 16#0043_0820#);

   PSX.CPU.Step.Step (CPU, Memory);

   --  The jump itself executes, but the delay-slot
   --  instruction at 0x1004 must execute next.
   Assert (CPU.PC = 16#0000_1004#, "STEP J enters delay slot");

   Assert (CPU.Next_PC = 16#0000_2000#, "STEP J schedules target");

   --  Execute the delay slot.
   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 30, "STEP J executes delay slot");

   Assert (CPU.PC = 16#0000_2000#, "STEP J reaches target after delay slot");

   Assert (CPU.Next_PC = 16#0000_2004#, "STEP J advances target Next_PC");

   Ada.Text_IO.Put_Line ("PASS: STEP J");

   --------------------------------------------------
   --  CPU STEP: JAL
   --------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   --  JAL 0x00002000
   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#0C00_0800#);

   --  Delay slot: ADD R1, R2, R3
   PSX.Register.Write (CPU.Registers, 2, 10);
   PSX.Register.Write (CPU.Registers, 3, 20);

   PSX.Memory.Write_32 (Memory, 16#0000_1004#, 16#0043_0820#);

   PSX.CPU.Step.Step (CPU, Memory);

   Assert (CPU.PC = 16#0000_1004#, "STEP JAL enters delay slot");

   Assert (CPU.Next_PC = 16#0000_2000#, "STEP JAL schedules target");

   Assert
     (PSX.Register.Read (CPU.Registers, 31) = 16#0000_1008#,
      "STEP JAL stores return address");

   --  Execute the delay slot.
   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 30,
      "STEP JAL executes delay slot");

   Assert (CPU.PC = 16#0000_2000#, "STEP JAL reaches target after delay slot");

   Assert (CPU.Next_PC = 16#0000_2004#, "STEP JAL advances target Next_PC");

   Ada.Text_IO.Put_Line ("PASS: STEP JAL");

   --------------------------------------------------
   --  CPU STEP: BEQ TAKEN
   --------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   --  BEQ R2, R3, +4
   PSX.Register.Write (CPU.Registers, 2, 10);
   PSX.Register.Write (CPU.Registers, 3, 10);

   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#1043_0004#);

   --  Delay slot: ADD R1, R2, R3
   PSX.Memory.Write_32 (Memory, 16#0000_1004#, 16#0043_0820#);

   PSX.CPU.Step.Step (CPU, Memory);

   Assert (CPU.PC = 16#0000_1004#, "STEP BEQ enters delay slot");

   Assert (CPU.Next_PC = 16#0000_1014#, "STEP BEQ schedules target");

   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 20,
      "STEP BEQ executes delay slot");

   Assert (CPU.PC = 16#0000_1014#, "STEP BEQ reaches target");

   Ada.Text_IO.Put_Line ("PASS: STEP BEQ TAKEN");

   --------------------------------------------------
   --  CPU STEP: BEQ NOT TAKEN
   --------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   --  BEQ R2, R3, +4
   PSX.Register.Write (CPU.Registers, 2, 10);
   PSX.Register.Write (CPU.Registers, 3, 20);

   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#1043_0004#);

   --  Sequential instruction / delay slot
   PSX.Memory.Write_32 (Memory, 16#0000_1004#, 16#0043_0820#);

   PSX.CPU.Step.Step (CPU, Memory);

   Assert (CPU.PC = 16#0000_1004#, "STEP BEQ not taken advances normally");

   Assert
     (CPU.Next_PC = 16#0000_1008#, "STEP BEQ not taken keeps sequential flow");

   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 30,
      "STEP BEQ not taken executes next instruction");

   Assert
     (CPU.PC = 16#0000_1008#, "STEP BEQ not taken reaches sequential address");

   --------------------------------------------------
   --  CPU STEP: BNE TAKEN
   --------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   --  BNE R2, R3, +4
   PSX.Register.Write (CPU.Registers, 2, 10);
   PSX.Register.Write (CPU.Registers, 3, 20);

   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#1443_0004#);

   --  Delay slot: ADD R1, R2, R3
   PSX.Memory.Write_32 (Memory, 16#0000_1004#, 16#0043_0820#);

   PSX.CPU.Step.Step (CPU, Memory);

   Assert (CPU.PC = 16#0000_1004#, "STEP BNE enters delay slot");

   Assert (CPU.Next_PC = 16#0000_1014#, "STEP BNE schedules target");

   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 30,
      "STEP BNE executes delay slot");

   Assert (CPU.PC = 16#0000_1014#, "STEP BNE reaches target");

   Ada.Text_IO.Put_Line ("PASS: STEP BNE TAKEN");

   --------------------------------------------------
   --  CPU STEP: BNE NOT TAKEN
   --------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   --  BNE R2, R3, +4
   PSX.Register.Write (CPU.Registers, 2, 10);
   PSX.Register.Write (CPU.Registers, 3, 10);

   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#1443_0004#);

   --  Sequential instruction / delay slot
   PSX.Memory.Write_32 (Memory, 16#0000_1004#, 16#0043_0820#);

   PSX.CPU.Step.Step (CPU, Memory);

   Assert (CPU.PC = 16#0000_1004#, "STEP BNE not taken advances normally");

   Assert
     (CPU.Next_PC = 16#0000_1008#, "STEP BNE not taken keeps sequential flow");

   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 20,
      "STEP BNE not taken executes next instruction");

   Assert
     (CPU.PC = 16#0000_1008#, "STEP BNE not taken reaches sequential address");

   Ada.Text_IO.Put_Line ("PASS: STEP BNE NOT TAKEN");

   --------------------------------------------------
   --  CPU STEP: BLEZ TAKEN
   --------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   --  BLEZ R2, +4
   PSX.Register.Write (CPU.Registers, 2, 16#FFFF_FFFF#);

   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#1840_0004#);

   --  Delay slot: ADD R1, R2, R2
   PSX.Memory.Write_32 (Memory, 16#0000_1004#, 16#0042_0820#);

   PSX.CPU.Step.Step (CPU, Memory);

   Assert (CPU.PC = 16#0000_1004#, "STEP BLEZ enters delay slot");

   Assert (CPU.Next_PC = 16#0000_1014#, "STEP BLEZ schedules target");

   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 16#FFFF_FFFE#,
      "STEP BLEZ executes delay slot");

   Assert (CPU.PC = 16#0000_1014#, "STEP BLEZ reaches target");

   Ada.Text_IO.Put_Line ("PASS: STEP BLEZ TAKEN");

   --------------------------------------------------
   --  CPU STEP: BLEZ NOT TAKEN
   --------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   --  BLEZ R2, +4
   PSX.Register.Write (CPU.Registers, 2, 1);

   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#1840_0004#);

   --  Sequential instruction
   PSX.Memory.Write_32 (Memory, 16#0000_1004#, 16#0042_0820#);

   PSX.CPU.Step.Step (CPU, Memory);

   Assert (CPU.PC = 16#0000_1004#, "STEP BLEZ not taken advances normally");

   Assert
     (CPU.Next_PC = 16#0000_1008#,
      "STEP BLEZ not taken keeps sequential flow");

   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 2,
      "STEP BLEZ not taken executes next instruction");

   Assert
     (CPU.PC = 16#0000_1008#,
      "STEP BLEZ not taken reaches sequential address");

   Ada.Text_IO.Put_Line ("PASS: STEP BLEZ NOT TAKEN");

   --------------------------------------------------
   --  CPU STEP: BGTZ TAKEN
   --------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   --  BGTZ R2, +4
   PSX.Register.Write (CPU.Registers, 2, 1);

   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#1C40_0004#);

   --  Delay slot
   PSX.Memory.Write_32 (Memory, 16#0000_1004#, 16#0042_0820#);

   PSX.CPU.Step.Step (CPU, Memory);

   Assert (CPU.PC = 16#0000_1004#, "STEP BGTZ enters delay slot");

   Assert (CPU.Next_PC = 16#0000_1014#, "STEP BGTZ schedules target");

   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 2,
      "STEP BGTZ executes delay slot");

   Assert (CPU.PC = 16#0000_1014#, "STEP BGTZ reaches target");

   Ada.Text_IO.Put_Line ("PASS: STEP BGTZ TAKEN");

   --------------------------------------------------
   --  CPU STEP: BGTZ NOT TAKEN
   --------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   --  BGTZ R2, +4
   PSX.Register.Write (CPU.Registers, 2, 0);

   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#1C40_0004#);

   --  Sequential instruction
   PSX.Memory.Write_32 (Memory, 16#0000_1004#, 16#0042_0820#);

   PSX.CPU.Step.Step (CPU, Memory);

   Assert (CPU.PC = 16#0000_1004#, "STEP BGTZ not taken advances normally");

   Assert
     (CPU.Next_PC = 16#0000_1008#,
      "STEP BGTZ not taken keeps sequential flow");

   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 0,
      "STEP BGTZ not taken executes next instruction");

   Assert
     (CPU.PC = 16#0000_1008#,
      "STEP BGTZ not taken reaches sequential address");

   Ada.Text_IO.Put_Line ("PASS: STEP BGTZ NOT TAKEN");

   --------------------------------------------------
   --  CPU STEP: BLTZ TAKEN
   --------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   --  BLTZ R2, +4
   PSX.Register.Write (CPU.Registers, 2, 16#FFFF_FFFF#);

   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#0440_0004#);

   --  Delay slot
   PSX.Memory.Write_32 (Memory, 16#0000_1004#, 16#0042_0820#);

   PSX.CPU.Step.Step (CPU, Memory);

   Assert (CPU.PC = 16#0000_1004#, "STEP BLTZ enters delay slot");

   Assert (CPU.Next_PC = 16#0000_1014#, "STEP BLTZ schedules target");

   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 16#FFFF_FFFE#,
      "STEP BLTZ executes delay slot");

   Assert (CPU.PC = 16#0000_1014#, "STEP BLTZ reaches target");

   Ada.Text_IO.Put_Line ("PASS: STEP BLTZ TAKEN");

   --------------------------------------------------
   --  CPU STEP: BLTZ NOT TAKEN
   --------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   --  BLTZ R2, +4
   PSX.Register.Write (CPU.Registers, 2, 0);

   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#0440_0004#);

   --  Sequential instruction
   PSX.Memory.Write_32 (Memory, 16#0000_1004#, 16#0042_0820#);

   PSX.CPU.Step.Step (CPU, Memory);

   Assert (CPU.PC = 16#0000_1004#, "STEP BLTZ not taken advances normally");

   Assert
     (CPU.Next_PC = 16#0000_1008#,
      "STEP BLTZ not taken keeps sequential flow");

   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 0,
      "STEP BLTZ not taken executes next instruction");

   Assert
     (CPU.PC = 16#0000_1008#,
      "STEP BLTZ not taken reaches sequential address");

   Ada.Text_IO.Put_Line ("PASS: STEP BLTZ NOT TAKEN");

   --------------------------------------------------
   --  CPU STEP: BGEZ TAKEN
   --------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   --  BGEZ R2, +4
   PSX.Register.Write (CPU.Registers, 2, 0);

   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#0441_0004#);

   --  Delay slot
   PSX.Memory.Write_32 (Memory, 16#0000_1004#, 16#0042_0820#);

   PSX.CPU.Step.Step (CPU, Memory);

   Assert (CPU.PC = 16#0000_1004#, "STEP BGEZ enters delay slot");

   Assert (CPU.Next_PC = 16#0000_1014#, "STEP BGEZ schedules target");

   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 0,
      "STEP BGEZ executes delay slot");

   Assert (CPU.PC = 16#0000_1014#, "STEP BGEZ reaches target");

   Ada.Text_IO.Put_Line ("PASS: STEP BGEZ TAKEN");

   --------------------------------------------------
   --  CPU STEP: BGEZ NOT TAKEN
   --------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   --  BGEZ R2, +4
   PSX.Register.Write (CPU.Registers, 2, 16#FFFF_FFFF#);

   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#0441_0004#);

   --  Sequential instruction
   PSX.Memory.Write_32 (Memory, 16#0000_1004#, 16#0042_0820#);

   PSX.CPU.Step.Step (CPU, Memory);

   Assert (CPU.PC = 16#0000_1004#, "STEP BGEZ not taken advances normally");

   Assert
     (CPU.Next_PC = 16#0000_1008#,
      "STEP BGEZ not taken keeps sequential flow");

   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 16#FFFFFFFE#,
      "STEP BGEZ not taken executes next instruction");

   Assert
     (CPU.PC = 16#0000_1008#,
      "STEP BGEZ not taken reaches sequential address");

   Ada.Text_IO.Put_Line ("PASS: STEP BGEZ NOT TAKEN");

   --------------------------------------------------
   --  CPU STEP: BEQ NEGATIVE OFFSET
   --------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   --  BEQ R2, R3, -2
   --
   --  Target:
   --  0x1000 + 4 + (-2 << 2)
   --  = 0x1004 - 8
   --  = 0x0FFC
   PSX.Register.Write (CPU.Registers, 2, 10);
   PSX.Register.Write (CPU.Registers, 3, 10);

   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#1043_FFFE#);

   --  Delay slot: ADD R1, R2, R3
   PSX.Memory.Write_32 (Memory, 16#0000_1004#, 16#0043_0820#);

   PSX.CPU.Step.Step (CPU, Memory);

   Assert (CPU.PC = 16#0000_1004#, "STEP BEQ negative enters delay slot");

   Assert
     (CPU.Next_PC = 16#0000_0FFC#,
      "STEP BEQ negative schedules backward target");

   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (PSX.Register.Read (CPU.Registers, 1) = 20,
      "STEP BEQ negative executes delay slot");

   Assert
     (CPU.PC = 16#0000_0FFC#, "STEP BEQ negative reaches backward target");

   Ada.Text_IO.Put_Line ("PASS: STEP BEQ NEGATIVE OFFSET");

   -------------------------------------------------------------------------
   --  ADD overflow
   -------------------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   PSX.Register.Write (CPU.Registers, 1, 16#7FFF_FFFF#);
   PSX.Register.Write (CPU.Registers, 2, 1);

   --  ADD R3, R1, R2
   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#0022_1820#);

   PSX.CPU.Step.Step (CPU, Memory);

   Assert (CPU.Cause = PSX.CPU.Overflow, "STEP ADD OVERFLOW: cause");

   Assert (CPU.EPC = 16#0000_1000#, "STEP ADD OVERFLOW: EPC");

   Assert (CPU.PC = 16#8000_0080#, "STEP ADD OVERFLOW: exception vector");

   Assert (not CPU.Exception_Pending, "STEP ADD OVERFLOW: exception consumed");

   Ada.Text_IO.Put_Line ("PASS: STEP ADD OVERFLOW");

   -------------------------------------------------------------------------
   --  SUB overflow
   -------------------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   PSX.Register.Write (CPU.Registers, 1, 16#8000_0000#);
   PSX.Register.Write (CPU.Registers, 2, 1);

   --  SUB R3, R1, R2
   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#0022_1822#);

   PSX.CPU.Step.Step (CPU, Memory);

   Assert (CPU.Cause = PSX.CPU.Overflow, "STEP SUB OVERFLOW: cause");

   Assert (CPU.EPC = 16#0000_1000#, "STEP SUB OVERFLOW: EPC");

   Assert (CPU.PC = 16#8000_0080#, "STEP SUB OVERFLOW: exception vector");

   Assert (not CPU.Exception_Pending, "STEP SUB OVERFLOW: exception consumed");

   Ada.Text_IO.Put_Line ("PASS: STEP SUB OVERFLOW");

   -------------------------------------------------------------------------
   --  ADDI overflow
   -------------------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   PSX.Register.Write (CPU.Registers, 1, 16#7FFF_FFFF#);

   --  ADDI R2, R1, 1
   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#2022_0001#);

   PSX.CPU.Step.Step (CPU, Memory);

   Assert (CPU.Cause = PSX.CPU.Overflow, "STEP ADDI OVERFLOW: cause");

   Assert (CPU.EPC = 16#0000_1000#, "STEP ADDI OVERFLOW: EPC");

   Assert (CPU.PC = 16#8000_0080#, "STEP ADDI OVERFLOW: exception vector");

   Assert
     (not CPU.Exception_Pending, "STEP ADDI OVERFLOW: exception consumed");

   Ada.Text_IO.Put_Line ("PASS: STEP ADDI OVERFLOW");

   -------------------------------------------------------------------------
   --  SYSCALL
   -------------------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   --  SYSCALL
   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#0000_000C#);

   PSX.CPU.Step.Step (CPU, Memory);

   Assert (CPU.Cause = PSX.CPU.Syscall, "STEP SYSCALL: cause");

   Assert (CPU.EPC = 16#0000_1000#, "STEP SYSCALL: EPC");

   Assert (CPU.PC = 16#8000_0080#, "STEP SYSCALL: exception vector");

   Assert (not CPU.Exception_Pending, "STEP SYSCALL: exception consumed");

   Ada.Text_IO.Put_Line ("PASS: STEP SYSCALL");

   -------------------------------------------------------------------------
   --  BREAK
   -------------------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   --  BREAK
   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#0000_000D#);

   PSX.CPU.Step.Step (CPU, Memory);

   Assert (not CPU.Exception_Pending, "STEP BREAK: exception consumed");

   Assert (CPU.Cause = PSX.CPU.Break, "STEP BREAK: cause");

   Assert (CPU.EPC = 16#0000_1000#, "STEP BREAK: EPC");

   Assert (CPU.PC = 16#8000_0080#, "STEP BREAK: exception vector");

   Ada.Text_IO.Put_Line ("PASS: STEP BREAK");

   -------------------------------------------------------------------------
   --  Exception in branch delay slot
   -------------------------------------------------------------------------

   PSX.CPU.Reset (CPU);
   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   PSX.Register.Write (CPU.Registers, 1, 1);
   PSX.Register.Write (CPU.Registers, 2, 1);

   --  BEQ R1, R2, +1
   --
   --  Branch target = 0x1008.
   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#1022_0001#);

   --  Delay slot: SYSCALL
   PSX.Memory.Write_32 (Memory, 16#0000_1004#, 16#0000_000C#);

   --  First Step: execute BEQ.
   PSX.CPU.Step.Step (CPU, Memory);

   Assert (CPU.PC = 16#0000_1004#, "STEP DELAY EXCEPTION: delay slot PC");

   Assert (CPU.Next_PC = 16#0000_1008#, "STEP DELAY EXCEPTION: branch target");

   --  Second Step: execute SYSCALL in delay slot.
   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (not CPU.Exception_Pending, "STEP DELAY EXCEPTION: exception consumed");

   Assert (CPU.Cause = PSX.CPU.Syscall, "STEP DELAY EXCEPTION: cause");

   Assert
     (CPU.EPC = 16#0000_1000#, "STEP DELAY EXCEPTION: EPC points to branch");

   Assert (CPU.PC = 16#8000_0080#, "STEP DELAY EXCEPTION: exception vector");

   Ada.Text_IO.Put_Line ("PASS: STEP DELAY SLOT EXCEPTION");

   --------------------------------------------------
   --  CPU STEP: TIMER TICK
   --------------------------------------------------

   PSX.CPU.Reset (CPU);
   PSX.Memory.Reset (Memory);

   CPU.PC := 16#0000_1000#;
   CPU.Next_PC := 16#0000_1004#;

   --  NOP
   PSX.Memory.Write_32 (Memory, 16#0000_1000#, 16#0000_0000#);

   Assert
     (PSX.Timers.Read_Counter (Memory.Timers, 0) = 0,
      "STEP TIMER initial counter");

   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (PSX.Timers.Read_Counter (Memory.Timers, 0) = 1,
      "STEP TIMER advances counter");

   PSX.CPU.Step.Step (CPU, Memory);

   Assert
     (PSX.Timers.Read_Counter (Memory.Timers, 0) = 2,
      "STEP TIMER advances counter twice");

   Ada.Text_IO.Put_Line ("PASS: STEP TIMER TICK");

   --------------------------------------------------
   --  RESULT
   --------------------------------------------------

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("All CPU STEP tests passed.");

end Psx_Cpu_Step_Tests;
