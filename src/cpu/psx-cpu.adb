with Interfaces;

package body PSX.CPU is

   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_32;

   procedure Reset (CPU : out CPU_State) is
   begin
      CPU.Registers := (others => 0);
      CPU.PC := 16#BFC0_0000#;
      CPU.Next_PC := 16#BFC0_0004#;
      CPU.In_Delay_Slot := False;
      CPU.HI := 0;
      CPU.LO := 0;
      CPU.MulDiv_Busy := False;
      CPU.MulDiv_Cycles := 0;
      CPU.Memory_Stall_Cycles := 0;
      CPU.Load_Pending := False;
      CPU.Load_Register := 0;
      CPU.Load_Value := 0;
      CPU.Status := 0;
      CPU.EPC := 0;
      CPU.Cause := None;
      CPU.Exception_Pending := False;
   end Reset;

   procedure Enter_Exception (CPU : in out CPU_State) is
   begin
      CPU.Status :=
        Interfaces.Shift_Left (CPU.Status and 16#0000_003F#, 2)
        and 16#0000_003F#;

      CPU.Status := CPU.Status and not 16#0000_0003#;

      CPU.PC := 16#8000_0080#;

      CPU.Next_PC := 16#8000_0084#;

      CPU.In_Delay_Slot := False;

      CPU.Exception_Pending := False;
   end Enter_Exception;

   procedure Return_From_Exception (CPU : in out CPU_State) is
   begin
      CPU.Status :=
        Interfaces.Shift_Right (CPU.Status and 16#0000_003C#, 2)
        or (CPU.Status and 16#0000_0003#);
   end Return_From_Exception;

end PSX.CPU;
