# NeXT_FPGA

NeXT_FPGA is a VHDL starter implementation of a NeXTcube-style system-on-chip.
It is intended as a structured hardware model, not a cycle-accurate clone. The
current design gives the major NeXT custom-chip responsibilities stable module
boundaries so they can be refined incrementally against schematics, ROM
behavior, bus traces, and real peripheral documentation.

## Current Scope

The repository currently contains:

- A 68030-style external CPU bus socket.
- An optional internal 68040 integration shell.
- Shared bus, DMA, and interrupt record types.
- A starter memory map and address decoder.
- Inferred RAM, ROM, and VRAM blocks.
- A simple CPU/DMA bus arbiter.
- Shell implementations for system, DMA, video, sound, and I/O ASIC behavior.
- A GHDL smoke test that exercises RAM readback and a few ASIC registers.

Several important NeXT subsystems are represented only as placeholders. This
tree is best treated as a foundation for bringing up individual hardware
responsibilities one at a time.

## Repository Layout

```text
.
├── Makefile
├── docs/
│   └── architecture.md
├── rtl/
│   ├── next_bus_arbiter.vhd
│   ├── next_bus_decode.vhd
│   ├── next_dma_asic.vhd
│   ├── next_io_asic.vhd
│   ├── next_memory_map_pkg.vhd
│   ├── next_m68040_core.vhd
│   ├── next_simple_ram.vhd
│   ├── next_sound_asic.vhd
│   ├── next_system_asic.vhd
│   ├── next_types_pkg.vhd
│   ├── next_video_asic.vhd
│   └── nextcube_soc.vhd
└── tb/
    └── nextcube_soc_tb.vhd
```

See [docs/architecture.md](docs/architecture.md) for a module-by-module
architecture overview and suggested next steps.

## Requirements

- `make`
- `ghdl` with VHDL-2008 support

The `Makefile` defaults to `ghdl` and `--std=08`. Override them if your toolchain
uses different command names or flags:

```sh
make GHDL=/path/to/ghdl VHDL_STD=--std=08 test
```

## Build and Test

Analyze the RTL:

```sh
make analyze
```

Run the testbench:

```sh
make test
```

Clean GHDL build artifacts:

```sh
make clean
```

The testbench instantiates `nextcube_soc` with small RAM/ROM/VRAM memories, then
performs basic bus reads and writes. Passing this test means the starter bus
plumbing is coherent; it does not imply machine-level compatibility.

## CPU Integration

The top-level entity defaults to the original external 68k-style CPU socket.
Set `USE_INTERNAL_68040 => true` on `nextcube_soc` to select the internal
`next_m68040_core` bus master instead.

`next_m68040_core` is a CPU integration shell, not a complete MC68040
instruction implementation. It issues the reset-vector reads at addresses
`0x00000000` and `0x00000004`, latches the initial PC, and then idles. This
keeps the SoC wiring ready for a real synthesizable 68040-compatible core
without inventing inaccurate instruction behavior.

## Top-Level Interface

The top-level entity is `nextcube_soc` in `rtl/nextcube_soc.vhd`. It exposes:

- `clk_40m` and synchronous reset input.
- A simple 32-bit 68k-style address/data bus.
- 68k-style `AS`, `RW`, byte enables, `DSACK`, `IPL`, and reset signals.
- Monochrome video timing outputs.
- A PWM audio output.
- Keyboard, serial, SCSI IRQ, and Ethernet IRQ hooks.

The current ROM is an inferred read-only RAM initialized with a placeholder
word. Replace it with a vendor block RAM or ROM loader once real boot ROM
integration is added.

## Known Gaps

- No complete MC68040 instruction core is implemented.
- The address map is a pragmatic starter map, not confirmed cycle-accurate NeXT
  decoding.
- ROM contents and reset-vector behavior are placeholders.
- Video timing exists, but VRAM pixel fetch is not wired into the video path.
- SCSI, Ethernet, SCC serial, keyboard/mouse, RTC/NVRAM, DSP56001, floppy, and
  magneto-optical behavior are register or IRQ shells only.
- The DMA block is currently a minimal word-copy engine rather than a complete
  channel implementation.

## Development Direction

Good next milestones are:

1. Integrate a synthesizable 68020/68030-compatible CPU core or external CPU
   bridge.
2. Replace the placeholder ROM with real boot ROM initialization.
3. Refine the memory map using hardware references and ROM expectations.
4. Wire video output to packed monochrome VRAM fetches.
5. Expand DMA and I/O ASIC models around real software-visible register maps.
