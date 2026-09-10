with Interfaces;
with PSX.Types;

package PSX.SPU is
   
   use type Interfaces.Unsigned_32;

   subtype Word8 is PSX.Types.Word8;
   subtype Word16 is PSX.Types.Word16;
   subtype Word32 is PSX.Types.Word32;

   SPU_RAM_SIZE : constant := 16#0008_0000#;

   type SPU_RAM_Array is array (Word32 range 0 .. SPU_RAM_SIZE - 1) of Word8;

   type SPU_State is record

      RAM : SPU_RAM_Array;

      Control : Word16;

      Status : Word16;

      Transfer_Address : Word16;

      Transfer_Control : Word16;

      IRQ_Address : Word16;

   end record;

   procedure Reset (SPU : out SPU_State);

end PSX.SPU;
