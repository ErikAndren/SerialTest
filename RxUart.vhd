library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity SerialRx is
  generic (
    DataW : positive
  );
  port (
    Clk   : in  bit1;
    RstN  : in  bit1;
    --
    Rx    : in  bit1;
    --
    Baud  : in  word(3-1 downto 0);
    --
    Dout  : out word(DataW-1 downto 0);
    RxRdy : out bit1
    );
end entity;

architecture rtl of SerialRx is
  signal Divisor : integer;
  signal Top16   : bit1;
  signal Div16   : integer;
  signal TopRx   : bit1;
  signal RxDiv   : integer;
  signal ClrDiv  : bit1;
  --
  signal Rx_Reg : word(DataW-1 downto 0);
  signal RxBitCnt : integer;
  type RxFsmType is (Start_Rx, Idle, Edge_Rx, Shift_Rx, Stop_Rx, RxOVF);
  signal RxFsm : RxFsmType;
  signal RxRdyi : bit1;

begin
  BaudRateSel : process (RstN, Clk)
  begin
    if RstN = '0' then
      Divisor <= 0;
    elsif rising_edge(Clk) then
      case Baud is
        when "000" =>
          Divisor <= 25;
        when "001" =>
          Divisor <= 53;
        when "010" =>
          Divisor <= 81;
        when "011" =>
          Divisor <= 165;
        when "100" =>
          Divisor <= 340;
        when "101" =>
          Divisor <= 670;
        when "110" =>
          Divisor <= 1342;
        when "111" =>
          Divisor <= 2688;
      end case;
    end if;
  end process;

  Clk16Gen : process (RstN, Clk)
  begin
    if RstN = '0' then
      Top16 <= '0';
      Div16 <= 0;
    elsif rising_edge(Clk) then
      Top16 <= '0';
      if Div16 = Divisor then
        Div16 <= 0;
        Top16 <= '1';
      else
        Div16 <= Div16 + 1;
      end if;
    end if;
  end process;

  RxSampGen : process (RstN, Clk)
  begin
    if RstN = '0' then
      TopRx <= '0';
      RxDiv <= 0;
    elsif rising_edge(Clk) then
      TopRx <= '0';
      if ClrDiv = '1' then
        RxDiv <= 0;
      elsif Top16 = '1' then
        if RxDiv = 7 then
          RxDiv <= 0;
          TopRx <= '1';
        else
          RxDiv <= RxDiv + 1;
        end if;
      end if;
    end if;
  end process;

  Rx_FSM : process (RstN, Clk)
  begin
    if RstN = '0' then
      Rx_Reg   <= (others => '0');
      RxBitCnt <= 0;
      RxFsm    <= Idle;
      RxRdyi   <= '0';
      ClrDiv   <= '0';
    elsif rising_edge(Clk) then
      ClrDiv <= '0';
      RxRdyi <= '0';

      case RxFSM is
        when Idle =>
          RxBitCnt <= 0;
          if Top16 = '1' then
            if Rx = '0' then
              RxFSM  <= Start_Rx;
              ClrDiv <= '1';
            end if;
          end if;

        when Start_Rx =>
          if TopRx = '1' then
            if Rx = '1' then
              RxFSM <= RxOVF;
            else
              RxFSM <= Edge_Rx;
            end if;
          end if;
          
        when Edge_Rx =>
          if TopRx = '1' then
            RxFSM <= Shift_Rx;
            if RxBitCnt = DataW then
              RxFSM <= Stop_Rx;
            else
              RxFSM <= Shift_Rx;
            end if;
          end if;
          
        when Shift_Rx =>
          if TopRx = '1' then
            RxBitCnt <= RxBitCnt + 1;
            Rx_Reg <= Rx & Rx_Reg(Rx_Reg'high downto 1);
            RxFSM <= Edge_Rx;
          end if;

        when Stop_Rx =>
          if TopRx = '1' then
            RxRdyi <= '1';
            RxFSM <= Idle;
          end if;

        when RxOVF =>
          if Rx = '1' then
            RxFSM <= Idle;
          end if;
        end case;
    end if;
  end process;
  Dout  <= Rx_Reg;
  RxRdy <= RxRdyi;

end architecture;
