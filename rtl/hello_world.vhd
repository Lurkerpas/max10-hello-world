-- maXimator top level: LED chaser on the board, "HELLO WORLD" scroller on the shield.
library ieee;
use ieee.std_logic_1164.all;

entity hello_world is
  port (
    clk   : in  std_logic;                     -- 10 MHz oscillator
    led   : out std_logic_vector(3 downto 0);
    seg   : out std_logic_vector(7 downto 0);  -- a..g, dp
    digit : out std_logic_vector(3 downto 0)
  );
end entity hello_world;

architecture rtl of hello_world is
begin

  chaser : entity work.blink
    port map (clk => clk, led => led);

  text : entity work.scroller
    port map (clk => clk, seg => seg, digit => digit);

end architecture rtl;
