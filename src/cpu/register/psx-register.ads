with PSX.Types;

package PSX.Register is

   subtype Word32 is PSX.Types.Word32;

   type Register_Index is range 0 .. 31;

   type Register_Array is array (Register_Index) of Word32;

   function Read
     (Registers : Register_Array;
      Index     : Register_Index) return Word32;

   procedure Write
     (Registers : in out Register_Array;
      Index     : Register_Index;
      Value     : Word32);

end PSX.Register;