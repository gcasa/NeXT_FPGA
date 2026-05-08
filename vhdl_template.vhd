library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Generic NeXT_FPGA module template
entity module_template is
  generic (
    G_WIDTH : positive := 8
  );
  port (
    clk_i   : in  std_logic;
    rst_ni  : in  std_logic;
    en_i    : in  std_logic;
    data_i  : in  std_logic_vector(G_WIDTH - 1 downto 0);
    data_o  : out std_logic_vector(G_WIDTH - 1 downto 0)
  );
end entity module_template;

architecture rtl of module_template is
  signal data_q : std_logic_vector(G_WIDTH - 1 downto 0) := (others => '0');
begin
  p_regs : process (clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_ni = '0' then
        data_q <= (others => '0');
      elsif en_i = '1' then
        data_q <= data_i;
      end if;
    end if;
  end process p_regs;

  data_o <= data_q;
end architecture rtl;
