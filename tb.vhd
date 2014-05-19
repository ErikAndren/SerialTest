library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

use work.Types.all;

entity tb is
end entity;

architecture rtl of tb is
  signal Clk   : bit1;
  signal Rst_N : bit1;
  signal SerialOut : bit1;
begin
  ClkProc : process
  begin
    while true loop
      Clk <= '0';
      wait for 20 ns;
      Clk <= '1';
      wait for 20 ns;
    end loop;
  end process;

  RstProc : Process
  begin
    Rst_N <= '0';
    wait for 300 ns;
    Rst_N <= '1';
    wait;
  end Process;

  DUT : entity work.SerialTestTop
    port map (
      AsyncRstN => Rst_N,
      Clk       => Clk,
      --
      -- Loop back
      SerialOut => SerialOut,
      SerialIn => SerialOut
      );
end architecture;
