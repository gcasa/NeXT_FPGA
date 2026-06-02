library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.next_types_pkg.all;

entity next_m68040_core is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    reset_n   : in  std_logic;
    ipl_n     : in  std_logic_vector(2 downto 0);
    bus_req   : out bus_req_t;
    bus_rsp   : in  bus_rsp_t;
    boot_done : out std_logic;
    pc        : out std_logic_vector(31 downto 0)
  );
end entity;

architecture rtl of next_m68040_core is
  type state_t is (
    ST_RESET,
    ST_FETCH_SSP,
    ST_FETCH_PC,
    ST_IDLE
  );

  signal state       : state_t := ST_RESET;
  signal req_r       : bus_req_t := BUS_REQ_IDLE;
  signal pc_r        : std_logic_vector(31 downto 0) := (others => '0');
  signal boot_done_r : std_logic := '0';
begin
  bus_req <= req_r;
  boot_done <= boot_done_r;
  pc <= pc_r;

  process(clk)
  begin
    if rising_edge(clk) then
      req_r <= BUS_REQ_IDLE;

      if rst = '1' or reset_n = '0' then
        state <= ST_RESET;
        pc_r <= (others => '0');
        boot_done_r <= '0';
      else
        case state is
          when ST_RESET =>
            req_r.valid <= '1';
            req_r.rw    <= '1';
            req_r.addr  <= x"00000000";
            req_r.be    <= "1111";
            state <= ST_FETCH_SSP;

          when ST_FETCH_SSP =>
            req_r.valid <= '1';
            req_r.rw    <= '1';
            req_r.addr  <= x"00000000";
            req_r.be    <= "1111";
            if bus_rsp.ready = '1' then
              req_r.addr <= x"00000004";
              state <= ST_FETCH_PC;
            end if;

          when ST_FETCH_PC =>
            req_r.valid <= '1';
            req_r.rw    <= '1';
            req_r.addr  <= x"00000004";
            req_r.be    <= "1111";
            if bus_rsp.ready = '1' then
              pc_r <= bus_rsp.rdata;
              boot_done_r <= '1';
              state <= ST_IDLE;
            end if;

          when ST_IDLE =>
            if ipl_n /= "111" then
              boot_done_r <= boot_done_r;
            end if;
        end case;
      end if;
    end if;
  end process;
end architecture;
