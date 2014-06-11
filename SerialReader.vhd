-- Implements a rs232 decoder
-- Copyright Erik Zachrisson 2014, erik@zachrisson.info

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity SerialReader is
  generic (
    Bitrate    : positive := 9600;
    DataW      : positive := 8;
    ClkFreq    : positive := 50000000;
    ParityBits : natural  := 0
    );
  port (
    Clk        : in  bit1;
    Rst_N      : in  bit1;
    --
    SerialIn   : in  bit1;
    --
    Led : out word(2-1 downto 0);
    --
    IncByte    : out word(DataW-1 downto 0);
    IncByteVal : out bit1
    );
end entity;

architecture fpga of SerialReader is
  constant BitRateCnt       : positive := ClkFreq / Bitrate;
  signal Cnt_N, Cnt_D       : word(bits(BitRateCnt)-1 downto 0);
  signal SampleLine         : bit1;
  signal SetTimer, SetDelay : bit1;
  --
  signal CharCnt_N, CharCnt_D : word(DataW-1 downto 0);
  --
  signal Str_D, Str_N   : word(DataW-1 downto 0);
  --
  type SerialState is (READING, DELAY, WAITING_FOR_STOP, WAITING_FOR_START);
  signal State_N, State_D   : SerialState;
  signal QualifyData        : bit1;
begin

  CntSync : process (Clk, Rst_N)
  begin
    if (Rst_N = '0') then
      Cnt_D     <= (others => '0');
      Str_D     <= (others => '0');
      CharCnt_D <= (others => '0');
      State_D   <= WAITING_FOR_START;
    elsif rising_edge(Clk) then
      Cnt_D     <= Cnt_N;
      Str_D     <= Str_N;
      State_D   <= State_N;
      CharCnt_D <= CharCnt_N;
    end if;
  end process;

  AsyncProc : process (State_D, SerialIn, Str_D, CharCnt_D, SampleLine)
  begin
    State_N     <= State_D;
    SetTimer    <= '0';
    SetDelay    <= '0';
    Str_N       <= Str_D;
    CharCnt_N   <= CharCnt_D;
    QualifyData <= '0';

    case State_D is
      when WAITING_FOR_START =>
        Led <= "11";
        
        if SampleLine = '1' then
          if SerialIn = '0' and Str_D(0) = '1' then
            State_N   <= DELAY;
            CharCnt_N <= (others => '0');
            Str_N     <= (others => '0');
            -- Wait a bit to not sample the beginning of an edge
            SetDelay  <= '1';
          else
            Str_N(0) <= SerialIn;
            SetDelay <= '1';
          end if;
        end if;

      when DELAY =>
        Led <= "00";

        if SampleLine = '1' then
          SetTimer <= '1';
          State_N  <= READING;
        end if;

      when READING =>
        Led <= "10";
        if SampleLine = '1' then
          CharCnt_N <= CharCnt_D + 1;
          Str_N     <= SerialIn & Str_D(Str_N'length-1 downto 1);
          SetTimer  <= '1';

          if conv_integer(CharCnt_D) + 1 = DataW then
            State_N <= WAITING_FOR_STOP;
          end if;
        end if;

      when WAITING_FOR_STOP =>
        Led <= "01";
        if SampleLine = '1' then
          State_N     <= WAITING_FOR_START;
          QualifyData <= '1';
          SetTimer    <= '1';
        end if;

      when others =>
        State_N <= WAITING_FOR_START;
    end case;
  end process;

  SetTime : process (SetTimer, SetDelay, Cnt_D)
  begin
    Cnt_N <= Cnt_D - 1;
    if Cnt_D = 0 then
      Cnt_N <= (others => '0');
    end if;

    if SetDelay = '1' then
      Cnt_N <= conv_word(BitRateCnt/2, Cnt_N'length);
    end if;

    if SetTimer = '1' then
      Cnt_N <= conv_word(BitRateCnt-1, Cnt_N'length);
    end if;
  end process;

  SampleLine <= '1' when Cnt_D = 0 else '0';

  -- FIXME: Add support for parity
  QualifyDataProc : process (QualifyData, Str_D)
  begin
    IncByte    <= Str_D;
    IncByteVal <= '0';

    if QualifyData = '1' then
      IncByteVal <= '1';
    end if;
  end process;
end architecture;
