-- Scrolls "HELLO WORLD" right to left, one symbol per step, on the 4-digit
-- multiplexed 7-segment display of the maXimator multi-function shield.
--
-- seg   : bit 0..6 = segments a..g, bit 7 = decimal point (all active high)
-- digit : one-hot digit enable, active high; digit(0) is the rightmost digit
library ieee;
use ieee.std_logic_1164.all;

entity scroller is
  generic (
    STEP_CLKS : positive := 5_000_000;  -- clocks per scroll step (0.5 s at 10 MHz)
    SCAN_CLKS : positive := 10_000      -- clocks per digit while multiplexing (1 ms)
  );
  port (
    clk   : in  std_logic;
    seg   : out std_logic_vector(7 downto 0);
    digit : out std_logic_vector(3 downto 0)
  );
end entity scroller;

architecture rtl of scroller is
  subtype glyph_t is std_logic_vector(6 downto 0);  -- gfedcba

  constant G_BLANK : glyph_t := "0000000";
  constant G_H     : glyph_t := "1110110";
  constant G_E     : glyph_t := "1111001";
  constant G_L     : glyph_t := "0111000";
  constant G_O     : glyph_t := "0111111";
  constant G_W     : glyph_t := "0111110";  -- shown as "U", W has no 7-segment form
  constant G_R     : glyph_t := "1010000";
  constant G_D     : glyph_t := "1011110";

  type msg_t is array (natural range <>) of glyph_t;
  -- Four leading blanks let the text enter from the right and leave to the left.
  constant MSG : msg_t := (
    G_BLANK, G_BLANK, G_BLANK, G_BLANK,
    G_H, G_E, G_L, G_L, G_O, G_BLANK,
    G_W, G_O, G_R, G_L, G_D
  );

  signal step_cnt : natural range 0 to STEP_CLKS - 1 := 0;
  signal scan_cnt : natural range 0 to SCAN_CLKS - 1 := 0;
  signal pos      : natural range MSG'range := 0;  -- message index shown on the left digit
  signal scan_idx : natural range 0 to 3 := 0;      -- 0 = rightmost digit
begin

  process (clk)
    variable idx : natural range 0 to MSG'length + 2;
  begin
    if rising_edge(clk) then
      if step_cnt = STEP_CLKS - 1 then
        step_cnt <= 0;
        if pos = MSG'high then
          pos <= 0;
        else
          pos <= pos + 1;
        end if;
      else
        step_cnt <= step_cnt + 1;
      end if;

      if scan_cnt = SCAN_CLKS - 1 then
        scan_cnt <= 0;
        scan_idx <= (scan_idx + 1) mod 4;
      else
        scan_cnt <= scan_cnt + 1;
      end if;

      -- Digit and segments change on the same edge to avoid ghosting.
      idx := (pos + 3 - scan_idx) mod MSG'length;
      seg   <= '0' & MSG(idx);
      digit <= (others => '0');
      digit(scan_idx) <= '1';
    end if;
  end process;

end architecture rtl;
