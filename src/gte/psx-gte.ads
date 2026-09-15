with PSX.Types;
with Interfaces;

package PSX.GTE is

   use type Interfaces.Unsigned_32;
   subtype Word32 is PSX.Types.Word32;

   type GTE_State is record

      -- Data registers

      V0_X : Word32;
      V0_Y : Word32;
      V0_Z : Word32;

      V1_X : Word32;
      V1_Y : Word32;
      V1_Z : Word32;

      V2_X : Word32;
      V2_Y : Word32;
      V2_Z : Word32;

      RGBC : Word32;
      OTZ  : Word32;

      IR0 : Word32;
      IR1 : Word32;
      IR2 : Word32;
      IR3 : Word32;

      SX0 : Word32;
      SY0 : Word32;
      SX1 : Word32;
      SY1 : Word32;
      SX2 : Word32;
      SY2 : Word32;

      SZ0 : Word32;
      SZ1 : Word32;
      SZ2 : Word32;
      SZ3 : Word32;

      RGB0 : Word32;
      RGB1 : Word32;
      RGB2 : Word32;

      MAC0 : Word32;
      MAC1 : Word32;
      MAC2 : Word32;
      MAC3 : Word32;

      IRGB : Word32;
      ORGB : Word32;

      LZCS : Word32;
      LZCR : Word32;

      -- Control registers

      RT11 : Word32;
      RT12 : Word32;
      RT13 : Word32;
      RT21 : Word32;
      RT22 : Word32;
      RT23 : Word32;
      RT31 : Word32;
      RT32 : Word32;
      RT33 : Word32;

      TRX : Word32;
      TRY : Word32;
      TRZ : Word32;

      L11 : Word32;
      L12 : Word32;
      L13 : Word32;
      L21 : Word32;
      L22 : Word32;
      L23 : Word32;
      L31 : Word32;
      L32 : Word32;
      L33 : Word32;

      RBK : Word32;
      GBK : Word32;
      BBK : Word32;

      LR1 : Word32;
      LR2 : Word32;
      LR3 : Word32;
      LG1 : Word32;
      LG2 : Word32;
      LG3 : Word32;
      LB1 : Word32;
      LB2 : Word32;
      LB3 : Word32;

      RFC : Word32;
      GFC : Word32;
      BFC : Word32;

      OFX : Word32;
      OFY : Word32;

      H : Word32;

      DQA : Word32;
      DQB : Word32;

      ZSF3 : Word32;
      ZSF4 : Word32;

      FLAG : Word32;

   end record;

   procedure Reset (GTE : out GTE_State);

      procedure Write_Data
     (GTE   : in out GTE_State;
      Index : Natural;
      Value : Word32);

   function Read_Data
     (GTE   : GTE_State;
      Index : Natural) return Word32;

   procedure Write_Control
     (GTE   : in out GTE_State;
      Index : Natural;
      Value : Word32);

   function Read_Control
     (GTE   : GTE_State;
      Index : Natural) return Word32;

end PSX.GTE;