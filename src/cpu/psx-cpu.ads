with PSX.Register;
with PSX.Types;

package PSX.CPU is

   pragma Elaborate_Body;

   subtype Word32 is PSX.Types.Word32;

   type Exception_Code is (None, Syscall, Break, Overflow);

   type CPU_State is record
      Registers : PSX.Register.Register_Array;

      --  Program Counter
      PC : Word32;

      --  Next Program Counter.
      --
      --  This models the next instruction address used by the
      --  MIPS R3000A branch-delay mechanism.
      Next_PC : Word32;

      --  Indicates that the current instruction is executing
      --  in the branch delay slot.
      In_Delay_Slot : Boolean;

      HI : Word32;
      LO : Word32;

      --  Multiply / divide unit state
      MulDiv_Busy   : Boolean;
      MulDiv_Cycles : Natural;

      --  Coprocessor 0 / exception state
      Status : Word32;
      EPC    : Word32;
      Cause  : Exception_Code;

      Exception_Pending : Boolean;
   end record;

   procedure Reset (CPU : out CPU_State);
   procedure Enter_Exception (CPU : in out CPU_State);
   procedure Return_From_Exception (CPU : in out CPU_State);

end PSX.CPU;
