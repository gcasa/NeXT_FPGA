library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

use work.next_types_pkg.all;

entity next_m68040_core_tb is
end entity;

architecture sim of next_m68040_core_tb is
  signal clk       : std_logic := '0';
  signal rst       : std_logic := '1';
  signal reset_n   : std_logic := '0';
  signal bus_req   : bus_req_t := BUS_REQ_IDLE;
  signal bus_rsp   : bus_rsp_t := BUS_RSP_IDLE;
  signal boot_done : std_logic;
  signal pc        : std_logic_vector(31 downto 0);
begin
  clk <= not clk after 12.5 ns;

  dut : entity work.next_m68040_core
    port map (
      clk       => clk,
      rst       => rst,
      reset_n   => reset_n,
      ipl_n     => "111",
      bus_req   => bus_req,
      bus_rsp   => bus_rsp,
      boot_done => boot_done,
      pc        => pc
    );

  bus_model : process(all)
  begin
    bus_rsp <= BUS_RSP_IDLE;

    if bus_req.valid = '1' then
      bus_rsp.ready <= '1';
      case bus_req.addr is
        when x"00000000" =>
          bus_rsp.rdata <= x"00002000";
        when x"00000004" =>
          bus_rsp.rdata <= x"00001000";
        when others =>
          bus_rsp.err <= '1';
      end case;
    end if;
  end process;

  stim : process
  begin
    wait for 100 ns;
    rst <= '0';
    reset_n <= '1';

    wait until rising_edge(clk) and bus_req.valid = '1';
    assert bus_req.rw = '1' report "68040 reset fetch should be a read" severity failure;
    assert bus_req.addr = x"00000000" report "68040 did not fetch initial SSP" severity failure;

    wait until rising_edge(clk) and bus_req.valid = '1' and bus_req.addr = x"00000004";
    wait until rising_edge(clk) and boot_done = '1';
    assert pc = x"00001000" report "68040 did not latch initial PC" severity failure;

    assert false report "next_m68040_core_tb completed" severity note;
    stop;
  end process;
end architecture;
