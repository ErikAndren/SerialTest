library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

use work.Types.all;

entity SerialTestTop is
  port (
    AsyncRstN : in  bit1;
    Clk       : in  bit1;
    Button0   : in  bit1;
    --
    SerialOut : out bit1
    );
end entity;

architecture fpga of SerialTestTop is
  signal Rst_N : bit1;
  signal We    : bit1;
  signal WData : word(8-1 downto 0);
  
begin
  RstSync : entity work.ResetSync
    port map (
      AsyncRst => AsyncRstN,
      Clk      => Clk,
      --
      Rst_N    => Rst_N
      );

  We    <= '1' when Button0 = '0' else '0';
  WData <= conv_word(72, ByteW);

  SerialTest : entity work.SerialGen
    port map (
      Clk       => Clk,
      Rst_N     => Rst_N,
      --
      We        => We,
      WData     => Wdata,
      --
      SerialOut => SerialOut
      );
end architecture;
