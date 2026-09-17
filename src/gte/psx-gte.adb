package body PSX.GTE is

   procedure Reset (GTE : out GTE_State) is
   begin
      GTE := (others => 0);
   end Reset;

   procedure Write_Data
     (GTE : in out GTE_State; Index : Natural; Value : Word32) is
   begin
      case Index is

         --  V0

         when 0      =>
            GTE.V0_X := Value and 16#0000_FFFF#;
            GTE.V0_Y := Interfaces.Shift_Right (Value, 16);

         when 1      =>
            GTE.V0_Z := Value;

         --  V1

         when 2      =>
            GTE.V1_X := Value and 16#0000_FFFF#;
            GTE.V1_Y := Interfaces.Shift_Right (Value, 16);

         when 3      =>
            GTE.V1_Z := Value;

         -- V2

         when 4      =>
            GTE.V2_X := Value and 16#0000_FFFF#;
            GTE.V2_Y := Interfaces.Shift_Right (Value, 16);

         when 5      =>
            GTE.V2_Z := Value;

         --  Color

         when 6      =>
            GTE.RGBC := Value;

         --  OTZ

         when 7      =>
            GTE.OTZ := Value;

         --  IR

         when 8      =>
            GTE.IR0 := Value;

         when 9      =>
            GTE.IR1 := Value;

         when 10     =>
            GTE.IR2 := Value;

         when 11     =>
            GTE.IR3 := Value;

         --  Screen XY FIFO

         when 12     =>
            GTE.SX0 := Value and 16#0000_FFFF#;
            GTE.SY0 := Interfaces.Shift_Right (Value, 16);

         when 13     =>
            GTE.SX1 := Value and 16#0000_FFFF#;
            GTE.SY1 := Interfaces.Shift_Right (Value, 16);

         when 14     =>
            GTE.SX2 := Value and 16#0000_FFFF#;
            GTE.SY2 := Interfaces.Shift_Right (Value, 16);

         --  SXYP: write causes FIFO movement

         when 15     =>
            GTE.SX0 := GTE.SX1;
            GTE.SY0 := GTE.SY1;
            GTE.SX1 := GTE.SX2;
            GTE.SY1 := GTE.SY2;
            GTE.SX2 := Value and 16#0000_FFFF#;
            GTE.SY2 := Interfaces.Shift_Right (Value, 16);

         --  SZ FIFO

         when 16     =>
            GTE.SZ0 := Value;

         when 17     =>
            GTE.SZ1 := Value;

         when 18     =>
            GTE.SZ2 := Value;

         when 19     =>
            GTE.SZ3 := Value;

         --  RGB FIFO

         when 20     =>
            GTE.RGB0 := Value;

         when 21     =>
            GTE.RGB1 := Value;

         when 22     =>
            GTE.RGB2 := Value;

         --  MAC

         when 24     =>
            GTE.MAC0 := Value;

         when 25     =>
            GTE.MAC1 := Value;

         when 26     =>
            GTE.MAC2 := Value;

         when 27     =>
            GTE.MAC3 := Value;

         --  IRGB

         when 28     =>
            GTE.IRGB := Value;

         --  ORGB

         when 29     =>
            GTE.ORGB := Value;

         --  LZCS

         when 30     =>
            GTE.LZCS := Value;

            declare
               Count : Word32 := 0;
               Bit   : Word32;
               Sign  : Word32;
            begin
               -- The count is based on the leading bits equal to
               -- the sign bit of LZCS.
               Sign := Interfaces.Shift_Right (Value, 31);

               for I in reverse 0 .. 31 loop
                  Bit := Interfaces.Shift_Right (Value, I) and 1;

                  if Bit = Sign then
                     Count := Count + 1;
                  else
                     exit;
                  end if;
               end loop;

               GTE.LZCR := Count;
            end;

         --  LZCR is read-only.

         when 31     =>
            null;

         when others =>
            null;

      end case;
   end Write_Data;

   function Read_Data (GTE : GTE_State; Index : Natural) return Word32 is
   begin
      case Index is

         when 0      =>
            return
              (GTE.V0_X and 16#0000_FFFF#)
              or Interfaces.Shift_Left (GTE.V0_Y and 16#0000_FFFF#, 16);

         when 1      =>
            return GTE.V0_Z;

         when 2      =>
            return
              (GTE.V1_X and 16#0000_FFFF#)
              or Interfaces.Shift_Left (GTE.V1_Y and 16#0000_FFFF#, 16);

         when 3      =>
            return GTE.V1_Z;

         when 4      =>
            return
              (GTE.V2_X and 16#0000_FFFF#)
              or Interfaces.Shift_Left (GTE.V2_Y and 16#0000_FFFF#, 16);

         when 5      =>
            return GTE.V2_Z;

         when 6      =>
            return GTE.RGBC;

         when 7      =>
            return GTE.OTZ;

         when 8      =>
            return GTE.IR0;

         when 9      =>
            return GTE.IR1;

         when 10     =>
            return GTE.IR2;

         when 11     =>
            return GTE.IR3;

         when 12     =>
            return
              (GTE.SX0 and 16#0000_FFFF#)
              or Interfaces.Shift_Left (GTE.SY0 and 16#0000_FFFF#, 16);

         when 13     =>
            return
              (GTE.SX1 and 16#0000_FFFF#)
              or Interfaces.Shift_Left (GTE.SY1 and 16#0000_FFFF#, 16);

         when 14     =>
            return
              (GTE.SX2 and 16#0000_FFFF#)
              or Interfaces.Shift_Left (GTE.SY2 and 16#0000_FFFF#, 16);

         when 15     =>
            return
              (GTE.SX2 and 16#0000_FFFF#)
              or Interfaces.Shift_Left (GTE.SY2 and 16#0000_FFFF#, 16);

         when 16     =>
            return GTE.SZ0;

         when 17     =>
            return GTE.SZ1;

         when 18     =>
            return GTE.SZ2;

         when 19     =>
            return GTE.SZ3;

         when 20     =>
            return GTE.RGB0;

         when 21     =>
            return GTE.RGB1;

         when 22     =>
            return GTE.RGB2;

         when 23     =>
            return 0;

         when 24     =>
            return GTE.MAC0;

         when 25     =>
            return GTE.MAC1;

         when 26     =>
            return GTE.MAC2;

         when 27     =>
            return GTE.MAC3;

         when 28     =>
            return GTE.IRGB;

         when 29     =>
            return GTE.ORGB;

         when 30     =>
            return GTE.LZCS;

         when 31     =>
            return GTE.LZCR;

         when others =>
            return 0;

      end case;
   end Read_Data;

   function Sign_Extend_16 (Value : Word32) return Word32 is
      V : Word32 := Value and 16#0000_FFFF#;
   begin
      if (V and 16#0000_8000#) /= 0 then
         return V or 16#FFFF_0000#;
      else
         return V;
      end if;
   end Sign_Extend_16;

   procedure Write_Control
     (GTE : in out GTE_State; Index : Natural; Value : Word32) is
   begin
      case Index is

         --  Rotation matrix

         when 32     =>
            GTE.RT11 := Sign_Extend_16 (Value);
            GTE.RT12 := Sign_Extend_16 (Interfaces.Shift_Right (Value, 16));

         when 33     =>
            GTE.RT13 := Sign_Extend_16 (Value);
            GTE.RT21 := Sign_Extend_16 (Interfaces.Shift_Right (Value, 16));

         when 34     =>
            GTE.RT22 := Sign_Extend_16 (Value);
            GTE.RT23 := Sign_Extend_16 (Interfaces.Shift_Right (Value, 16));

         when 35     =>
            GTE.RT31 := Sign_Extend_16 (Value);
            GTE.RT32 := Sign_Extend_16 (Interfaces.Shift_Right (Value, 16));

         when 36     =>
            GTE.RT33 := Sign_Extend_16 (Value);

         --  Translation vector

         when 37     =>
            GTE.TRX := Value;

         when 38     =>
            GTE.TRY := Value;

         when 39     =>
            GTE.TRZ := Value;

         --  Light matrix

         when 40     =>
            GTE.L11 := Value and 16#0000_FFFF#;
            GTE.L12 := Interfaces.Shift_Right (Value, 16) and 16#0000_FFFF#;

         when 41     =>
            GTE.L13 := Value and 16#0000_FFFF#;
            GTE.L21 := Interfaces.Shift_Right (Value, 16) and 16#0000_FFFF#;

         when 42     =>
            GTE.L22 := Value and 16#0000_FFFF#;
            GTE.L23 := Interfaces.Shift_Right (Value, 16) and 16#0000_FFFF#;

         when 43     =>
            GTE.L31 := Value and 16#0000_FFFF#;
            GTE.L32 := Interfaces.Shift_Right (Value, 16) and 16#0000_FFFF#;

         when 44     =>
            GTE.L33 := Value and 16#0000_FFFF#;

         -- Background color

         when 45     =>
            GTE.RBK := Value;

         when 46     =>
            GTE.GBK := Value;

         when 47     =>
            GTE.BBK := Value;

         --  Light color matrix

         when 48     =>
            GTE.LR1 := Value and 16#0000_FFFF#;
            GTE.LR2 := Interfaces.Shift_Right (Value, 16) and 16#0000_FFFF#;

         when 49     =>
            GTE.LR3 := Sign_Extend_16 (Value);
            GTE.LG1 := Sign_Extend_16 (Interfaces.Shift_Right (Value, 16));

         when 50     =>
            GTE.LG2 := Sign_Extend_16 (Value);
            GTE.LG3 := Sign_Extend_16 (Interfaces.Shift_Right (Value, 16));

         when 51     =>
            GTE.LB1 := Sign_Extend_16 (Value);
            GTE.LB2 := Sign_Extend_16 (Interfaces.Shift_Right (Value, 16));

         when 52     =>
            GTE.LB3 := Sign_Extend_16 (Value);

         --  Far color

         when 53     =>
            GTE.RFC := Value;

         when 54     =>
            GTE.GFC := Value;

         when 55     =>
            GTE.BFC := Value;

         --  Screen offset

         when 56     =>
            GTE.OFX := Value;

         when 57     =>
            GTE.OFY := Value;

         --  Projection / depth cue

         when 58     =>
            GTE.H := Value and 16#0000_FFFF#;

         when 59     =>
            GTE.DQA := Sign_Extend_16 (Value);

         when 60     =>
            GTE.DQB := Value;

         when 61     =>
            GTE.ZSF3 := Sign_Extend_16 (Value);

         when 62     =>
            GTE.ZSF4 := Sign_Extend_16 (Value);

         --  FLAG is read-only.

         when 63     =>
            null;

         when others =>
            null;

      end case;
   end Write_Control;

   function Read_Control (GTE : GTE_State; Index : Natural) return Word32 is
   begin
      case Index is

         --  Rotation matrix

         when 32     =>
            return
              (GTE.RT11 and 16#0000_FFFF#)
              or Interfaces.Shift_Left (GTE.RT12 and 16#0000_FFFF#, 16);

         when 33     =>
            return
              (GTE.RT13 and 16#0000_FFFF#)
              or Interfaces.Shift_Left (GTE.RT21 and 16#0000_FFFF#, 16);

         when 34     =>
            return
              (GTE.RT22 and 16#0000_FFFF#)
              or Interfaces.Shift_Left (GTE.RT23 and 16#0000_FFFF#, 16);

         when 35     =>
            return
              (GTE.RT31 and 16#0000_FFFF#)
              or Interfaces.Shift_Left (GTE.RT32 and 16#0000_FFFF#, 16);

         when 36     =>
            return GTE.RT33 and 16#0000_FFFF#;

         --  Translation vector

         when 37     =>
            return GTE.TRX;

         when 38     =>
            return GTE.TRY;

         when 39     =>
            return GTE.TRZ;

         --  Light matrix

         when 40     =>
            return
              (GTE.L11 and 16#0000_FFFF#)
              or Interfaces.Shift_Left (GTE.L12 and 16#0000_FFFF#, 16);

         when 41     =>
            return
              (GTE.L13 and 16#0000_FFFF#)
              or Interfaces.Shift_Left (GTE.L21 and 16#0000_FFFF#, 16);

         when 42     =>
            return
              (GTE.L22 and 16#0000_FFFF#)
              or Interfaces.Shift_Left (GTE.L23 and 16#0000_FFFF#, 16);

         when 43     =>
            return
              (GTE.L31 and 16#0000_FFFF#)
              or Interfaces.Shift_Left (GTE.L32 and 16#0000_FFFF#, 16);

         when 44     =>
            return GTE.L33 and 16#0000_FFFF#;

         --  Background color

         when 45     =>
            return GTE.RBK;

         when 46     =>
            return GTE.GBK;

         when 47     =>
            return GTE.BBK;

         --  Light color matrix

         when 48     =>
            return
              (GTE.LR1 and 16#0000_FFFF#)
              or Interfaces.Shift_Left (GTE.LR2 and 16#0000_FFFF#, 16);

         when 49     =>
            return
              (GTE.LR3 and 16#0000_FFFF#)
              or Interfaces.Shift_Left (GTE.LG1 and 16#0000_FFFF#, 16);

         when 50     =>
            return
              (GTE.LG2 and 16#0000_FFFF#)
              or Interfaces.Shift_Left (GTE.LG3 and 16#0000_FFFF#, 16);

         when 51     =>
            return
              (GTE.LB1 and 16#0000_FFFF#)
              or Interfaces.Shift_Left (GTE.LB2 and 16#0000_FFFF#, 16);

         when 52     =>
            return GTE.LB3 and 16#0000_FFFF#;

         --  Far color

         when 53     =>
            return GTE.RFC;

         when 54     =>
            return GTE.GFC;

         when 55     =>
            return GTE.BFC;

         --  Screen offset

         when 56     =>
            return GTE.OFX;

         when 57     =>
            return GTE.OFY;

         --  Projection / depth cue

         when 58     =>
            return GTE.H and 16#0000_FFFF#;

         when 59     =>
            return GTE.DQA and 16#0000_FFFF#;

         when 60     =>
            return GTE.DQB;

         when 61     =>
            return GTE.ZSF3 and 16#0000_FFFF#;

         when 62     =>
            return GTE.ZSF4 and 16#0000_FFFF#;

         --  FLAG

         when 63     =>
            return GTE.FLAG;

         when others =>
            return 0;

      end case;
   end Read_Control;

end PSX.GTE;
