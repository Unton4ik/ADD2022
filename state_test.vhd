library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.all;
use work.typedefs.all;

entity state_test is
    port (
        clk : in std_logic;

        pb0  : in std_logic;
        pb1  : in std_logic;
        sw   : in std_logic_vector(9 downto 0);

        led  : out std_logic_vector(9 downto 0);
        hex0 : out std_logic_vector(7 downto 0);
        hex1 : out std_logic_vector(7 downto 0);
        hex2 : out std_logic_vector(7 downto 0);
        hex3 : out std_logic_vector(7 downto 0);
        hex4 : out std_logic_vector(7 downto 0);
        hex5 : out std_logic_vector(7 downto 0);
        hex6 : out std_logic_vector(7 downto 0);

        rx_serial : in  std_logic;
        tx_serial : out std_logic
    );
end state_test;

architecture rtl of state_test is
    signal MAST_SM_STATE     : t_state_master;
    signal MAST_SM_MIX_COND  : std_logic;
    signal MAST_SM_SORT_COND : std_logic;
    signal MAST_SM_LIFT_COND : std_logic;
    signal MAST_SM_IDLE_COND : std_logic;

    signal MIXER_SM_STATE        : t_state_mixer := MXR_IDLE;
    signal MIXER_SM_CLOSE_COND   : std_logic := '0';
    signal MIXER_SM_SPIN_COND    : std_logic := '0';
    signal MIXER_SM_RELEASE_COND : std_logic := '0';
    signal MIXER_SM_RESET_COND   : std_logic := '0';
    signal MIXER_SM_IDLE_COND    : std_logic := '0';

    signal FEEDER_SM_STATE      : t_state_feeder := FDR_IDLE;
    signal FEEDER_SM_FEED_COND  : std_logic := '0';
    signal FEEDER_SM_WAIT_COND  : std_logic := '0';
    signal FEEDER_SM_RESET_COND : std_logic := '0';
    signal FEEDER_SM_IDLE_COND  : std_logic := '0';

    signal STAGE1_SM_STATE            : t_state_stage := STG_IDLE;
    signal STAGE1_SM_DUMP_COND        : std_logic := '0';
    signal STAGE1_SM_RETURN_DUMP_COND : std_logic := '0';
    signal STAGE1_SM_PASS_COND        : std_logic := '0';
    signal STAGE1_SM_RETURN_PASS_COND : std_logic := '0';
    signal STAGE1_SM_IDLE_COND        : std_logic := '0';

    signal STAGE2_SM_STATE            : t_state_stage := STG_IDLE;
    signal STAGE2_SM_DUMP_COND        : std_logic := '0';
    signal STAGE2_SM_RETURN_DUMP_COND : std_logic := '0';
    signal STAGE2_SM_PASS_COND        : std_logic := '0';
    signal STAGE2_SM_RETURN_PASS_COND : std_logic := '0';
    signal STAGE2_SM_IDLE_COND        : std_logic := '0';

    signal STAGE3_SM_STATE            : t_state_stage := STG_IDLE;
    signal STAGE3_SM_DUMP_COND        : std_logic := '0';
    signal STAGE3_SM_RETURN_DUMP_COND : std_logic := '0';
    signal STAGE3_SM_PASS_COND        : std_logic := '0';
    signal STAGE3_SM_RETURN_PASS_COND : std_logic := '0';
    signal STAGE3_SM_IDLE_COND        : std_logic := '0';

    signal LIFT_SM_STATE        : t_state_lift := LFT_IDLE;
    signal LIFT_SM_GO_UP_COND   : std_logic := '0';
    signal LIFT_SM_WAIT_COND    : std_logic := '0';
    signal LIFT_SM_GO_DOWN_COND : std_logic := '0';
    signal LIFT_SM_IDLE_COND    : std_logic := '0';

    signal num0 : integer := 0;
    signal num1 : integer := 0;
    signal num2 : integer := 0;
    signal num3 : integer := 0;
    signal num4 : integer := 0;
    signal num5 : integer := 0;
    signal num6 : integer := 0;

    signal test_clk : std_logic;
