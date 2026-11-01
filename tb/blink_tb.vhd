-- Self-checking testbench: with a scaled-down clock, verifies that exactly one
-- LED is lit, each LED stays lit for exactly CLK_HZ cycles (one "second"), and
-- the order is LED0 -> LED1 -> LED2 -> LED3 -> LED0 ...
library ieee;
use ieee.std_logic_1164.all;

entity blink_tb is
end entity blink_tb;

architecture sim of blink_tb is
  constant CLK_HZ : positive := 8;
  constant PERIOD : time     := 100 ns;
  constant ROUNDS : positive := 3;

  signal clk : std_logic := '0';
  signal led : std_logic_vector(3 downto 0);

  function one_hot(i : natural) return std_logic_vector is
    variable v : std_logic_vector(3 downto 0) := (others => '0');
  begin
    v(i mod 4) := '1';
    return v;
  end function;
begin

  dut : entity work.blink
    generic map (CLK_HZ => CLK_HZ)
    port map (clk => clk, led => led);

  clk <= not clk after PERIOD / 2;

  check : process
  begin
    wait for 1 ns;
    assert led = one_hot(0)
      report "LED0 must be the only LED lit after power-up" severity failure;

    for p in 0 to 4 * ROUNDS - 1 loop
      for c in 1 to CLK_HZ loop
        wait until rising_edge(clk);
        wait for 1 ns;
        if c < CLK_HZ then
          assert led = one_hot(p)
            report "LED pattern changed early in step " & integer'image(p)
            severity failure;
        else
          assert led = one_hot(p + 1)
            report "Wrong LED after step " & integer'image(p)
            severity failure;
        end if;
      end loop;
    end loop;

    report "PASS: LEDs lit one at a time, in order, " &
           integer'image(CLK_HZ) & " cycles each" severity note;
    std.env.finish;
  end process;

end architecture sim;
