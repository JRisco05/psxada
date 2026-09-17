with PSX.Types;

package PSX.GTE.Execute.Saturation is

   subtype Word32 is PSX.Types.Word32;

   function Saturate_IR (Value : Integer) return Word32;

end PSX.GTE.Execute.Saturation;
