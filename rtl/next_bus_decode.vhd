library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.next_types_pkg.all;
use work.next_memory_map_pkg.all;

entity next_bus_decode is
  port (
    cpu_req    : in  bus_req_t;
    cpu_rsp    : out bus_rsp_t;

    ram_req    : out bus_req_t;
    ram_rsp    : in  bus_rsp_t;
    rom_req    : out bus_req_t;
    rom_rsp    : in  bus_rsp_t;
    vram_req   : out bus_req_t;
    vram_rsp   : in  bus_rsp_t;
    system_req : out bus_req_t;
    system_rsp : in  bus_rsp_t;
    dma_req    : out bus_req_t;
    dma_rsp    : in  bus_rsp_t;
    video_req  : out bus_req_t;
    video_rsp  : in  bus_rsp_t;
    sound_req  : out bus_req_t;
    sound_rsp  : in  bus_rsp_t;
    io_req     : out bus_req_t;
    io_rsp     : in  bus_rsp_t
  );
end entity;

architecture rtl of next_bus_decode is
begin
  process(all)
  begin
    ram_req    <= BUS_REQ_IDLE;
    rom_req    <= BUS_REQ_IDLE;
    vram_req   <= BUS_REQ_IDLE;
    system_req <= BUS_REQ_IDLE;
    dma_req    <= BUS_REQ_IDLE;
    video_req  <= BUS_REQ_IDLE;
    sound_req  <= BUS_REQ_IDLE;
    io_req     <= BUS_REQ_IDLE;
    cpu_rsp    <= BUS_RSP_IDLE;

    if cpu_req.valid = '1' then
      if in_range(cpu_req.addr, ADDR_RAM_BASE, ADDR_RAM_MASK) then
        ram_req <= cpu_req;
        cpu_rsp <= ram_rsp;
      elsif in_range(cpu_req.addr, ADDR_ROM_BASE, ADDR_ROM_MASK) then
        rom_req <= cpu_req;
        cpu_rsp <= rom_rsp;
      elsif in_range(cpu_req.addr, ADDR_VRAM_BASE, ADDR_VRAM_MASK) then
        vram_req <= cpu_req;
        cpu_rsp <= vram_rsp;
      elsif in_range(cpu_req.addr, ADDR_SYSTEM_BASE, ADDR_SYSTEM_MASK) then
        system_req <= cpu_req;
        cpu_rsp <= system_rsp;
      elsif in_range(cpu_req.addr, ADDR_DMA_BASE, ADDR_DMA_MASK) then
        dma_req <= cpu_req;
        cpu_rsp <= dma_rsp;
      elsif in_range(cpu_req.addr, ADDR_VIDEO_BASE, ADDR_VIDEO_MASK) then
        video_req <= cpu_req;
        cpu_rsp <= video_rsp;
      elsif in_range(cpu_req.addr, ADDR_SOUND_BASE, ADDR_SOUND_MASK) then
        sound_req <= cpu_req;
        cpu_rsp <= sound_rsp;
      elsif in_range(cpu_req.addr, ADDR_IO_BASE, ADDR_IO_MASK) then
        io_req <= cpu_req;
        cpu_rsp <= io_rsp;
      else
        cpu_rsp.ready <= '1';
        cpu_rsp.rdata <= (others => '0');
        cpu_rsp.err   <= '1';
      end if;
    end if;
  end process;
end architecture;
