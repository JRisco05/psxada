with PSX.CPU;

package body PSX.State is

   procedure Reset (System : in out PSX_State) is
   begin
      PSX.CPU.Reset (System.CPU);
   end Reset;

end PSX.State;
