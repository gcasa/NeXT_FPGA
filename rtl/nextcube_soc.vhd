library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.next_types_pkg.all;

entity nextcube_soc is
  generic (
    RAM_ADDR_BITS  : positive := 16;
    ROM_ADDR_BITS  : positive := 14;
    VRAM_ADDR_BITS : positive := 16;
    USE_INTERNAL_68040 : boolean := false
  );
  port (
    clk_40m       : in    std_logic;
    rst           : in    std_logic;

    m68k_addr     : in    std_logic_vector(31 downto 0);
    m68k_data     : inout std_logic_vector(31 downto 0);
    m68k_as_n     : in    std_logic;
    m68k_rw       : in    std_logic;
    m68k_be_n     : in    std_logic_vector(3 downto 0);
    m68k_dsack_n  : out   std_logic_vector(1 downto 0);
    m68k_ipl_n    : out   std_logic_vector(2 downto 0);
    m68k_reset_n  : out   std_logic;

    video_pixel   : out   std_logic;
    video_hsync   : out   std_logic;
    video_vsync   : out   std_logic;
    video_blank   : out   std_logic;

    audio_pwm     : out   std_logic;

    kbd_rx        : in    std_logic := '1';
    kbd_tx        : out   std_logic;
    serial_rx     : in    std_logic := '1';
    serial_tx     : out   std_logic;
    scsi_irq      : in    std_logic := '0';
    eth_irq       : in    std_logic := '0'
  );
end entity;

architecture rtl of nextcube_soc is
  signal cpu_req       : bus_req_t := BUS_REQ_IDLE;
  signal cpu_rsp       : bus_rsp_t := BUS_RSP_IDLE;
  signal external_cpu_req : bus_req_t := BUS_REQ_IDLE;
  signal internal_cpu_req : bus_req_t := BUS_REQ_IDLE;
  signal arb_req       : bus_req_t := BUS_REQ_IDLE;
  signal arb_rsp       : bus_rsp_t := BUS_RSP_IDLE;

  signal ram_req       : bus_req_t := BUS_REQ_IDLE;
  signal ram_rsp       : bus_rsp_t := BUS_RSP_IDLE;
  signal rom_req       : bus_req_t := BUS_REQ_IDLE;
  signal rom_rsp       : bus_rsp_t := BUS_RSP_IDLE;
  signal vram_req      : bus_req_t := BUS_REQ_IDLE;
  signal vram_rsp      : bus_rsp_t := BUS_RSP_IDLE;
  signal system_req    : bus_req_t := BUS_REQ_IDLE;
  signal system_rsp    : bus_rsp_t := BUS_RSP_IDLE;
  signal dma_regs_req  : bus_req_t := BUS_REQ_IDLE;
  signal dma_regs_rsp  : bus_rsp_t := BUS_RSP_IDLE;
  signal video_req     : bus_req_t := BUS_REQ_IDLE;
  signal video_rsp     : bus_rsp_t := BUS_RSP_IDLE;
  signal sound_req     : bus_req_t := BUS_REQ_IDLE;
  signal sound_rsp     : bus_rsp_t := BUS_RSP_IDLE;
  signal io_req        : bus_req_t := BUS_REQ_IDLE;
  signal io_rsp        : bus_rsp_t := BUS_RSP_IDLE;

  signal dma_master_req : dma_req_t := DMA_REQ_IDLE;
  signal dma_master_rsp : dma_rsp_t := DMA_RSP_IDLE;

  signal irq_lines     : irq_lines_t := IRQ_LINES_IDLE;
  signal rtc_irq       : std_logic := '0';
  signal io_irq        : std_logic := '0';
  signal system_reset_n : std_logic := '0';
  signal internal_cpu_reset_n : std_logic := '0';
  signal cpu_ipl_n      : std_logic_vector(2 downto 0) := (others => '1');
  signal internal_cpu_boot_done : std_logic := '0';
  signal internal_cpu_pc : std_logic_vector(31 downto 0) := (others => '0');