begin
    MASTER_SM_INST: entity MASTER_STATE
    port map (
        i_Clock     => clk,
        i_Reset     => not pb0,
        i_Mix_Cond  => MAST_SM_MIX_COND,
        i_Sort_Cond => MAST_SM_SORT_COND,
        i_Lift_Cond => MAST_SM_LIFT_COND,
        i_Idle_Cond => MAST_SM_IDLE_COND,
        o_State     => MAST_SM_STATE
    );
    MIXER_SM_INST: entity MIXER_STATE
    port map (
        i_Clock        => clk,
        i_Reset        => not pb0,
        i_Close_Cond   => MIXER_SM_CLOSE_COND,
        i_Spin_Cond    => MIXER_SM_SPIN_COND,
        i_Release_Cond => MIXER_SM_RELEASE_COND,
        i_Reset_Cond   => MIXER_SM_RESET_COND,
        i_Idle_Cond    => MIXER_SM_IDLE_COND,
        o_State        => MIXER_SM_STATE
    );
    FEEDER_SM_INST: entity FEEDER_STATE
    port map (
        i_Clock      => clk,
        i_Reset      => not pb0,
        i_Feed_Cond  => FEEDER_SM_FEED_COND,
        i_Wait_Cond  => FEEDER_SM_WAIT_COND,
        i_Reset_Cond => FEEDER_SM_RESET_COND,
        i_Idle_Cond  => FEEDER_SM_IDLE_COND,
        o_State      => FEEDER_SM_STATE
    );
    STAGE1_SM_INST: entity STAGE_STATE
    port map (
        i_Clock            => clk,
        i_Reset            => not pb0,
        i_Fail_Cond        => STAGE1_SM_DUMP_COND,
        i_Return_Dump_Cond => STAGE1_SM_RETURN_DUMP_COND,
        i_Pass_Cond        => STAGE1_SM_PASS_COND,
        i_Return_Pass_Cond => STAGE1_SM_RETURN_PASS_COND,
        i_Idle_Cond        => STAGE1_SM_IDLE_COND,
        o_State            => STAGE1_SM_STATE
    );
    STAGE2_SM_INST: entity STAGE_STATE
    port map (
        i_Clock            => clk,
        i_Reset            => not pb0,
        i_Fail_Cond        => STAGE2_SM_DUMP_COND,
        i_Return_Dump_Cond => STAGE2_SM_RETURN_DUMP_COND,
        i_Pass_Cond        => STAGE2_SM_PASS_COND,
        i_Return_Pass_Cond => STAGE2_SM_RETURN_PASS_COND,
        i_Idle_Cond        => STAGE2_SM_IDLE_COND,
        o_State            => STAGE2_SM_STATE
    );
    STAGE3_SM_INST: entity STAGE_STATE
    port map (
        i_Clock            => clk,
        i_Reset            => not pb0,
        i_Fail_Cond        => STAGE3_SM_DUMP_COND,
        i_Return_Dump_Cond => STAGE3_SM_RETURN_DUMP_COND,
        i_Pass_Cond        => STAGE3_SM_PASS_COND,
        i_Return_Pass_Cond => STAGE3_SM_RETURN_PASS_COND,
        i_Idle_Cond        => STAGE3_SM_IDLE_COND,
        o_State            => STAGE3_SM_STATE
    );
    LIFT_SM_INST: entity LIFT_STATE
    port map (
        i_Clock        => clk,
        i_Reset        => not pb0,
        i_Go_Up_Cond   => LIFT_SM_GO_UP_COND,
        i_Wait_Cond    => LIFT_SM_WAIT_COND,
        i_Go_Down_Cond => LIFT_SM_GO_DOWN_COND,
        i_Idle_Cond    => LIFT_SM_IDLE_COND,
        o_State        => LIFT_SM_STATE
    );

    UART: entity work.UART_CONTROLLER
      generic map (
        g_CLK_FREQ  => 50,
        g_BAUD_RATE => 9600
      )
      port map (
        i_Clock        => clk,
        i_Mixer_State  => MIXER_SM_STATE,
        i_Feeder_State => FEEDER_SM_STATE,
        i_Stage1_State => STAGE1_SM_STATE,
        i_Stage2_State => STAGE2_SM_STATE,
        i_Stage3_State => STAGE3_SM_STATE,
        i_Lift_State   => LIFT_SM_STATE,
        i_Screw_State  => SCR_IDLE,
        i_RX_Serial    => rx_serial,
        -- i_TX_Byte      => i_TX_Byte,
        o_TX_Serial    => tx_serial
        -- o_RX_Byte      => o_RX_Byte
      );

    TMR: entity TIMER
    generic map (
        g_CLK_FREQ => 50
    )
    port map (
        i_Clock  => clk,
        i_Enable => '1',
        i_Reset  => '0',
        i_Delay  => 500,
        o_Tick   => test_clk
    );

    SS0 : entity SEVEN_SEG port map(num1, hex0);
    SS1 : entity SEVEN_SEG port map(num2, hex1);
    SS2 : entity SEVEN_SEG port map(num3, hex2);
    SS3 : entity SEVEN_SEG port map(num4, hex3);
    SS4 : entity SEVEN_SEG port map(num5, hex4);
    SS5 : entity SEVEN_SEG port map(num6, hex5);

    num0 <= t_state_master'pos(MAST_SM_STATE);
    num1 <= t_state_mixer'pos(MIXER_SM_STATE);
    num2 <= t_state_feeder'pos(FEEDER_SM_STATE);
    num3 <= t_state_stage'pos(STAGE1_SM_STATE);
    num4 <= t_state_stage'pos(STAGE2_SM_STATE);
    num5 <= t_state_stage'pos(STAGE3_SM_STATE);
    num6 <= t_state_lift'pos(LIFT_SM_STATE);

    

end rtl;