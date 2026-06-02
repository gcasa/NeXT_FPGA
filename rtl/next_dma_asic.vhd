library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.next_types_pkg.all;

entity next_dma_asic is
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    req      : in  bus_req_t;
    rsp      : out bus_rsp_t;
    dma_req  : out dma_req_t;
    dma_rsp  : in  dma_rsp_t;
    irq      : out std_logic
  );
end entity;

architecture rtl of next_dma_asic is
  signal rsp_r   : bus_rsp_t := BUS_RSP_IDLE;
  signal control : std_logic_vector(31 downto 0) := (others => '0');
  signal src     : std_logic_vector(31 downto 0) := (others => '0');
  signal dst     : std_logic_vector(31 downto 0) := (others => '0');
  signal count   : unsigned(31 downto 0) := (others => '0');
  signal active  : std_logic := '0';
  signal phase   : std_logic := '0';
  signal data_buf : std_logic_vector(31 downto 0) := (others => '0');
  signal dreq_r  : dma_req_t := DMA_REQ_IDLE;
  signal irq_r   : std_logic := '0';
begin
  rsp <= rsp_r;
  dma_req <= dreq_r;
  irq <= irq_r;

  process(clk)
    variable rd : std_logic_vector(31 downto 0);
  begin
    if rising_edge(clk) then
      rsp_r <= BUS_RSP_IDLE;
      dreq_r <= DMA_REQ_IDLE;
      irq_r <= '0';

      if rst = '1' then
        control <= (others => '0');
        src <= (others => '0');
        dst <= (others => '0');
        count <= (others => '0');
        active <= '0';
        phase <= '0';
      else
        if req.valid = '1' then
          rd := (others => '0');
          case req.addr(5 downto 2) is
            when "0000" =>
              rd := control;
              if req.rw = '0' then
                control <= req.wdata;
                active <= req.wdata(0);
                phase <= '0';
              end if;
            when "0001" =>
              rd := src;
              if req.rw = '0' then src <= req.wdata; end if;
            when "0010" =>
              rd := dst;
              if req.rw = '0' then dst <= req.wdata; end if;
            when "0011" =>
              rd := std_logic_vector(count);
              if req.rw = '0' then count <= unsigned(req.wdata); end if;
            when others =>
              rd := x"4E585444"; -- "NXTD"
          end case;
          rsp_r.ready <= '1';
          rsp_r.rdata <= rd;
        end if;

        if active = '1' and count /= 0 then
          if phase = '0' then
            dreq_r.valid <= '1';
            dreq_r.rw    <= '1';
            dreq_r.addr  <= src;
            dreq_r.be    <= "1111";
            if dma_rsp.ready = '1' then
              data_buf <= dma_rsp.rdata;
              src <= std_logic_vector(unsigned(src) + 4);
              phase <= '1';
            end if;
          else
            dreq_r.valid <= '1';
            dreq_r.rw    <= '0';
            dreq_r.addr  <= dst;
            dreq_r.wdata <= data_buf;
            dreq_r.be    <= "1111";
            if dma_rsp.ready = '1' then
              dst <= std_logic_vector(unsigned(dst) + 4);
              count <= count - 1;
              phase <= '0';
              if count = 1 then
                active <= '0';
                control(0) <= '0';
                irq_r <= control(1);
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;
end architecture;
