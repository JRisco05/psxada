with PSX.GTE;
with PSX.GTE.Instruction;

package PSX.GTE.Execute is

   procedure Execute
     (GTE  : in out PSX.GTE.GTE_State;
      Inst : PSX.GTE.Instruction.Instruction);

end PSX.GTE.Execute;