begin
  external_cpu_req.valid <= not m68k_as_n;
  external_cpu_req.rw    <= m68k_rw;
  external_cpu_req.addr  <= m68k_addr;
  external_cpu_req.wdata <= m68k_data;
  external_cpu_req.be    <= not m68k_be_n;

  cpu_req <= internal_cpu_req when USE_INTERNAL_68040 else external_cpu_req;

  m68k_data <= cpu_rsp.rdata when USE_INTERNAL_68040 = false and cpu_rsp.ready = '1' and m68k_rw = '1' else (others => 'Z');
  m68k_dsack_n <= "00" when USE_INTERNAL_68040 = false and cpu_rsp.ready = '1' else "11";
  m68k_ipl_n <= cpu_ipl_n;
  m68k_reset_n <= system_reset_n;
  internal_cpu_reset_n <= not rst;

  irq_lines.scsi <= scsi_irq;
  irq_lines.ethernet <= eth_irq;
  irq_lines.serial <= io_irq;
  irq_lines.rtc <= rtc_irq;

  internal_cpu_i : entity work.next_m68040_core
    port map (
      clk       => clk_40m,
      rst       => rst,
      reset_n   => internal_cpu_reset_n,
      ipl_n     => cpu_ipl_n,
      bus_req   => internal_cpu_req,
      bus_rsp   => cpu_rsp,
      boot_done => internal_cpu_boot_done,
      pc        => internal_cpu_pc
    );

  arbiter_i : entity work.next_bus_arbiter
    port map (
      cpu_req => cpu_req,
      cpu_rsp => cpu_rsp,
      dma_req => dma_master_req,
      dma_rsp => dma_master_rsp,
      mem_req => arb_req,
      mem_rsp => arb_rsp
    );

  decode_i : entity work.next_bus_decode
    port map (
      cpu_req    => arb_req,
      cpu_rsp    => arb_rsp,
      ram_req    => ram_req,
      ram_rsp    => ram_rsp,
      rom_req    => rom_req,
      rom_rsp    => rom_rsp,
      vram_req   => vram_req,
      vram_rsp   => vram_rsp,
      system_req => system_req,
      system_rsp => system_rsp,
      dma_req    => dma_regs_req,
      dma_rsp    => dma_regs_rsp,
      video_req  => video_req,
      video_rsp  => video_rsp,
      sound_req  => sound_req,
      sound_rsp  => sound_rsp,
      io_req     => io_req,
      io_rsp     => io_rsp
    );

  ram_i : entity work.next_simple_ram
    generic map (
      ADDR_BITS => RAM_ADDR_BITS,
      READ_ONLY => false,
      INIT_WORD => x"00000000"
    )
    port map (
      clk => clk_40m,
      rst => rst,
      req => ram_req,
      rsp => ram_rsp
    );

  rom_i : entity work.next_simple_ram
    generic map (
      ADDR_BITS => ROM_ADDR_BITS,
      READ_ONLY => true,
      INIT_WORD => x"4E585452"
    )
    port map (
      clk => clk_40m,
      rst => rst,
      req => rom_req,
      rsp => rom_rsp
    );

  vram_i : entity work.next_simple_ram
    generic map (
      ADDR_BITS => VRAM_ADDR_BITS,
      READ_ONLY => false,
      INIT_WORD => x"AAAAAAAA"
    )
    port map (
      clk => clk_40m,
      rst => rst,
      req => vram_req,
      rsp => vram_rsp
    );

  system_i : entity work.next_system_asic
    port map (
      clk     => clk_40m,
      rst     => rst,
      req     => system_req,
      rsp     => system_rsp,
      irq_in  => irq_lines,
      irq_out => cpu_ipl_n,
      reset_n => system_reset_n
    );

  dma_i : entity work.next_dma_asic
    port map (
      clk     => clk_40m,
      rst     => rst,
      req     => dma_regs_req,
      rsp     => dma_regs_rsp,
      dma_req => dma_master_req,
      dma_rsp => dma_master_rsp,
      irq     => irq_lines.dma
    );

  video_i : entity work.next_video_asic
    port map (
      clk        => clk_40m,
      rst        => rst,
      req        => video_req,
      rsp        => video_rsp,
      pixel      => video_pixel,
      hsync      => video_hsync,
      vsync      => video_vsync,
      blank      => video_blank,
      vblank_irq => irq_lines.video_vblank
    );

  sound_i : entity work.next_sound_asic
    port map (
      clk       => clk_40m,
      rst       => rst,
      req       => sound_req,
      rsp       => sound_rsp,
      audio_pwm => audio_pwm,
      irq       => irq_lines.sound
    );

  io_i : entity work.next_io_asic
    port map (
      clk       => clk_40m,
      rst       => rst,
      req       => io_req,
      rsp       => io_rsp,
      kbd_rx    => kbd_rx,
      kbd_tx    => kbd_tx,
      serial_rx => serial_rx,
      serial_tx => serial_tx,
      scsi_irq  => scsi_irq,
      eth_irq   => eth_irq,
      rtc_irq   => rtc_irq,
      io_irq    => io_irq
    );
end architecture;
