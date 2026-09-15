with Interfaces;

package body PSX.GTE.Execute.Saturation is

   function Saturate_IR (Value : Integer) return Word32 is
   begin
      if Value > 32767 then
         return 32767;

      elsif Value < -32768 then
         return 16#0000_8000#;

      elsif Value < 0 then
         return Word32
           (Interfaces.Unsigned_32 (Value + 65536));

      else
         return Word32 (Value);
      end if;
   end Saturate_IR;

end PSX.GTE.Execute.Saturation;