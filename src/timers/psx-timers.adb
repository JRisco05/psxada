with Interfaces;

package body PSX.Timers is

   use type Interfaces.Unsigned_32;

   procedure Reset (Timers : out Timers_State) is
   begin
      for I in Timers.Timers'Range loop
         Timers.Timers (I).Counter := 0;
         Timers.Timers (I).Mode := 0;
         Timers.Timers (I).Target := 0;
      end loop;
   end Reset;

   procedure Write_Counter
     (Timers : in out Timers_State; Index : Natural; Value : Word32) is
   begin
      if Index in Timers.Timers'Range then
         Timers.Timers (Index).Counter := Value and 16#FFFF#;
      end if;
   end Write_Counter;

   function Read_Counter (Timers : Timers_State; Index : Natural) return Word32
   is
   begin
      if Index in Timers.Timers'Range then
         return Timers.Timers (Index).Counter;
      end if;

      return 0;
   end Read_Counter;

   procedure Write_Mode
     (Timers : in out Timers_State; Index : Natural; Value : Word32) is
   begin
      if Index in Timers.Timers'Range then

         -- Bits 10 y 11 son flags de estado.
         -- Al escribir Mode se limpian.
         Timers.Timers (Index).Mode := Value and 16#F3FF#;

      end if;
   end Write_Mode;

   function Read_Mode (Timers : Timers_State; Index : Natural) return Word32 is
   begin
      if Index in Timers.Timers'Range then
         return Timers.Timers (Index).Mode;
      end if;

      return 0;
   end Read_Mode;

   procedure Write_Target
     (Timers : in out Timers_State; Index : Natural; Value : Word32) is
   begin
      if Index in Timers.Timers'Range then
         Timers.Timers (Index).Target := Value and 16#FFFF#;
      end if;
   end Write_Target;

   function Read_Target (Timers : Timers_State; Index : Natural) return Word32
   is
   begin
      if Index in Timers.Timers'Range then
         return Timers.Timers (Index).Target;
      end if;

      return 0;
   end Read_Target;

   procedure Tick
     (Timers : in out Timers_State; Index : Natural; Cycles : Natural)
   is
      Counter : Word32;
      Target  : Word32;
   begin
      if Index not in Timers.Timers'Range then
         return;
      end if;

      Counter := Timers.Timers (Index).Counter and 16#FFFF#;
      Target := Timers.Timers (Index).Target and 16#FFFF#;

      for I in 1 .. Cycles loop

         if Counter = 16#FFFF# then

            Counter := 0;

            -- Bit 11: reached 0xFFFF
            Timers.Timers (Index).Mode :=
              Timers.Timers (Index).Mode or 16#0800#;

         else

            Counter := Counter + 1;

         end if;

         -- Target reached
         if Counter = Target then

            -- Bit 10: reached target
            Timers.Timers (Index).Mode :=
              Timers.Timers (Index).Mode or 16#0400#;

            -- Bit 3: reset counter when target reached
            if (Timers.Timers (Index).Mode and 16#0008#) /= 0 then
               Counter := 0;
            end if;

         end if;

      end loop;

      Timers.Timers (Index).Counter := Counter;

   end Tick;

end PSX.Timers;
