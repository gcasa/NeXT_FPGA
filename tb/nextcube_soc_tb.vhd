library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity nextcube_soc_tb is
end entity;

architecture sim of nextcube_soc_tb is
  signal clk          : std_logic := '0';
  signal rst          : std_logic := '1';
  signal addr         : std_logic_vector(31 downto 0) := (others => '0');
  signal data         : std_logic_vector(31 downto 0) := (others => 'Z');
  signal as_n         : std_logic := '1';
  signal rw           : std_logic := '1';
  signal be_n         : std_logic_vector(3 downto 0) := (others => '0');
  signal dsack_n      : std_logic_vector(1 downto 0);
  signal ipl_n        : std_logic_vector(2 downto 0);
  signal reset_n      : std_logic;
  signal pixel        : std_logic;
  signal hsync        : std_logic;
  signal vsync        : std_logic;
  signal blank        : std_logic;
  signal audio_pwm    : std_logic;
  signal kbd_tx       : std_logic;
  signal serial_tx    : std_logic;

  procedure bus_write(
    signal clk_s  : in std_logic;
    signal addr_s : out std_logic_vector(31 downto 0);
    signal data_s : inout std_logic_vector(31 downto 0);
    signal as_s   : out std_logic;
    signal rw_s   : out std_logic;
    signal ds_s   : in std_logic_vector(1 downto 0);
    constant a    : in std_logic_vector(31 downto 0);
    constant d    : in std_logic_vector(31 downto 0)
  ) is
  begin
    wait until rising_edge(clk_s);
    addr_s <= a;
    data_s <= d;
    rw_s <= '0';
    as_s <= '0';
    wait until rising_edge(clk_s) and ds_s = "00";
    as_s <= '1';
    data_s <= (others => 'Z');
  end procedure;

  procedure bus_read(
    signal clk_s  : in std_logic;
    signal addr_s : out std_logic_vector(31 downto 0);
    signal data_s : inout std_logic_vector(31 downto 0);
    signal as_s   : out std_logic;
    signal rw_s   : out std_logic;
    signal ds_s   : in std_logic_vector(1 downto 0);
    constant a    : in std_logic_vector(31 downto 0)
  ) is
  begin
    wait until rising_edge(clk_s);
    addr_s <= a;
    data_s <= (others => 'Z');
    rw_s <= '1';
    as_s <= '0';
    wait until rising_edge(clk_s) and ds_s = "00";
    as_s <= '1';
  end procedure;
begin
  clk <= not clk after 12.5 ns;

  dut : entity work.nextcube_soc
    generic map (
      RAM_ADDR_BITS => 8,
      ROM_ADDR_BITS => 8,
      VRAM_ADDR_BITS => 8
    )
    port map (
      clk_40m      => clk,
      rst          => rst,
      m68k_addr    => addr,
      m68k_data    => data,
      m68k_as_n    => as_n,
      m68k_rw      => rw,
      m68k_be_n    => be_n,
      m68k_dsack_n => dsack_n,
      m68k_ipl_n   => ipl_n,
      m68k_reset_n => reset_n,
      video_pixel  => pixel,
      video_hsync  => hsync,
      video_vsync  => vsync,
      video_blank  => blank,
      audio_pwm    => audio_pwm,
      kbd_tx       => kbd_tx,
      serial_tx    => serial_tx,
      kbd_rx       => '1',
      serial_rx    => '1',
      scsi_irq     => '0',
      eth_irq      => '0'
    );

  stim : process
  begin
    wait for 100 ns;
    rst <= '0';

    bus_write(clk, addr, data, as_n, rw, dsack_n, x"00000004", x"12345678");
    bus_read(clk, addr, data, as_n, rw, dsack_n, x"00000004");
    assert data = x"12345678" report "RAM readback failed" severity failure;

    bus_read(clk, addr, data, as_n, rw, dsack_n, x"0302000C");
    assert data = x"4E585456" report "Video ID read failed" severity failure;

    bus_write(clk, addr, data, as_n, rw, dsack_n, x"03030004", x"00008000");
    bus_write(clk, addr, data, as_n, rw, dsack_n, x"03040000", x"00000001");

    wait for 2 us;
    assert false report "nextcube_soc_tb completed" severity note;
    stop;
  end process;
end architecture;
