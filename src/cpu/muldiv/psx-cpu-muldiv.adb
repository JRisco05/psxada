with Interfaces;
with PSX.Types;

package body PSX.CPU.MulDiv is

   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;
   use type Interfaces.Integer_32;
   use type Interfaces.Integer_64;

   procedure Start_Multiply
     (CPU    : in out PSX.CPU.CPU_State;
      Left   : PSX.Types.Word32;
      Right  : PSX.Types.Word32;
      Signed : Boolean)
   is
      Product : Interfaces.Unsigned_64;
      Cycles  : Natural;
   begin
      if Signed then

         declare
            L : constant Interfaces.Integer_64 :=
              Interfaces.Integer_64 (Interfaces.Integer_32 (Left));

            R : constant Interfaces.Integer_64 :=
              Interfaces.Integer_64 (Interfaces.Integer_32 (Right));

            P : constant Interfaces.Integer_64 := L * R;
         begin
            Product := Interfaces.Unsigned_64 (P);
         end;

         if Left <= 16#0000_07FF# or else Left >= 16#FFFF_F800# then
            Cycles := 6;

         elsif Left <= 16#000F_FFFF# or else Left >= 16#FFF0_0000# then
            Cycles := 9;

         else
            Cycles := 13;
         end if;

      else

         Product :=
           Interfaces.Unsigned_64 (Left) * Interfaces.Unsigned_64 (Right);

         if Left <= 16#0000_07FF# then
            Cycles := 6;
         elsif Left <= 16#000F_FFFF# then
            Cycles := 9;
         else
            Cycles := 13;
         end if;

      end if;

      CPU.HI := PSX.Types.Word32 (Interfaces.Shift_Right (Product, 32));

      CPU.LO := PSX.Types.Word32 (Product and 16#FFFF_FFFF#);

      CPU.MulDiv_Busy := True;
      CPU.MulDiv_Cycles := Cycles;
   end Start_Multiply;

   procedure Start_Divide
     (CPU    : in out PSX.CPU.CPU_State;
      Left   : PSX.Types.Word32;
      Right  : PSX.Types.Word32;
      Signed : Boolean)
   is
      Quotient  : Interfaces.Integer_64;
      Remainder : Interfaces.Integer_64;
   begin
      if Right = 0 then

         if Signed then
            if Interfaces.Integer_32 (Left) < 0 then
               CPU.LO := 1;
               CPU.HI := Left;
            else
               CPU.LO := 16#FFFF_FFFF#;
               CPU.HI := Left;
            end if;
         else
            CPU.LO := 16#FFFF_FFFF#;
            CPU.HI := Left;
         end if;

      elsif Signed then

         Quotient :=
           Interfaces.Integer_64 (Interfaces.Integer_32 (Left))
           / Interfaces.Integer_64 (Interfaces.Integer_32 (Right));

         Remainder :=
           Interfaces.Integer_64 (Interfaces.Integer_32 (Left))
           rem Interfaces.Integer_64 (Interfaces.Integer_32 (Right));

         CPU.LO := PSX.Types.Word32 (Interfaces.Unsigned_32 (Quotient));

         CPU.HI := PSX.Types.Word32 (Interfaces.Unsigned_32 (Remainder));

      else

         CPU.LO := PSX.Types.Word32 (Interfaces.Unsigned_32 (Left / Right));

         CPU.HI := PSX.Types.Word32 (Interfaces.Unsigned_32 (Left rem Right));

      end if;

      CPU.MulDiv_Busy := True;
      CPU.MulDiv_Cycles := 36;
   end Start_Divide;

   procedure Tick (CPU : in out PSX.CPU.CPU_State; Cycles : Natural) is
   begin
      if CPU.MulDiv_Busy then

         if Cycles >= CPU.MulDiv_Cycles then
            CPU.MulDiv_Cycles := 0;
            CPU.MulDiv_Busy := False;
         else
            CPU.MulDiv_Cycles := CPU.MulDiv_Cycles - Cycles;
         end if;

      end if;
   end Tick;

end PSX.CPU.MulDiv;
