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
    IncByte    : out word(DataW-1 downto 0);
    IncByteVal : out bit1
    );
end entity;

architecture fpga of SerialReader is
  constant PayloadW     : positive := DataW + 2;
  constant BitRateCnt   : positive := ClkFreq / Bitrate;
  signal Cnt_N, Cnt_D   : word(bits(bitRateCnt)-1 downto 0);
  --
  signal BitCnt_N, BitCnt_D : word(bits(DataW + ParityBits)-1 downto 0);
  
  signal Str_D, Str_N   : word(DataW-1 downto 0);

  type SerialState is (READING, WAITING_FOR_STOP, WAITING_FOR_START, WAITING_FOR_PARITY_BITS);
  signal State_N, State_D : SerialState;
  signal SetTimer         : bit1;
  signal QualifyData      : bit1;
begin
  BusyAssign : Busy <= '1' when Char_D < PayLoadW else '0';

  CntSync : process (Clk, Rst_N)
  begin
    if (Rst_N = '0') then
      Cnt_D   <= (others => '0');
      Str_D   <= (others => '0');
      Char_D  <= (others => '1');
      State_D <= WAITING_FOR_START;
    elsif rising_edge(Clk) then
      Cnt_D   <= Cnt_N;
      Str_D   <= Str_N;
      Char_D  <= Char_N;
      State_N <= State_D;
    end if;
  end process;

  AsyncProc : process (State_D, SerialIn, Str_D, BitCnt_D, Cnt_D)
  begin
    State_N  <= State_D;
    SetTimer <= '0';
    Str_N    <= Str_D;
    BitCnt_N <= BitCnt_D;
    QualifyData <= '0';
    
    case State_D is
      when WAITING_FOR_START =>
        if SerialIn = '1' then
          State_N <= READING;
          SetTimer <= '1';
        end if;

      when READING =>
        if Cnt_D = 0 then
          BitCnt_N <= BitCnt_D - 1;
          Str_N <= SerialIn & Str_D(Str_N'length-1 downto 1);
          SetTimer <= '1';

          if (BitCnt_D - 1) = 0 then
            State_N <= WAITING_FOR_STOP;
          end if;
        end if;
        
      when WAITING_FOR_STOP =>
        if Cnt_D = 0 then
          if SerialIn = '0' then
            QualifyData <= '1';
            SetTimer <= '1';
          end if;
          State_N <= WAITING_FOR_START;
        end if;
    end case;
  end process;

  SetTime : process (SetTimer, Cnt_D)
  begin
    Cnt_N <= Cnt_D - 1;
    if Cnt_D = 0 then
      Cnt_N <= (others => '0');
    end if;

    if SetTimer = '1' then
      Cnt_N <= conv_word(BitRateCnt, Cnt_N'length);
    end if;
  end process;

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

