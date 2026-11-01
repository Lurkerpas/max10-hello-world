-- Lights the maXimator user LEDs one at a time, in order, each for one second.
library ieee;
use ieee.std_logic_1164.all;

entity blink is
  generic (
    CLK_HZ : positive := 10_000_000  -- on-board oscillator frequency
  );
  port (
    clk : in  std_logic;
    led : out std_logic_vector(3 downto 0)  -- active high
  );
end entity blink;

architecture rtl of blink is
  -- Power-up values are honoured by MAX 10 registers, so no reset is needed.
  signal count : natural range 0 to CLK_HZ - 1 := 0;
  signal led_r : std_logic_vector(3 downto 0)  := "0001";
begin

  process (clk)
  begin
    if rising_edge(clk) then
      if count = CLK_HZ - 1 then
        count <= 0;
        led_r <= led_r(2 downto 0) & led_r(3);
      else
        count <= count + 1;
      end if;
    end if;
  end process;

  led <= led_r;

end architecture rtl;
