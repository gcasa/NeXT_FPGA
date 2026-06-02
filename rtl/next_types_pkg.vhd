library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package next_types_pkg is
  subtype u8  is unsigned(7 downto 0);
  subtype u16 is unsigned(15 downto 0);
  subtype u32 is unsigned(31 downto 0);

  subtype slv8  is std_logic_vector(7 downto 0);
  subtype slv16 is std_logic_vector(15 downto 0);
  subtype slv32 is std_logic_vector(31 downto 0);

  type bus_req_t is record
    valid : std_logic;
    rw    : std_logic; -- '1' read, '0' write
    addr  : slv32;
    wdata : slv32;
    be    : std_logic_vector(3 downto 0);
  end record;

  type bus_rsp_t is record
    ready : std_logic;
    rdata : slv32;
    err   : std_logic;
  end record;

  type dma_req_t is record
    valid : std_logic;
    rw    : std_logic;
    addr  : slv32;
    wdata : slv32;
    be    : std_logic_vector(3 downto 0);
  end record;

  type dma_rsp_t is record
    ready : std_logic;
    rdata : slv32;
    err   : std_logic;
  end record;

  type irq_lines_t is record
    video_vblank : std_logic;
    sound        : std_logic;
    scsi         : std_logic;
    ethernet     : std_logic;
    serial       : std_logic;
    rtc          : std_logic;
    dma          : std_logic;
  end record;

  constant BUS_REQ_IDLE : bus_req_t := (
    valid => '0',
    rw    => '1',
    addr  => (others => '0'),
    wdata => (others => '0'),
    be    => (others => '0')
  );

  constant BUS_RSP_IDLE : bus_rsp_t := (
    ready => '0',
    rdata => (others => '0'),
    err   => '0'
  );

  constant DMA_REQ_IDLE : dma_req_t := (
    valid => '0',
    rw    => '1',
    addr  => (others => '0'),
    wdata => (others => '0'),
    be    => (others => '0')
  );

  constant DMA_RSP_IDLE : dma_rsp_t := (
    ready => '0',
    rdata => (others => '0'),
    err   => '0'
  );

  constant IRQ_LINES_IDLE : irq_lines_t := (
    video_vblank => '0',
    sound        => '0',
    scsi         => '0',
    ethernet     => '0',
    serial       => '0',
    rtc          => '0',
    dma          => '0'
  );
end package;
