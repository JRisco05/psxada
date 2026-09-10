package body PSX.SPU is

   procedure Reset (SPU : out SPU_State) is
   begin

      SPU.RAM := (others => 0);

      SPU.Control := 0;
      SPU.Status := 0;

      SPU.Transfer_Address := 0;
      SPU.Transfer_Control := 0;

      SPU.IRQ_Address := 0;

   end Reset;

end PSX.SPU;
