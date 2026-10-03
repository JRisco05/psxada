with System;

package PSX.Display is

   procedure Initialize_Window (Width, Height : Integer)
   with Import, Convention => C, External_Name => "psx_init_window";

   procedure Update_Frame (Buffer_Address : System.Address; Size : Integer)
   with Import, Convention => C, External_Name => "psx_update_frame";

   function Process_Events return Integer
   with Import, Convention => C, External_Name => "psx_process_events";

end PSX.Display;
