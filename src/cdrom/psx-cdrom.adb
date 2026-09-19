with Interfaces;

package body PSX.CDROM is

   -- 🌟 SOLUCIÓN: Hacemos visibles los operadores de bits para Word8
   use type Interfaces.Unsigned_8;

   ------------------
   --    RESET     --
   ------------------
   procedure Reset (CD : out CDROM_State) is
   begin
      CD.Index := 0;
      CD.Status_Reg := 16#18#;
      CD.Interrupt_Enable := 0;
      CD.Interrupt_Flag := 0;
      CD.Param_Count := 0;
      CD.Response_Count := 0;
      CD.Response_Index := 0;
      CD.Response_Buffer := (others => 0);
      CD.Command_Param := (others => 0);
   end Reset;

   --------------------
   -- WRITE REGISTER --
   --------------------
   procedure Write_Register
     (CD : in out CDROM_State; Address : Word32; Value : Word8) is
   begin
      case Address is
         when 16#1F801800# =>
            CD.Index := Value and 16#03#;

         when 16#1F801801# =>
            case CD.Index is
               when 0      =>
                  CD.Response_Buffer (0) := 16#02#;
                  CD.Response_Count := 1;
                  CD.Response_Index := 0;
                  CD.Interrupt_Flag := 16#03#;

               when others =>
                  null;
            end case;

         when 16#1F801802# =>
            case CD.Index is
               when 0      =>
                  if CD.Param_Count < 16 then
                     CD.Command_Param (CD.Param_Count) := Value;
                     CD.Param_Count := CD.Param_Count + 1;
                  end if;

               when 1      =>
                  CD.Interrupt_Enable := Value;

               when others =>
                  null;
            end case;

         when 16#1F801803# =>
            case CD.Index is
               when 1      =>
                  CD.Interrupt_Flag := CD.Interrupt_Flag and (not Value);

               when others =>
                  null;
            end case;

         when others       =>
            null;
      end case;
   end Write_Register;

   -------------------
   -- READ REGISTER --
   -------------------
   procedure Read_Register
     (CD : in out CDROM_State; Address : Word32; Value : out Word8) is
   begin
      Value := 0;
      case Address is
         when 16#1F801800# =>
            Value := CD.Index or CD.Status_Reg;

         when 16#1F801801# =>
            if CD.Response_Count > 0
              and then CD.Response_Index < CD.Response_Count
            then
               Value := CD.Response_Buffer (CD.Response_Index);
               CD.Response_Index := CD.Response_Index + 1;
            end if;

         when 16#1F801802# =>
            Value := 0;

         when 16#1F801803# =>
            case CD.Index is
               when 0 | 2  =>
                  Value := CD.Interrupt_Flag or 16#E0#;

               when 1      =>
                  Value := CD.Interrupt_Enable or 16#E0#;

               when others =>
                  Value := 0;
            end case;

         when others       =>
            Value := 0;
      end case;
   end Read_Register;

end PSX.CDROM;
