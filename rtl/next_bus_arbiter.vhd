library ieee;
use ieee.std_logic_1164.all;

use work.next_types_pkg.all;

entity next_bus_arbiter is
  port (
    cpu_req  : in  bus_req_t;
    cpu_rsp  : out bus_rsp_t;
    dma_req  : in  dma_req_t;
    dma_rsp  : out dma_rsp_t;
    mem_req  : out bus_req_t;
    mem_rsp  : in  bus_rsp_t
  );
end entity;

architecture rtl of next_bus_arbiter is
begin
  process(all)
  begin
    mem_req <= cpu_req;
    cpu_rsp <= mem_rsp;
    dma_rsp <= DMA_RSP_IDLE;

    if dma_req.valid = '1' then
      mem_req.valid <= dma_req.valid;
      mem_req.rw    <= dma_req.rw;
      mem_req.addr  <= dma_req.addr;
      mem_req.wdata <= dma_req.wdata;
      mem_req.be    <= dma_req.be;
      cpu_rsp <= BUS_RSP_IDLE;
      dma_rsp.ready <= mem_rsp.ready;
      dma_rsp.rdata <= mem_rsp.rdata;
      dma_rsp.err   <= mem_rsp.err;
    end if;
  end process;
end architecture;
