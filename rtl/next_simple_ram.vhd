library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.next_types_pkg.all;

entity next_simple_ram is
  generic (
    ADDR_BITS : positive := 12;
    READ_ONLY : boolean := false;
    INIT_WORD : std_logic_vector(31 downto 0) := x"00000000"
  );
  port (
    clk : in std_logic;
    rst : in std_logic;
    req : in bus_req_t;
    rsp : out bus_rsp_t
  );
end entity;

architecture rtl of next_simple_ram is
  type ram_t is array (0 to (2 ** ADDR_BITS) - 1) of std_logic_vector(31 downto 0);
  signal ram : ram_t := (others => INIT_WORD);
  signal rsp_r : bus_rsp_t := BUS_RSP_IDLE;
begin
  rsp <= rsp_r;

  process(clk)
    variable index : natural;
    variable word  : std_logic_vector(31 downto 0);
  begin
    if rising_edge(clk) then
      rsp_r <= BUS_RSP_IDLE;

      if rst = '1' then
        rsp_r <= BUS_RSP_IDLE;
      elsif req.valid = '1' then
        index := to_integer(unsigned(req.addr(ADDR_BITS + 1 downto 2)));
        word := ram(index);

        if req.rw = '0' and not READ_ONLY then
          for i in 0 to 3 loop
            if req.be(i) = '1' then
              word((i * 8) + 7 downto i * 8) := req.wdata((i * 8) + 7 downto i * 8);
            end if;
          end loop;
          ram(index) <= word;
        end if;

        rsp_r.ready <= '1';
        rsp_r.rdata <= word;
        rsp_r.err   <= '0';
      end if;
    end if;
  end process;
end architecture;
