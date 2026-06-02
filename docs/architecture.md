# NeXTcube-on-FPGA Starter Architecture

This tree is a starting point, not a cycle-accurate NeXTcube clone. It gives
each major custom-chip responsibility a stable VHDL boundary so the internals
can be refined against schematics, ROM behavior, and bus traces.

## Source Layout

- `rtl/next_types_pkg.vhd`: shared bus, DMA, and IRQ record types.
- `rtl/next_memory_map_pkg.vhd`: starter address decode constants.
- `rtl/next_bus_arbiter.vhd`: CPU/DMA master selection.
- `rtl/next_bus_decode.vhd`: address decoder for RAM, ROM, VRAM, and ASICs.
- `rtl/next_simple_ram.vhd`: small inferred RAM/ROM/VRAM block.
- `rtl/next_system_asic.vhd`: reset, interrupt mask/pending, system ID.
- `rtl/next_dma_asic.vhd`: register file plus a minimal word-copy DMA engine.
- `rtl/next_video_asic.vhd`: 1120x832-style monochrome timing placeholder.
- `rtl/next_sound_asic.vhd`: simple sample register and PWM output.
- `rtl/next_io_asic.vhd`: keyboard, serial, RTC, SCSI, and Ethernet IRQ shell.
- `rtl/nextcube_soc.vhd`: top-level 68030-style socket and chip integration.
- `tb/nextcube_soc_tb.vhd`: basic bus read/write smoke test.

## What Is Intentionally Incomplete

- The MC68030 is not implemented. `nextcube_soc` exposes a simple external
  68030-style bus so an existing 68k core or physical CPU bridge can be added.
- ROM contents are a placeholder word. Replace `next_simple_ram` for ROM with a
  vendor block RAM initialized from the real boot ROM image.
- VRAM fetch is not wired into the video path yet. The video ASIC currently
  generates timing and a checkerboard test pattern.
- SCSI, Ethernet, SCC serial, keyboard/mouse protocol, magneto-optical storage,
  DSP56001 behavior, and floppy/MO details are represented as register/IRQ
  shells only.
- The address map is deliberately simple and must be corrected as hardware
  references are brought in.

## Suggested Next Steps

1. Replace the external CPU socket with a synthesizable 68030-compatible core or
   a 68020/68030 bus bridge.
2. Replace the ROM placeholder with real boot ROM initialization and adjust the
   reset vector address map until the CPU fetches sensible vectors.
3. Make `next_video_asic` fetch packed monochrome pixels from VRAM.
4. Expand `next_dma_asic` into independent channels for sound, SCSI, Ethernet,
   and video where needed.
5. Implement real SCC, SCSI, Ethernet, RTC/NVRAM, keyboard, and DSP register
   maps as ROM/software expectations become known.
