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
begin
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

  We    <= Btn0Pulse;
  WData  <= conv_word(72, ByteW);

  SerialWrite : entity work.SerialGen
    port map (
      Clk       => Clk,
      Rst_N     => Rst_N,
      --
      We        => We,
      WData     => Wdata,
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
