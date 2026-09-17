with Interfaces;
with PSX.Memory;
with PSX.GPU; -- Añadido para poder interactuar con la pantalla de la GPU

package body PSX.DMA is

   use type Interfaces.Unsigned_32;

    DMA_BASE : constant Word32 := 16#1F80_1080#;

   --  Nuevas Constantes para el Canal 2 (GPU)
   DMA2_MADR : constant Word32 := DMA_BASE + 16#20#;
   DMA2_BCR  : constant Word32 := DMA_BASE + 16#24#;
   DMA2_CHCR : constant Word32 := DMA_BASE + 16#28#;

   --  Constantes existentes para el Canal 6 (OTC)
   DMA6_MADR : constant Word32 := DMA_BASE + 16#60#;
   DMA6_BCR  : constant Word32 := DMA_BASE + 16#64#;
   DMA6_CHCR : constant Word32 := DMA_BASE + 16#68#;

   procedure Reset (Memory : in out PSX.Memory.Memory_State) is
   begin
      Memory.DMA_Registers := (others => 0);
   end Reset;

   function Read_DMA_Register
     (Memory : PSX.Memory.Memory_State; Address : Word32) return Word32 is
   begin
      return Memory.DMA_Registers ((Address - DMA_BASE) / 4);
   end Read_DMA_Register;

   procedure Write_DMA_Register
     (Memory  : in out PSX.Memory.Memory_State;
      Address : Word32;
      Value   : Word32) is
   begin
      Memory.DMA_Registers ((Address - DMA_BASE) / 4) := Value;
   end Write_DMA_Register;

   --  Procedimiento interno para procesar el Canal 2 (RAM -> GPU)
   procedure Process_GPU
     (Memory : in out PSX.Memory.Memory_State; GPU : in out PSX.GPU.GPU_State)
   is
      MADR : Word32;
      BCR  : Word32;
      CHCR : Word32;

      Address : Word32;
      Count   : Word32;
      Value   : Word32;
   begin
      MADR := Read_DMA_Register (Memory, DMA2_MADR);
      BCR := Read_DMA_Register (Memory, DMA2_BCR);
      CHCR := Read_DMA_Register (Memory, DMA2_CHCR);

      --  El canal 2 debe estar activo.
      if (CHCR and 16#0100_0000#) = 0 then
         return;
      end if;

      --  La dirección de la transferencia debe ser obligatoriamente RAM -> GPU.
      if (CHCR and 16#0000_0001#) /= 0 then
         return;
      end if;

      --  Modo Manual.
      if ((CHCR and 16#0000_0600#) /= 0) then
         return;
      end if;

      --  Cantidad de palabras (words) a transferir.
      Count := BCR and 16#0000_FFFF#;

      if Count = 0 then
         return;
      end if;

      Address := MADR;

      while Count > 0 loop
         --  Leemos el dato de la memoria
         Value := PSX.Memory.Read_32 (Memory, Address);

         --  Se lo mandamos directo al GP0 de la GPU
         PSX.GPU.Write_GP0 (GPU, Value);

         Address := Address + 4;
         Count := Count - 1;
      end loop;

      --  Apagamos el bit de "DMA activo" porque la transferencia terminó.
      CHCR := CHCR and not 16#0100_0000#;

      Write_DMA_Register (Memory, DMA2_CHCR, CHCR);
   end Process_GPU;

   --  Procedimiento existente para procesar el Canal 6 (OTC)
   procedure Process_OTC (Memory : in out PSX.Memory.Memory_State) is
      MADR : Word32;
      BCR  : Word32;
      CHCR : Word32;

      Address : Word32;
      Count   : Word32;
      Next    : Word32;
   begin
      MADR := Read_DMA_Register (Memory, DMA6_MADR);
      BCR := Read_DMA_Register (Memory, DMA6_BCR);
      CHCR := Read_DMA_Register (Memory, DMA6_CHCR);

      if (CHCR and 16#0100_0000#) = 0 then
         return;
      end if;

      if ((CHCR and 16#0000_0600#) /= 0) then
         return;
      end if;

      Count := BCR and 16#0000_FFFF#;

      if Count = 0 then
         return;
      end if;

      Address := MADR;

      while Count > 1 loop
         Next := Address - 4;
         PSX.Memory.Write_32 (Memory, Address, Next);
         Address := Next;
         Count := Count - 1;
      end loop;

      PSX.Memory.Write_32 (Memory, Address, 16#00FF_FFFF#);

      CHCR := CHCR and not 16#0100_0000#;
      Write_DMA_Register (Memory, DMA6_CHCR, CHCR);
   end Process_OTC;

   --  IMPLEMENTACIÓN DE LAS DOS VERSIONES DE PROCESS

   --  Versión 1: (Solo Memory) Ejecuta el Canal 6 si está activo.
   procedure Process (Memory : in out PSX.Memory.Memory_State) is
      CHCR : Word32;
   begin
      CHCR := Read_DMA_Register (Memory, DMA6_CHCR);

      if (CHCR and 16#0100_0000#) /= 0 then
         Process_OTC (Memory);
      end if;
   end Process;

   --  Versión 2: (Memory + GPU) Revisa el Canal 2 de la GPU y luego el 6 de OTC.
   procedure Process
     (Memory : in out PSX.Memory.Memory_State; GPU : in out PSX.GPU.GPU_State)
   is
      CHCR : Word32;
   begin
      --  Revisamos Canal 2: GPU
      CHCR := Read_DMA_Register (Memory, DMA2_CHCR);

      if (CHCR and 16#0100_0000#) /= 0 then
         Process_GPU (Memory, GPU);
      end if;

      --  Revisamos Canal 6: OTC
      CHCR := Read_DMA_Register (Memory, DMA6_CHCR);

      if (CHCR and 16#0100_0000#) /= 0 then
         Process_OTC (Memory);
      end if;
   end Process;

end PSX.DMA;
