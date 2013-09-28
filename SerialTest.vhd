library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

use work.Types.all;
use work.txt_util.all;

entity SerialTest is
	port (
		Clk       : in bit1;
		Rst_N     : in bit1;
		--
		SerialOut : out bit1
	);
end entity;

architecture fpga of SerialTest is
	signal Cnt_N, Cnt_D : word(9-1 downto 0);
	
	signal Char_D, Char_N : word(4-1 downto 0);
	signal Str_D, Str_N   : word(8*11-1 downto 0);
begin
	CntSync : process (Clk, Rst_N)
	begin
		if (Rst_N = '0') then
			Cnt_D <= (others => '0');
			Str_D <= SwapBytes(to_std_logic_vector("Hello World"));
			Char_D <= (others => '0');
		elsif rising_edge(Clk) then
			Cnt_D  <= Cnt_N;
			Str_D  <= Str_N;
			Char_D <= Char_N;
		end if;
	end process;
	
	CntAsync : process (Cnt_D, Char_D, Str_D)
	begin
		Cnt_N <= Cnt_D + 1;
	
		if (Char_D = 0) then
			-- Send start bit
			SerialOut <= '1';
		elsif (Char_D = 9) then
			-- Send stop bit
			SerialOut <= '1';
		else
			-- Invert bit
			SerialOut <= not Str_D(0);
		end if;
			
		if (Cnt_D = 433) then
			Cnt_N <= (others => '0');
			if (Char_D < 9) then
				Char_N <= Char_D + 1;
			else
				-- Rotate value right one step
				Str_N  <= Str_D(0) & Str_D(Str_D'high downto 1);
				Char_N <= (others => '0');
			end if;
		end if;
	end process;
end architecture;

