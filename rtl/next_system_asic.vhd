library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.next_types_pkg.all;

entity next_system_asic is
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    req      : in  bus_req_t;
    rsp      : out bus_rsp_t;
    irq_in   : in  irq_lines_t;
    irq_out  : out std_logic_vector(2 downto 0);
    reset_n  : out std_logic
  );
end entity;

architecture rtl of next_system_asic is
  signal rsp_r       : bus_rsp_t := BUS_RSP_IDLE;
  signal irq_enable  : std_logic_vector(6 downto 0) := (others => '0');
  signal irq_pending : std_logic_vector(6 downto 0) := (others => '0');
  signal control     : std_logic_vector(31 downto 0) := (others => '0');
begin
  rsp <= rsp_r;
  reset_n <= not rst and control(0);

  irq_pending <= irq_in.video_vblank & irq_in.sound & irq_in.scsi & irq_in.ethernet &
                 irq_in.serial & irq_in.rtc & irq_in.dma;

  process(irq_pending, irq_enable)
    variable active : std_logic;
  begin
    active := '0';
    for i in irq_pending'range loop
      active := active or (irq_pending(i) and irq_enable(i));
    end loop;

    if active = '1' then
      irq_out <= "110";
    else
      irq_out <= "000";
    end if;
  end process;

  process(clk)
    variable rd : std_logic_vector(31 downto 0);
  begin
    if rising_edge(clk) then
      rsp_r <= BUS_RSP_IDLE;

      if rst = '1' then
        control <= (others => '0');
        irq_enable <= (others => '0');
      elsif req.valid = '1' then
        rd := (others => '0');
        case req.addr(7 downto 2) is
          when "000000" =>
            rd := control;
            if req.rw = '0' then
              control <= req.wdata;
            end if;
          when "000001" =>
            rd(6 downto 0) := irq_enable;
            if req.rw = '0' then
              irq_enable <= req.wdata(6 downto 0);
            end if;
          when "000010" =>
            rd(6 downto 0) := irq_pending;
          when others =>
            rd := x"4E585453"; -- "NXTS"
        end case;

        rsp_r.ready <= '1';
        rsp_r.rdata <= rd;
      end if;
    end if;
  end process;
end architecture;
