library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity SerialTestTop is
  port (
    AsyncRstN : in  bit1;
    Clk       : in  bit1;
    Button0   : in  bit1;
    --
    SerialOut : out bit1;
    SerialIn  : in  bit1
    );
end entity;

architecture fpga of SerialTestTop is
  signal Rst_N     : bit1;
  signal We        : bit1;
  signal WData     : word(8-1 downto 0);
  signal RData     : word(8-1 downto 0);
  signal RDataVal  : bit1;
  signal Btn0Pulse : bit1;

  signal Cnt_N, Cnt_D : word(25-1 downto 0);
  
begin
  Sync : process (Clk, Rst_N)
  begin
    if Rst_N = '0' then
      Cnt_D <= (others => '0');
    elsif rising_edge(Clk) then
      Cnt_D <= Cnt_N;
    end if;
  end process;

  Async : process (Cnt_D)
  begin
    Cnt_N <= Cnt_D + 1;
    We <= '0';

    if Cnt_D = 0 then
      We <= '1';
    end if;
    
    if conv_integer(Cnt_D + 1) = 25000000 then
      Cnt_N <= (others => '0');      
    end if;
  end process;
  
  RstSync : entity work.ResetSync
    port map (
      AsyncRst => AsyncRstN,
      Clk      => Clk,
      --
      Rst_N    => Rst_N
      );

  ButtonPulse0 : entity work.ButtonPulse
    port map (
      Clk         => Clk,
      RstN        => Rst_N,
      --
      Button      => Button0,
      --
      ButtonPulse => Btn0Pulse
      );

--  WData  <= conv_word(72, ByteW);

  SerialWrite : entity work.SerialGen
    port map (
      Clk       => Clk,
      Rst_N     => Rst_N,
      --
      We        => RDataVal,
      WData     => RData,
      --
      SerialOut => SerialOut
      );

  SerialRead : entity work.SerialReader
    port map (
      Clk        => Clk,
      Rst_N      => Rst_N,
      --
      SerialIn   => SerialIn,
      --
      IncByte    => RData,
      IncByteVal => RDataVal
      );

end architecture;
