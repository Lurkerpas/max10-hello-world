# maXimator on-board 10 MHz oscillator
create_clock -name clk -period 100.000 [get_ports clk]
derive_clock_uncertainty

# LEDs and display are not timing critical
set_false_path -to [get_ports {led[*] seg[*] digit[*]}]
