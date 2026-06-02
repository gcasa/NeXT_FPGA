library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.next_types_pkg.all;

entity next_video_asic is
  generic (
    H_VISIBLE : natural := 1120;
    H_FRONT   : natural := 16;
    H_SYNC    : natural := 96;
    H_BACK    : natural := 128;
    V_VISIBLE : natural := 832;
    V_FRONT   : natural := 1;
    V_SYNC    : natural := 3;
    V_BACK    : natural := 28
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    req       : in  bus_req_t;
    rsp       : out bus_rsp_t;
    pixel     : out std_logic;
    hsync     : out std_logic;
    vsync     : out std_logic;
    blank     : out std_logic;
    vblank_irq : out std_logic
  );
end entity;

architecture rtl of next_video_asic is
  constant H_TOTAL : natural := H_VISIBLE + H_FRONT + H_SYNC + H_BACK;
  constant V_TOTAL : natural := V_VISIBLE + V_FRONT + V_SYNC + V_BACK;

  signal rsp_r      : bus_rsp_t := BUS_RSP_IDLE;
  signal control    : std_logic_vector(31 downto 0) := x"00000001";
  signal fb_base    : std_logic_vector(31 downto 0) := x"02000000";
  signal h_ctr      : natural range 0 to H_TOTAL - 1 := 0;
  signal v_ctr      : natural range 0 to V_TOTAL - 1 := 0;
  signal visible    : std_logic;
  signal vblank_pulse : std_logic := '0';
begin
  rsp <= rsp_r;
  visible <= '1' when h_ctr < H_VISIBLE and v_ctr < V_VISIBLE else '0';
  blank <= not visible;
  hsync <= '0' when h_ctr >= H_VISIBLE + H_FRONT and h_ctr < H_VISIBLE + H_FRONT + H_SYNC else '1';
  vsync <= '0' when v_ctr >= V_VISIBLE + V_FRONT and v_ctr < V_VISIBLE + V_FRONT + V_SYNC else '1';
  vblank_irq <= vblank_pulse;

  -- Placeholder video: checkerboard proves timing until VRAM fetch is added.
  pixel <= control(0) and visible when ((h_ctr / 16) mod 2) /= ((v_ctr / 16) mod 2) else '0';

  process(clk)
    variable rd : std_logic_vector(31 downto 0);
  begin
    if rising_edge(clk) then
      rsp_r <= BUS_RSP_IDLE;
      vblank_pulse <= '0';

      if rst = '1' then
        control <= x"00000001";
        fb_base <= x"02000000";
        h_ctr <= 0;
        v_ctr <= 0;
      else
        if h_ctr = H_TOTAL - 1 then
          h_ctr <= 0;
          if v_ctr = V_TOTAL - 1 then
            v_ctr <= 0;
          else
            v_ctr <= v_ctr + 1;
            if v_ctr = V_VISIBLE - 1 then
              vblank_pulse <= '1';
            end if;
          end if;
        else
          h_ctr <= h_ctr + 1;
        end if;

        if req.valid = '1' then
          rd := (others => '0');
          case req.addr(5 downto 2) is
            when "0000" =>
              rd := control;
              if req.rw = '0' then control <= req.wdata; end if;
            when "0001" =>
              rd := fb_base;
              if req.rw = '0' then fb_base <= req.wdata; end if;
            when "0010" =>
              rd := std_logic_vector(to_unsigned(h_ctr, 16)) & std_logic_vector(to_unsigned(v_ctr, 16));
            when others =>
              rd := x"4E585456"; -- "NXTV"
          end case;
          rsp_r.ready <= '1';
          rsp_r.rdata <= rd;
        end if;
      end if;
    end if;
  end process;
end architecture;
