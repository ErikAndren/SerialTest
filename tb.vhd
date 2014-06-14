library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

use work.Types.all;

entity tb is
end entity;

architecture rtl of tb is
  signal Clk         : bit1;
  signal Rst_N       : bit1;
  signal SerialOut   : bit1;
  signal Button0     : bit1;
  signal Baud        : word(3-1 downto 0);
  signal TestData    : word(8-1 downto 0);
  signal TestDataVal : bit1;
  signal SerialIn    : bit1;
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

  ButtonPush : process
  begin
    Button0 <= '0';
    while true loop
      wait for 100 ms;
      Button0 <= not Button0;
    end loop;
  end process;

  DUT : entity work.SerialTestTop
    port map (
      AsyncRstN => Rst_N,
      Clk       => Clk,
      --
      Button0 => Button0,
      --
      -- Loop back
      SerialOut => open,
      SerialIn => SerialIn
      );

  Baud <= "010";

  TestData <= x"30";
  TestDataVal <= '1';
  
  TbSerialGen : entity work.SerialGen
    port map (
      Clk       => Clk,
      Rst_N     => Rst_N,
      --
      Baud      => Baud,
      --
      We        => TestDataVal,
      WData     => TestData,
      --
      SerialOut => SerialIn
      );
  
end architecture;
