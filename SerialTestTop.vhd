library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

use work.Types.all;

entity SerialTestTop is 
	port (
		AsyncRstN : in bit1;
		Clk      : in bit1;
		--
		SerialOut : out bit1
	);
end entity;

architecture fpga of SerialTestTop is
	signal Rst_N : bit1;

begin
        RstSync : entity work.ResetSync
        port map (
                AsyncRst => AsyncRstN,
                Clk      => Clk,
                --
                Rst_N    => Rst_N
        );
	
	SerialTest : entity work.SerialTest
	port map (
		Clk => Clk,
		Rst_N => Rst_N,
		--
		SerialOut => SerialOut
	);
	
end architecture;
