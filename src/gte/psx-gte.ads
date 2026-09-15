with PSX.Types;

package PSX.GTE is

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

      -- MAC registers
      MAC0 : Word32;
      MAC1 : Word32;
      MAC2 : Word32;
      MAC3 : Word32;

      -- RGB registers
      RGB0 : Word32;
      RGB1 : Word32;
      RGB2 : Word32;

      -- IR registers
      IR0 : Word32;
      IR1 : Word32;
      IR2 : Word32;
      IR3 : Word32;

      -- Screen coordinates
      SX0 : Word32;
      SY0 : Word32;
      SX1 : Word32;
      SY1 : Word32;
      SX2 : Word32;
      SY2 : Word32;

      -- Depth
      SZ0 : Word32;
      SZ1 : Word32;
      SZ2 : Word32;
      SZ3 : Word32;

      -- Control registers
      RT11 : Word32;
      RT12 : Word32;
      RT13 : Word32;

      TRX : Word32;
      TRY : Word32;
      TRZ : Word32;

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

end PSX.GTE;
