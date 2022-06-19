library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.all;
use work.typedefs.all;

use work.UART_RX;
use work.UART_TX;

entity UART_CONTROLLER is 
    generic (
        g_CLK_FREQ  : integer := 50000000; -- clock frequency in Hz
        g_BAUD_RATE : integer := 9600      -- uart baud rate
    );
    port (
        i_Clock : std_logic;

        i_Mixer_State  : in t_state_mixer;
        i_Feeder_State : in t_state_feeder;
        i_Stage1_State : in t_state_stage;
        i_Stage2_State : in t_state_stage;
        i_Stage3_State : in t_state_stage;
        i_Lift_State   : in t_state_lift;
        i_Screw_State  : in t_state_screw;

        i_RX_Serial : in std_logic;
        --i_TX_Byte   : in std_logic_vector(7 downto 0);

        o_TX_Serial : out std_logic
        --o_RX_Byte   : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of UART_CONTROLLER is
    signal rx_dv : std_logic;

    signal tx_dv     : std_logic;
    signal tx_active : std_logic;
    signal tx_done   : std_logic;

    signal tmr_dn      : std_logic;
    signal tx_byte     : std_logic_vector(7 downto 0);
    signal reg_rx_byte : std_logic_vector(7 downto 0);
    
    signal counter      : integer := 0;
    signal state_num    : integer := 0;
    signal machine_bits : std_logic_vector(2 downto 0);
    signal state_bits   : std_logic_vector(2 downto 0);
begin
    --------------------------
    -- Entity instantiation --
    --------------------------

    TX: entity UART_TX
    generic map (
        g_CLKS_PER_BIT => g_CLK_FREQ/g_BAUD_RATE
    )
    port map (
        i_Clk       => i_Clock,
        i_TX_DV     => tx_dv,
        i_TX_Byte   => tx_byte,
        o_TX_Active => tx_active,
        o_TX_Serial => o_TX_Serial,
        o_TX_Done   => tx_done
    );

    -- 10ms timer for arduino communication
    TMR: entity TIMER
    generic map (
        g_CLK_FREQ => g_CLK_FREQ
    )
    port map (
        i_Clock  => i_Clock,
        i_Enable => '1',
        i_Reset  => '0',
        i_Delay  => 10,
        o_Tick   => tmr_dn
    );

    -- State encoding --
    machine_bits <= std_logic_vector(to_unsigned(counter, machine_bits'length));
    state_num <= t_state_mixer'pos(i_Mixer_State)   when counter = 0 else
                 t_state_feeder'pos(i_Feeder_State) when counter = 1 else
                 t_state_stage'pos(i_Stage1_State)  when counter = 2 else
                 t_state_stage'pos(i_Stage2_State)  when counter = 3 else
                 t_state_stage'pos(i_Stage3_State)  when counter = 4 else
                 t_state_lift'pos(i_Lift_State)     when counter = 5;-- else
                --  t_state_screw'pos(i_Screw_State)   when counter = 6;
    state_bits <= std_logic_vector(to_unsigned(state_num, state_bits'length));

    reg_rx_byte <= "00" & machine_bits & state_bits;

    tx_dv <= tmr_dn;

    process is
    begin
        tx_byte <= reg_rx_byte;
        counter <= (counter + 1) mod 6;
        --reg_rx_byte <= std_logic_vector(to_unsigned(counter, reg_rx_byte'length));
        
        wait until rising_edge(tmr_dn);
    end process;

end rtl;