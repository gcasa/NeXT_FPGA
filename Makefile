VHDL_STD ?= --std=08
GHDL ?= ghdl

RTL = \
	rtl/next_types_pkg.vhd \
	rtl/next_memory_map_pkg.vhd \
	rtl/next_bus_arbiter.vhd \
	rtl/next_bus_decode.vhd \
	rtl/next_simple_ram.vhd \
	rtl/next_system_asic.vhd \
	rtl/next_dma_asic.vhd \
	rtl/next_video_asic.vhd \
	rtl/next_sound_asic.vhd \
	rtl/next_io_asic.vhd \
	rtl/nextcube_soc.vhd

.PHONY: analyze test clean

analyze:
	$(GHDL) -a $(VHDL_STD) $(RTL)

test: analyze
	$(GHDL) -a $(VHDL_STD) tb/nextcube_soc_tb.vhd
	$(GHDL) -e $(VHDL_STD) nextcube_soc_tb
	$(GHDL) -r $(VHDL_STD) nextcube_soc_tb --assert-level=error

clean:
	$(GHDL) --clean
