library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

use work.Types.all;

entity SerialTestTop is 
	port (
		AsyncRst : in bit1;
		Clk      : in bit1;
		--
		SerialOut : out bit1
	);
end entity;

architecture fpga of SerialTestTop is
	signal Rst_N : bit1;

begin
	RstSync : work.ResetSync
	port map (
		AsyncRst => AsyncRst,
		Clk      => Clk,
		--
		Rst_N    => Rst_N
	);
	
	SerialTest : work.SerialTest
	port map (
		Clk => Clk,
		Rst_N => Rst_N,
		--
		SerialOut => SerialOut
	);
	
end architecture;