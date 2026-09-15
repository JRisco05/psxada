with PSX.CPU;
with PSX.Types;

package PSX.CPU.MulDiv is

   procedure Start_Multiply
     (CPU    : in out PSX.CPU.CPU_State;
      Left   : PSX.Types.Word32;
      Right  : PSX.Types.Word32;
      Signed : Boolean);

   procedure Start_Divide
     (CPU    : in out PSX.CPU.CPU_State;
      Left   : PSX.Types.Word32;
      Right  : PSX.Types.Word32;
      Signed : Boolean);

   procedure Tick (CPU : in out PSX.CPU.CPU_State; Cycles : Natural);

end PSX.CPU.MulDiv;
