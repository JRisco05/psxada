# psxada 🎮✨

Un emulador de **PlayStation 1 (PSX)** de código abierto centrado en la **Emulación de Bajo Nivel (LLE)** y desarrollado de forma nativa para macOS en **Ada** y **Metal** (Apple Silicon).

El objetivo principal de este proyecto es la máxima fidelidad y seguridad en la emulación del hardware original, buscando un rendimiento óptimo a través de un intérprete optimizado y renderizado por GPU acelerado sin recurrir a la compilación dinámica (JIT) para mantener la integridad total de la memoria.

---

## 🚀 Estado del Proyecto y Objetivos

Nuestra meta a largo plazo es alcanzar e igualar la precisión de emuladores de referencia como DuckStation, pero bajo un entorno seguro provisto por la arquitectura de Ada.

- **CPU:** Intérprete puro (MIPS I / R3000A) enfocado en precisión a nivel de ciclo.
- **DMA:** Implementado el canal OTC (Ordering Table Clear). En proceso de extender los canales multimedia (GPU/SPU).
- **Audio (SPU):** Pruebas iniciales de registros de control y acceso de lectura/escritura en SPU RAM completadas exitosamente.
- **Gráficos:** El motor se apoyará en Metal para el renderizado nativo y el escalado de resolución en macOS sin romper las barreras de bajo nivel.

---

## 🔬 Estado de los Tests Actuales

El proyecto utiliza pruebas unitarias para garantizar el comportamiento LLE del hardware. Actualmente pasamos los siguientes bloques:

### DMA (Direct Memory Access)

- `PASS`: OTC entry 0
- `PASS`: OTC entry 1
- `PASS`: OTC entry 2
- `PASS`: OTC terminator
- `PASS`: OTC DMA completed

### SPU (Sound Processing Unit)

- `PASS`: SPU Control, Status, Transfer & IRQ Address resets
- `PASS`: SPU RAM read/write boundaries (0x0, 0x10000, and Last Address)
- `PASS`: SPU RAM independent addressing

---

## 🤝 ¿Cómo contribuir? (¡Se busca ayuda!)

El núcleo lógico del emulador está expuesto públicamente para mejorar su precisión mediante la revisión de la comunidad. Actualmente estamos buscando ayuda especializada en dos áreas críticas:

### 1. El motor DMA (Direct Memory Access)

Necesitamos implementar y validar el resto de los 7 canales de transferencia de la PS1:

- Transferencias en modo bloque (_Block/Slice_) para sincronizar CPU de forma correcta.
- Lógica de la lista enlazada (_Linked List_) utilizada por la GPU para caminar la Ordering Table.

### 2. El subsistema de Audio (SPU)

- Desarrollo del decodificador de bloques comprimidos **ADPCM** a muestras PCM de 16 bits.
- Lógica para las curvas de volumen automatizadas de las 24 voces (**Envolvente ADSR**).
- Manejo exacto de las interrupciones del SPU (Audio IRQ).

Si tienes experiencia con la arquitectura MIPS, procesamiento de señales a bajo nivel o desarrollo en **Ada**, ¡tus pull requests son más que bienvenidas!

---

## 🛡️ Filosofía de Seguridad

A diferencia de otros emuladores que dependen de compiladores JIT (Just-In-Time) inyectando código dinámico en la memoria intermedia (rompiendo protecciones de macOS), **psxada** apuesta por:

1. Un intérprete seguro nativo en Ada.
2. Control estricto de tipos y excepciones en tiempo de desarrollo.
3. El uso estratégico de `pragma Suppress(All_Checks);` únicamente para el binario final optimizado de producción.
