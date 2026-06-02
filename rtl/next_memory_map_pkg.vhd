library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package next_memory_map_pkg is
  -- Pragmatic starter map. Real NeXT address decoding should be refined from
  -- schematics/ROM disassembly as each peripheral is made cycle accurate.
  constant ADDR_RAM_BASE      : unsigned(31 downto 0) := x"00000000";
  constant ADDR_RAM_MASK      : unsigned(31 downto 0) := x"0F000000";

  constant ADDR_ROM_BASE      : unsigned(31 downto 0) := x"01000000";
  constant ADDR_ROM_MASK      : unsigned(31 downto 0) := x"0F000000";

  constant ADDR_VRAM_BASE     : unsigned(31 downto 0) := x"02000000";
  constant ADDR_VRAM_MASK     : unsigned(31 downto 0) := x"0F000000";

  constant ADDR_SYSTEM_BASE   : unsigned(31 downto 0) := x"03000000";
  constant ADDR_SYSTEM_MASK   : unsigned(31 downto 0) := x"0FFF0000";

  constant ADDR_DMA_BASE      : unsigned(31 downto 0) := x"03010000";
  constant ADDR_DMA_MASK      : unsigned(31 downto 0) := x"0FFF0000";

  constant ADDR_VIDEO_BASE    : unsigned(31 downto 0) := x"03020000";
  constant ADDR_VIDEO_MASK    : unsigned(31 downto 0) := x"0FFF0000";

  constant ADDR_SOUND_BASE    : unsigned(31 downto 0) := x"03030000";
  constant ADDR_SOUND_MASK    : unsigned(31 downto 0) := x"0FFF0000";

  constant ADDR_IO_BASE       : unsigned(31 downto 0) := x"03040000";
  constant ADDR_IO_MASK       : unsigned(31 downto 0) := x"0FFF0000";

  function in_range(
    addr : std_logic_vector(31 downto 0);
    base : unsigned(31 downto 0);
    mask : unsigned(31 downto 0)
  ) return boolean;
end package;

package body next_memory_map_pkg is
  function in_range(
    addr : std_logic_vector(31 downto 0);
    base : unsigned(31 downto 0);
    mask : unsigned(31 downto 0)
  ) return boolean is
  begin
    return (unsigned(addr) and mask) = base;
  end function;
end package body;
