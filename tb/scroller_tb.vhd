-- Self-checking testbench for the scroller, using a scaled-down timebase.
-- Reconstructs the 4 displayed symbols from the multiplexed outputs and checks
-- that "HELLO WORLD" moves one symbol to the left per step, wraps around, and
-- that exactly one digit is enabled at a time with the decimal point off.
library ieee;
use ieee.std_logic_1164.all;

entity scroller_tb is
end entity scroller_tb;

architecture sim of scroller_tb is
  constant STEP_CLKS : positive := 64;
  constant SCAN_CLKS : positive := 4;
  constant PERIOD    : time     := 100 ns;
  constant TEXT      : string   := "    HELLO WORLD";
  constant N         : positive := TEXT'length;

  signal clk   : std_logic := '0';
  signal seg   : std_logic_vector(7 downto 0);
  signal digit : std_logic_vector(3 downto 0);

  -- Expected segment pattern (gfedcba) per character, written out per segment.
  function glyph(c : character) return std_logic_vector is
  begin
    case c is
      when 'H'    => return "1110110";  -- b c e f g
      when 'E'    => return "1111001";  -- a d e f g
      when 'L'    => return "0111000";  -- d e f
      when 'O'    => return "0111111";  -- a b c d e f
      when 'W'    => return "0111110";  -- b c d e f (drawn as "U")
      when 'R'    => return "1010000";  -- e g
      when 'D'    => return "1011110";  -- b c d e g
      when others => return "0000000";
    end case;
  end function;
begin

  dut : entity work.scroller
    generic map (STEP_CLKS => STEP_CLKS, SCAN_CLKS => SCAN_CLKS)
    port map (clk => clk, seg => seg, digit => digit);

  clk <= not clk after PERIOD / 2;

  check : process
    type seen_t is array (0 to 3) of std_logic_vector(6 downto 0);
    variable seen : seen_t := (others => (others => 'U'));
    variable d    : integer;
    variable ones : natural;
  begin
    for s in 0 to 2 * N - 1 loop
      for c in 1 to STEP_CLKS loop
        wait until rising_edge(clk);
        wait for 1 ns;

        ones := 0;
        for i in 0 to 3 loop
          if digit(i) = '1' then
            ones := ones + 1;
            d := i;
          end if;
        end loop;
        assert ones = 1
          report "Exactly one digit must be enabled" severity failure;
        assert seg(7) = '0'
          report "Decimal point must stay off" severity failure;
        seen(d) := seg(6 downto 0);

        -- Late in the step every digit has been refreshed with this step's text.
        if c = STEP_CLKS - 1 then
          for i in 0 to 3 loop
            assert seen(i) = glyph(TEXT(((s + 3 - i) mod N) + 1))
              report "Step " & integer'image(s) & ": wrong symbol on digit " &
                     integer'image(i) severity failure;
          end loop;
        end if;
      end loop;
    end loop;

    report "PASS: HELLO WORLD scrolls right to left and wraps around"
      severity note;
    std.env.finish;
  end process;

end architecture sim;
