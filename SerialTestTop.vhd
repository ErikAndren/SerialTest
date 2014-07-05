library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;
use work.SerialPack.all;

entity SerialTestTop is
  port (
    AsyncRstN : in  bit1;
    Clk       : in  bit1;
    Button0   : in  bit1;
    --
    Led0      : out bit1;
    Led1      : out bit1;
    Led2      : out bit1;
    --
    SerialOut : out bit1;
    SerialIn  : in  bit1
    );
end entity;

architecture fpga of SerialTestTop is
  signal HalfClk                            : bit1;
  signal Rst_N                              : bit1;
  signal We                                 : bit1;
  signal DataToParser, DataFromParser       : word(8-1 downto 0);
  signal DataToParserVal, DataFromParserVal : bit1;
  signal Btn0Pulse                          : bit1;
  --
  signal Cnt_N, Cnt_D                       : word(25-1 downto 0);
  signal WData_N, WData_D                   : word(8-1 downto 0);
  signal Baud                               : word(3-1 downto 0);
  signal RegAccess                          : RegAccessRec;
  signal Led                                : word(2-1 downto 0);
  signal Busy                               : bit1;
begin
  Led0 <= Led(0);
  Led1 <= Led(1);
  
  Sync : process (Clk, Rst_N)
  begin
    if Rst_N = '0' then
      Cnt_D   <= (others => '0');
      WData_D <= x"30";
    elsif rising_edge(Clk) then
      Cnt_D   <= Cnt_N;
      WData_D <= WData_N;
    end if;
  end process;

  ClkDiv : process (Rst_N, Clk)
  begin
    if Rst_N = '0' then
      HalfClk <= '0';
    elsif rising_edge(Clk) then
      HalfClk <= not HalfClk;
    end if;
  end process;
--  HalfClk <= Clk;

  Async : process (Cnt_D, WData_D)
  begin
    Cnt_N   <= Cnt_D + 1;
    We      <= '0';
    WData_N <= WData_D;

    if Cnt_D = 0 then
      We <= '1';
      WData_N <= WData_D + 1;
      if WData_D + 1 = x"40" then
        WData_N <= x"30";
      end if;
    end if;
    
    if conv_integer(Cnt_D + 1) = 25000000 then
      Cnt_N <= (others => '0');
    end if;
  end process;

  Led2 <= Cnt_D(Cnt_D'high);
  
  RstSync : entity work.ResetSync
    port map (
      AsyncRst => AsyncRstN,
      Clk      => HalfClk,
      --
      Rst_N    => Rst_N
      );

  ButtonPulse0 : entity work.ButtonPulse
    port map (
      Clk         => HalfClk,
      RstN        => Rst_N,
      --
      Button      => Button0,
      --
      ButtonPulse => Btn0Pulse
      );

  Baud <= "010";
  
  SerialWrite : entity work.SerialGen
    generic map (
      ClkFreq => 25000000
      )
    port map (
      Clk       => HalfClk,
      Rst_N     => Rst_N,
      --
      Baud      => Baud,
      --
      We        => DataFromParserVal,
      WData     => DataFromParser,
      --
      SerialOut => SerialOut,
      Busy      => Busy
      );

  SerialRead : entity work.SerialRx
    generic map (
      DataW   => 8,
      ClkFreq => 25000000
      )
    port map (
      Clk   => HalfClk,
      RstN  => Rst_N,
      --
      Rx    => SerialIn,
      --
      Baud  => Baud,
      --
      DOut  => DataToParser,
      RxRdy => DataToParserVal
      );

  CmdParser : entity work.SerialCmdParser
    port map (
      RstN           => Rst_N,
      Clk            => HalfClk,
      --
      IncSerChar     => DataToParser,
      IncSerCharVal  => DataToParserVal,
      --
      OutSerCharBusy => Busy,
      OutSerChar     => DataFromParser,
      OutSerCharVal  => DataFromParserVal,
      --
      RegAccessOut   => RegAccess,
      RegAccessIn    => RegAccess
      );
end architecture;
