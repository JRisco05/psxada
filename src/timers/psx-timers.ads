with PSX.Types;

package PSX.Timers is

   subtype Word32 is PSX.Types.Word32;

   Timer_Count : constant := 3;

   type Timer_State is record
      Counter : Word32;
      Mode    : Word32;
      Target  : Word32;
   end record;

   type Timer_Array is
     array (Natural range 0 .. Timer_Count - 1) of Timer_State;

   type Timers_State is record
      Timers : Timer_Array;
   end record;

   procedure Reset (Timers : out Timers_State);

   procedure Write_Counter
     (Timers : in out Timers_State; Index : Natural; Value : Word32);

   procedure Tick
     (Timers : in out Timers_State; Index : Natural; Cycles : Natural);

   function Read_Counter
     (Timers : Timers_State; Index : Natural) return Word32;

   procedure Write_Mode
     (Timers : in out Timers_State; Index : Natural; Value : Word32);

   function Read_Mode (Timers : Timers_State; Index : Natural) return Word32;

   procedure Write_Target
     (Timers : in out Timers_State; Index : Natural; Value : Word32);

   function Read_Target (Timers : Timers_State; Index : Natural) return Word32;

end PSX.Timers;
