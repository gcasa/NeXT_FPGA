library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.next_types_pkg.all;

entity next_io_asic is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    req       : in  bus_req_t;
    rsp       : out bus_rsp_t;
    kbd_rx    : in  std_logic;
    kbd_tx    : out std_logic;
    serial_rx : in  std_logic;
    serial_tx : out std_logic;
    scsi_irq  : in  std_logic;
    eth_irq   : in  std_logic;
    rtc_irq   : out std_logic;
    io_irq    : out std_logic
  );
end entity;

architecture rtl of next_io_asic is
  signal rsp_r      : bus_rsp_t := BUS_RSP_IDLE;
  signal led_reg    : std_logic_vector(31 downto 0) := (others => '0');
  signal serial_reg : std_logic_vector(31 downto 0) := (others => '0');
  signal rtc_ctr    : unsigned(23 downto 0) := (others => '0');
  signal rtc_irq_r  : std_logic := '0';
begin
  rsp <= rsp_r;
  serial_tx <= serial_reg(0);
  kbd_tx <= led_reg(0);
  rtc_irq <= rtc_irq_r;
  io_irq <= scsi_irq or eth_irq or rtc_irq_r or not kbd_rx or not serial_rx;

  process(clk)
    variable rd : std_logic_vector(31 downto 0);
  begin
    if rising_edge(clk) then
      rsp_r <= BUS_RSP_IDLE;
      rtc_irq_r <= '0';

      if rst = '1' then
        led_reg <= (others => '0');
        serial_reg <= (others => '0');
        rtc_ctr <= (others => '0');
      else
        rtc_ctr <= rtc_ctr + 1;
        if rtc_ctr = 0 then
          rtc_irq_r <= '1';
        end if;

        if req.valid = '1' then
          rd := (others => '0');
          case req.addr(5 downto 2) is
            when "0000" =>
              rd := led_reg;
              if req.rw = '0' then led_reg <= req.wdata; end if;
            when "0001" =>
              rd := serial_reg;
              rd(8) := serial_rx;
              if req.rw = '0' then serial_reg <= req.wdata; end if;
            when "0010" =>
              rd(0) := kbd_rx;
              rd(1) := scsi_irq;
              rd(2) := eth_irq;
            when "0011" =>
              rd(23 downto 0) := std_logic_vector(rtc_ctr);
            when others =>
              rd := x"4E585449"; -- "NXTI"
          end case;
          rsp_r.ready <= '1';
          rsp_r.rdata <= rd;
        end if;
      end if;
    end if;
  end process;
end architecture;
