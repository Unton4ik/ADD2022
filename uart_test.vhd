library ieee;
use ieee.std_logic_1164.all;

use work.all;

entity uart_test is
  port (
    clk : in std_logic;

    led : out std_logic_vector(9 downto 0);

    rx_serial : in  std_logic;
    tx_serial : out std_logic
  );
end uart_test;

architecture rtl of uart_test is
    signal rx_byte : std_logic_vector(7 downto 0);
    signal tx_byte : std_logic_vector(7 downto 0);
begin
    UART: entity UART_CONTROLLER
      generic map (
        g_CLK_FREQ  => 50,
        g_BAUD_RATE => 9600
      )
      port map (
        i_Clock     => clk,
        i_RX_Serial => rx_serial,
        -- i_TX_Byte   => tx_byte,
        o_TX_Serial => tx_serial
        -- o_RX_Byte   => rx_byte
      );
end rtl;