library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.next_types_pkg.all;

entity next_sound_asic is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    req       : in  bus_req_t;
    rsp       : out bus_rsp_t;
    audio_pwm : out std_logic;
    irq       : out std_logic
  );
end entity;

architecture rtl of next_sound_asic is
  signal rsp_r      : bus_rsp_t := BUS_RSP_IDLE;
  signal control    : std_logic_vector(31 downto 0) := (others => '0');
  signal sample     : unsigned(15 downto 0) := (others => '0');
  signal pwm_accum  : unsigned(16 downto 0) := (others => '0');
  signal irq_r      : std_logic := '0';
begin
  rsp <= rsp_r;
  audio_pwm <= pwm_accum(16);
  irq <= irq_r;

  process(clk)
    variable rd : std_logic_vector(31 downto 0);
  begin
    if rising_edge(clk) then
      rsp_r <= BUS_RSP_IDLE;
      irq_r <= '0';

      if rst = '1' then
        control <= (others => '0');
        sample <= (others => '0');
        pwm_accum <= (others => '0');
      else
        pwm_accum <= ('0' & pwm_accum(15 downto 0)) + ('0' & sample);

        if req.valid = '1' then
          rd := (others => '0');
          case req.addr(5 downto 2) is
            when "0000" =>
              rd := control;
              if req.rw = '0' then control <= req.wdata; end if;
            when "0001" =>
              rd(15 downto 0) := std_logic_vector(sample);
              if req.rw = '0' then
                sample <= unsigned(req.wdata(15 downto 0));
                irq_r <= control(1);
              end if;
            when others =>
              rd := x"4E585441"; -- "NXTA"
          end case;
          rsp_r.ready <= '1';
          rsp_r.rdata <= rd;
        end if;
      end if;
    end if;
  end process;
end architecture;
