package body PSX.Register is

   function Read
     (Registers : Register_Array;
      Index     : Register_Index) return Word32
   is
   begin
      if Index = 0 then
         return 0;
      end if;

      return Registers (Index);
   end Read;


   procedure Write
     (Registers : in out Register_Array;
      Index     : Register_Index;
      Value     : Word32)
   is
   begin
      if Index = 0 then
         return;
      end if;

      Registers (Index) := Value;
   end Write;

end PSX.Register;