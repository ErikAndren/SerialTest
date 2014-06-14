library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;
use work.SerialPack.all;

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
  signal Busy        : bit1;

  signal DataPtr_N, DataPtr_D : word(4-1 downto 0); 
  
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


  WriteProcSync : process (Clk, Rst_N)
  begin
    if Rst_N = '0' then
      DataPtr_D <= (others => '0');
    elsif rising_edge(Clk) then
      DataPtr_D <= DataPtr_N;
    end if;
  end process;

  WriteProcAsync : process (DataPtr_D, Busy)
  begin
   DataPtr_N <= DataPtr_D;
   TestDataVal <= '1';

   case DataPtr_D is
     when "0000" =>
       TestData <= W;

     when "0001" =>
       TestData <= Space;

     when "0010" =>
       TestData <= x"30";

     when "0011" =>
       TestData <= x"31";

     when "0100" =>
       TestData <= x"32";
       
     when "0101" =>
       TestData <= x"33";

     when "0110" =>
       TestData <= Space;       

     when "0111" =>
       TestData <= x"34";

     when "1000" =>
       TestData <= x"35";

     when "1001" =>
       TestData <= x"36";

     when "1010" =>
       TestData <= x"37";
       
     when "1011" =>
       TestData <= NewLine;
       
     when others =>
       TestData    <= x"FF";
       TestDataVal <= '0';
   end case;
   
   if Busy <= '0' and DataPtr_D /= x"FF" then
     DataPtr_N <= DataPtr_D + 1;
   end if;
  end process;
  
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
      SerialOut => SerialIn,
      Busy      => Busy
      );  
end architecture;
