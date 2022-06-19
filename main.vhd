library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

use work.all;
use work.typedefs.all;
use work.util.all;

entity main is
    generic (
        g_SW        : integer := 10;       -- # of switches & leds
        g_CLK_FREQ  : integer := 50000000; -- clock frequency in Hz
        g_BAUD_RATE : integer := 9600      -- uart baud rate
    );
    port (
        clk : in  std_logic; -- clock
        
        pb0 : in  std_logic; -- push button 0
        pb1 : in  std_logic; -- push button 1
        sw  : in  std_logic_vector(g_SW-1 downto 0); -- switches
        led : out std_logic_vector(g_SW-1 downto 0); -- LEDs
        
        -- 7-segment displays
        -- hex0 : out std_logic_vector(7 downto 0);
        hex1 : out std_logic_vector(7 downto 0);
        hex2 : out std_logic_vector(7 downto 0);
        hex3 : out std_logic_vector(7 downto 0);
        hex4 : out std_logic_vector(7 downto 0);
        hex5 : out std_logic_vector(7 downto 0);
        
        rx_serial : in  std_logic; -- UART receive bit
        tx_serial : out std_logic; -- UART transmit bit

        I_MIXER_INTAKE_IR : in  std_logic;
        I_FEEDER_IR       : in  std_logic;
        I_STAGE1_LIMIT    : in  std_logic;
        I_STAGE2_CLR      : in  std_logic;
        I_STAGE2_IND      : in  std_logic;
        I_STAGE3_FSR      : in  std_logic;
        I_LIFT_UP_LIMIT   : in  std_logic;
        I_LIFT_DOWN_LIMIT : in  std_logic;
        O_SCREW_MOTOR     : out std_logic
    );
end;

architecture rtl of main is
    signal rx_byte   : std_logic_vector(7 downto 0);
    signal rx_dv     : std_logic;
    signal tx_byte   : std_logic_vector(7 downto 0);
    signal tx_dv     : std_logic;
    signal tx_active : std_logic;
    signal tx_done   : std_logic;

    -- State Machine signals
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
    signal STAGE1_SM_TEST_COND        : std_logic := '0';
    signal STAGE1_SM_FAIL_COND        : std_logic := '0';
    -- signal STAGE1_SM_RETURN_FAIL_COND : std_logic := '0';
    signal STAGE1_SM_PASS_COND        : std_logic := '0';
    signal STAGE1_SM_RETURN_COND : std_logic := '0';
    signal STAGE1_SM_IDLE_COND        : std_logic := '0';

    signal STAGE2_SM_STATE            : t_state_stage := STG_IDLE;
    signal STAGE2_SM_TEST_COND        : std_logic := '0';
    signal STAGE2_SM_FAIL_COND        : std_logic := '0';
    -- signal STAGE2_SM_RETURN_FAIL_COND : std_logic := '0';
    signal STAGE2_SM_PASS_COND        : std_logic := '0';
    signal STAGE2_SM_RETURN_COND : std_logic := '0';
    signal STAGE2_SM_IDLE_COND        : std_logic := '0';

    signal STAGE3_SM_STATE            : t_state_stage := STG_IDLE;
    signal STAGE3_SM_TEST_COND        : std_logic := '0';
    signal STAGE3_SM_FAIL_COND        : std_logic := '0';
    -- signal STAGE3_SM_RETURN_FAIL_COND : std_logic := '0';
    signal STAGE3_SM_PASS_COND        : std_logic := '0';
    signal STAGE3_SM_RETURN_COND : std_logic := '0';
    signal STAGE3_SM_IDLE_COND        : std_logic := '0';

    signal LIFT_SM_STATE        : t_state_lift := LFT_IDLE;
    signal LIFT_SM_GO_UP_COND   : std_logic := '0';
    signal LIFT_SM_WAIT_COND    : std_logic := '0';
    signal LIFT_SM_GO_DOWN_COND : std_logic := '0';
    signal LIFT_SM_IDLE_COND    : std_logic := '0';

    signal SCREW_SM_STATE     : t_state_screw := SCR_IDLE;
    signal SCREW_SM_SPIN_COND : std_logic := '0';
    signal SCREW_SM_IDLE_COND : std_logic := '0';


    -- digital inputs
    -- TODO pin allocation
    signal MIXER_INTAKE_IR      : std_logic := '0';
    signal MIXER_INTAKE_TMR_DN  : std_logic := '0';
    signal MIXER_CLOSE_TMR_DN   : std_logic := '0';
    signal MIXER_SPIN_TMR_DN    : std_logic := '0';
    signal MIXER_RELEASE_TMR_DN : std_logic := '0';
    signal MIXER_RESET_TMR_DN   : std_logic := '0';
    constant MIXER_INTAKE_TMR_DELAY  : integer := 1000;
    constant MIXER_CLOSE_TMR_DELAY   : integer := 30000;
    constant MIXER_SPIN_TMR_DELAY    : integer := 100;
    constant MIXER_RELEASE_TMR_DELAY : integer := 100;
    constant MIXER_RESET_TMR_DELAY   : integer := 100;
    
    signal FEEDER_IR          : std_logic := '0';
    signal FEEDER_FEED_TMR_DN : std_logic := '0';
    constant FEEDER_FEED_TMR_DELAY : integer := 4000;

    signal STAGE1_TEST_TMR_DN   : std_logic := '0';
    -- signal STAGE1_IR_LATCH_Q    : std_logic := '0';
    signal STAGE1_LIMIT         : std_logic := '0';
    signal STAGE1_LIMIT_LATCH_Q : std_logic := '0';
    signal STAGE1_FAIL_TMR_DN   : std_logic := '0';
    signal STAGE1_PASS_TMR_DN   : std_logic := '0';
    signal STAGE1_RETURN_TMR_DN : std_logic := '0';
    constant STAGE1_TEST_TMR_DELAY   : integer := 1500;
    constant STAGE1_FAIL_TMR_DELAY   : integer := 1000;
    constant STAGE1_PASS_TMR_DELAY   : integer := 1000;
    constant STAGE1_RETURN_TMR_DELAY : integer := 1000;

    signal STAGE2_TEST_TMR_DN   : std_logic := '0';
    signal STAGE2_CLR           : std_logic := '0';
    signal STAGE2_CLR_LATCH_Q   : std_logic := '0';
    signal STAGE2_IND           : std_logic := '0';
    signal STAGE2_IND_LATCH_Q   : std_logic := '0';
    signal STAGE2_FAIL_TMR_DN   : std_logic := '0';
    signal STAGE2_PASS_TMR_DN   : std_logic := '0';
    signal STAGE2_RETURN_TMR_DN : std_logic := '0';
    -- signal STAGE2_SOLENOID    : std_logic := '0'; -- OUTPUT
    constant STAGE2_TEST_TMR_DELAY   : integer := 1500;
    constant STAGE2_FAIL_TMR_DELAY   : integer := 1000;
    constant STAGE2_PASS_TMR_DELAY   : integer := 1000;
    constant STAGE2_RETURN_TMR_DELAY : integer := 1000;

    signal STAGE3_TEST_TMR_DN   : std_logic := '0';
    signal STAGE3_FSR           : std_logic := '0';
    signal STAGE3_FSR_LATCH_Q   : std_logic := '0';
    signal STAGE3_FAIL_TMR_DN   : std_logic := '0';
    signal STAGE3_PASS_TMR_DN   : std_logic := '0';
    signal STAGE3_RETURN_TMR_DN : std_logic := '0';
    constant STAGE3_TEST_TMR_DELAY   : integer := 1500;
    constant STAGE3_FAIL_TMR_DELAY   : integer := 1000;
    constant STAGE3_PASS_TMR_DELAY   : integer := 1000;
    constant STAGE3_RETURN_TMR_DELAY : integer := 1000;

    -- don't need to latch these limits
    -- signal LIFT_UP_LIMIT_Q   : std_logic := '0';
    -- signal LIFT_DOWN_LIMIT_Q : std_logic := '0';
    signal LIFT_UP_LIMIT       : std_logic := '0';
    signal LIFT_DOWN_LIMIT     : std_logic := '0';
    signal LIFT_GO_UP_TMR_DN   : std_logic := '0';
    signal LIFT_WAIT_TMR_DN    : std_logic := '0';
    signal LIFT_GO_DOWN_TMR_DN : std_logic := '0';
    constant LIFT_GO_UP_TMR_DELAY   : integer := 35000;
    constant LIFT_WAIT_TMR_DELAY    : integer := 1000;
    constant LIFT_GO_DOWN_TMR_DELAY : integer := 30000;

    signal SCREW_SPIN_TMR_DN : std_logic := '0';
    constant SCREW_SPIN_TMR_DELAY : integer := 10000;

    signal num0 : integer := 0;
    signal num1 : integer := 0;
    signal num2 : integer := 0;
    signal num3 : integer := 0;
    signal num4 : integer := 0;
    signal num5 : integer := 0;

    -- signal num  : integer := 0;
    -- signal dig0 : integer := 0;
    -- signal dig1 : integer := 0;
    -- signal dig2 : integer := 0;

    -- signal tmr_dn : std_logic;
    -- signal r_dig0, r_dig1, r_dig2 : integer := 0;
begin
    
    -- Instantiate objects
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
        i_Clock       => clk,
        i_Reset       => not pb0,
        i_Test_Cond   => STAGE1_SM_TEST_COND,
        i_Fail_Cond   => STAGE1_SM_FAIL_COND,
        i_Pass_Cond   => STAGE1_SM_PASS_COND,
        i_Return_Cond => STAGE1_SM_RETURN_COND,
        i_Idle_Cond   => STAGE1_SM_IDLE_COND,
        o_State       => STAGE1_SM_STATE
    );
    STAGE2_SM_INST: entity STAGE_STATE
    port map (
        i_Clock       => clk,
        i_Reset       => not pb0,
        i_Fail_Cond   => STAGE2_SM_FAIL_COND,
        i_Test_Cond   => STAGE2_SM_TEST_COND,
        i_Pass_Cond   => STAGE2_SM_PASS_COND,
        i_Return_Cond => STAGE2_SM_RETURN_COND,
        i_Idle_Cond   => STAGE2_SM_IDLE_COND,
        o_State       => STAGE2_SM_STATE
    );
    STAGE3_SM_INST: entity STAGE_STATE
    port map (
        i_Clock       => clk,
        i_Reset       => not pb0,
        i_Fail_Cond   => STAGE3_SM_FAIL_COND,
        i_Test_Cond   => STAGE3_SM_TEST_COND,
        i_Pass_Cond   => STAGE3_SM_PASS_COND,
        i_Return_Cond => STAGE3_SM_RETURN_COND,
        i_Idle_Cond   => STAGE3_SM_IDLE_COND,
        o_State       => STAGE3_SM_STATE
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

    SCREW_SM_INST: entity SCREW_STATE
    port map (
        i_Clock => clk,
        i_Reset => not pb0,
        i_Spin_Cond => SCREW_SM_SPIN_COND,
        i_Idle_Cond => SCREW_SM_IDLE_COND,
        o_State => SCREW_SM_STATE
    );

    UART: entity UART_CONTROLLER
    generic map (
        g_CLK_FREQ  => g_CLK_FREQ,
        g_BAUD_RATE => g_BAUD_RATE
    )
    port map (
        i_Clock        => clk,
        i_Mixer_State  => MIXER_SM_STATE,
        i_Feeder_State => FEEDER_SM_STATE,
        i_Stage1_State => STAGE1_SM_STATE,
        i_Stage2_State => STAGE2_SM_STATE,
        i_Stage3_State => STAGE3_SM_STATE,
        i_Lift_State   => LIFT_SM_STATE,
        i_Screw_State  => SCREW_SM_STATE,
        i_RX_Serial    => rx_serial,
        -- i_TX_Byte      => i_TX_Byte,
        o_TX_Serial    => tx_serial
        -- o_RX_Byte      => o_RX_Byte
    );

    
    
    
    -- Control Logic --
    MIXER_INTAKE_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => to_std_logic(MIXER_INTAKE_IR='1' and MIXER_SM_STATE=MXR_IDLE),
        i_Reset  => '0',
        i_Delay  => MIXER_INTAKE_TMR_DELAY,
        o_Tick   => MIXER_INTAKE_TMR_DN
    );
    MIXER_CLOSE_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => MIXER_SM_CLOSE_COND,
        i_Reset  => '0',
        i_Delay  => MIXER_CLOSE_TMR_DELAY,
        o_Tick   => MIXER_CLOSE_TMR_DN
    );
    MIXER_SPIN_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => MIXER_SM_SPIN_COND,
        i_Reset  => '0',
        i_Delay  => MIXER_SPIN_TMR_DELAY,
        o_Tick   => MIXER_SPIN_TMR_DN
    );
    MIXER_RELEASE_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => MIXER_SM_RELEASE_COND,
        i_Reset  => '0',
        i_Delay  => MIXER_RELEASE_TMR_DELAY,
        o_Tick   => MIXER_RELEASE_TMR_DN
    );
    MIXER_RESET_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => MIXER_SM_RESET_COND,
        i_Reset  => '0',
        i_Delay  => MIXER_RESET_TMR_DELAY,
        o_Tick   => MIXER_RESET_TMR_DN
    );

    MIXER_SM_CLOSE_COND   <= to_std_logic(MIXER_INTAKE_TMR_DN='1'  and MIXER_SM_STATE=MXR_IDLE);
    MIXER_SM_SPIN_COND    <= to_std_logic(MIXER_CLOSE_TMR_DN='1'   and MIXER_SM_STATE=MXR_CLOSE);
    MIXER_SM_RELEASE_COND <= to_std_logic(MIXER_SPIN_TMR_DN='1'    and MIXER_SM_STATE=MXR_SPIN);
    MIXER_SM_RESET_COND   <= to_std_logic(MIXER_RELEASE_TMR_DN='1' and MIXER_SM_STATE=MXR_RELEASE);
    MIXER_SM_IDLE_COND    <= to_std_logic(MIXER_RESET_TMR_DN='1'   and MIXER_SM_STATE=MXR_RESET);
    

    FEEDER_FEED_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => FEEDER_SM_FEED_COND,
        i_Reset  => '0',
        i_Delay  => FEEDER_FEED_TMR_DELAY,
        o_Tick   => FEEDER_FEED_TMR_DN
    );

    FEEDER_SM_FEED_COND <= to_std_logic(FEEDER_IR='1' and STAGE1_SM_STATE=STG_IDLE and FEEDER_SM_STATE=FDR_IDLE and MIXER_SM_STATE=MXR_CLOSE);
    FEEDER_SM_IDLE_COND <= to_std_logic(FEEDER_FEED_TMR_DN='1' and FEEDER_SM_STATE=FDR_FEED);


    STAGE1_TEST_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => STAGE1_SM_TEST_COND,
        i_Reset  => '0',
        i_Delay  => STAGE1_TEST_TMR_DELAY,
        o_Tick   => STAGE1_TEST_TMR_DN
    );
    STAGE1_FAIL_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => STAGE1_SM_FAIL_COND,
        i_Reset  => '0',
        i_Delay  => STAGE1_FAIL_TMR_DELAY,
        o_Tick   => STAGE1_FAIL_TMR_DN
    );
    STAGE1_PASS_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => STAGE1_SM_PASS_COND,
        i_Reset  => '0',
        i_Delay  => STAGE1_PASS_TMR_DELAY,
        o_Tick   => STAGE1_PASS_TMR_DN
    );
    STAGE1_RETURN_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => STAGE1_SM_RETURN_COND,
        i_Reset  => '0',
        i_Delay  => STAGE1_RETURN_TMR_DELAY,
        o_Tick   => STAGE1_RETURN_TMR_DN
    );
    -- STAGE1_IR_LATCH: entity INPUT_LATCH
    -- port map (
    --     i_Clock  => clk,
    --     i_Enable => to_std_logic(STAGE1_SM_STATE = STG_TEST),
    --     I        => FEEDER_IR,
    --     Q        => STAGE1_IR_LATCH_Q
    -- );
    STAGE1_LIMIT_LATCH: entity INPUT_LATCH
    port map (
        i_Clock  => clk,
        i_Enable => to_std_logic(STAGE1_SM_STATE = STG_TEST),
        I        => STAGE1_LIMIT,
        Q        => STAGE1_LIMIT_LATCH_Q
    );

    -- STAGE1_SM_RETURN_FAIL_COND <= STAGE1_FAIL_TMR_DN;
    STAGE1_SM_TEST_COND   <= to_std_logic(FEEDER_FEED_TMR_DN='1' and STAGE1_SM_STATE=STG_IDLE);
    STAGE1_SM_FAIL_COND   <= to_std_logic(STAGE1_TEST_TMR_DN='1' and STAGE1_LIMIT_LATCH_Q='1' and STAGE2_CLR_LATCH_Q='1' and STAGE1_SM_STATE=STG_TEST);
    STAGE1_SM_PASS_COND   <= to_std_logic(STAGE1_TEST_TMR_DN='1' and (STAGE1_LIMIT_LATCH_Q='0' or STAGE2_CLR_LATCH_Q='0')  and STAGE1_SM_STATE=STG_TEST);
    STAGE1_SM_RETURN_COND <= to_std_logic((STAGE1_FAIL_TMR_DN='1' and STAGE1_SM_STATE=STG_FAIL) or (STAGE1_PASS_TMR_DN='1' and STAGE1_SM_STATE=STG_PASS));
    STAGE1_SM_IDLE_COND   <= to_std_logic(STAGE1_RETURN_TMR_DN='1' and STAGE1_SM_STATE=STG_RETURN);


    STAGE2_TEST_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => STAGE2_SM_TEST_COND,
        i_Reset  => '0',
        i_Delay  => STAGE2_TEST_TMR_DELAY,
        o_Tick   => STAGE2_TEST_TMR_DN
    );
    STAGE2_FAIL_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => STAGE2_SM_FAIL_COND,
        i_Reset  => '0',
        i_Delay  => STAGE2_FAIL_TMR_DELAY,
        o_Tick   => STAGE2_FAIL_TMR_DN
    );
    STAGE2_PASS_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => STAGE2_SM_PASS_COND,
        i_Reset  => '0',
        i_Delay  => STAGE2_PASS_TMR_DELAY,
        o_Tick   => STAGE2_PASS_TMR_DN
    );
    STAGE2_RETURN_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => STAGE2_SM_RETURN_COND,
        i_Reset  => '0',
        i_Delay  => STAGE2_RETURN_TMR_DELAY,
        o_Tick   => STAGE2_RETURN_TMR_DN
    );
    STAGE2_CLR_LATCH: entity INPUT_LATCH
    port map (
        i_Clock  => clk,
        i_Enable => to_std_logic(STAGE2_SM_STATE = STG_TEST),
        I        => STAGE2_CLR,
        Q        => STAGE2_CLR_LATCH_Q
    );
    STAGE2_IND_LATCH: entity INPUT_LATCH
    port map (
        i_Clock  => clk,
        i_Enable => to_std_logic(STAGE2_SM_STATE = STG_TEST),
        I        => STAGE2_IND,
        Q        => STAGE2_IND_LATCH_Q
    );

    -- STAGE2_SM_RETURN_FAIL_COND <= STAGE2_FAIL_TMR_DN;
    STAGE2_SM_TEST_COND   <= to_std_logic(STAGE1_SM_PASS_COND='1' and STAGE2_SM_STATE=STG_IDLE);
    STAGE2_SM_FAIL_COND   <= to_std_logic(STAGE2_TEST_TMR_DN='1' and (STAGE2_CLR_LATCH_Q='0' or STAGE2_IND_LATCH_Q='0') and STAGE2_SM_STATE=STG_TEST);
    STAGE2_SM_PASS_COND   <= to_std_logic(STAGE2_TEST_TMR_DN='1' and STAGE2_CLR_LATCH_Q='1' and STAGE2_IND_LATCH_Q='1' and STAGE2_SM_STATE=STG_TEST);
    STAGE2_SM_RETURN_COND <= to_std_logic((STAGE2_FAIL_TMR_DN='1' and STAGE2_SM_STATE=STG_FAIL) or (STAGE2_PASS_TMR_DN='1' and STAGE2_SM_STATE=STG_PASS));
    STAGE2_SM_IDLE_COND   <= to_std_logic(STAGE2_RETURN_TMR_DN='1' and STAGE2_SM_STATE=STG_RETURN);

    
    STAGE3_TEST_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => STAGE3_SM_TEST_COND,
        i_Reset  => '0',
        i_Delay  => STAGE3_TEST_TMR_DELAY,
        o_Tick   => STAGE3_TEST_TMR_DN
    );
    STAGE3_FAIL_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => STAGE3_SM_FAIL_COND,
        i_Reset  => '0',
        i_Delay  => STAGE3_FAIL_TMR_DELAY,
        o_Tick   => STAGE3_FAIL_TMR_DN
    );
    STAGE3_PASS_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => STAGE3_SM_PASS_COND,
        i_Reset  => '0',
        i_Delay  => STAGE3_PASS_TMR_DELAY,
        o_Tick   => STAGE3_PASS_TMR_DN
    );
    STAGE3_RETURN_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => STAGE3_SM_RETURN_COND,
        i_Reset  => '0',
        i_Delay  => STAGE3_RETURN_TMR_DELAY,
        o_Tick   => STAGE3_RETURN_TMR_DN
    );
    STAGE3_FSR_LATCH: entity INPUT_LATCH
    port map (
        i_Clock  => clk,
        i_Enable => to_std_logic(STAGE3_SM_STATE = STG_TEST),
        I        => STAGE3_FSR,
        Q        => STAGE3_FSR_LATCH_Q
    );

    -- STAGE3_SM_RETURN_FAIL_COND <= STAGE3_FAIL_TMR_DN;
    STAGE3_SM_TEST_COND   <= to_std_logic( (STAGE1_TEST_TMR_DN='1' and (STAGE1_LIMIT_LATCH_Q='0' or STAGE2_CLR_LATCH_Q='0')  and STAGE1_SM_STATE=STG_TEST)  and STAGE3_SM_STATE=STG_IDLE);
    STAGE3_SM_FAIL_COND   <= to_std_logic(STAGE3_TEST_TMR_DN='1' and STAGE3_FSR_LATCH_Q='0' and STAGE3_SM_STATE=STG_TEST);
    STAGE3_SM_PASS_COND   <= to_std_logic(STAGE3_TEST_TMR_DN='1' and STAGE3_FSR_LATCH_Q='1' and STAGE3_SM_STATE=STG_TEST);
    STAGE3_SM_RETURN_COND <= to_std_logic((STAGE3_FAIL_TMR_DN='1' and STAGE3_SM_STATE=STG_FAIL) or (STAGE3_PASS_TMR_DN='1' and STAGE3_SM_STATE=STG_PASS));
    STAGE3_SM_IDLE_COND   <= to_std_logic(STAGE3_RETURN_TMR_DN='1' and STAGE3_SM_STATE=STG_RETURN);

    

    LIFT_GO_UP_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => LIFT_SM_GO_UP_COND,
        i_Reset  => '0',
        i_Delay  => LIFT_GO_UP_TMR_DELAY,
        o_Tick   => LIFT_GO_UP_TMR_DN
    );
    LIFT_WAIT_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => LIFT_SM_WAIT_COND,
        i_Reset  => '0',
        i_Delay  => LIFT_WAIT_TMR_DELAY,
        o_Tick   => LIFT_WAIT_TMR_DN
    );
    LIFT_GO_DOWN_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => LIFT_SM_GO_DOWN_COND,
        i_Reset  => '0',
        i_Delay  => LIFT_GO_DOWN_TMR_DELAY,
        o_Tick   => LIFT_GO_DOWN_TMR_DN
    );

    LIFT_SM_GO_UP_COND   <= to_std_logic(STAGE3_PASS_TMR_DN='1' and LIFT_SM_STATE=LFT_IDLE);
    LIFT_SM_WAIT_COND    <= to_std_logic(LIFT_GO_UP_TMR_DN='1' and LIFT_SM_STATE=LFT_GO_UP);
    LIFT_SM_GO_DOWN_COND <= to_std_logic(LIFT_WAIT_TMR_DN='1' and LIFT_SM_STATE=LFT_WAIT);
    LIFT_SM_IDLE_COND    <= to_std_logic(LIFT_GO_DOWN_TMR_DN='1' and LIFT_SM_STATE=LFT_GO_DOWN);
    
    
    SCREW_SPIN_TMR: entity TIMER
    generic map (g_CLK_FREQ)
    port map (
        i_Clock  => clk,
        i_Enable => SCREW_SM_SPIN_COND,
        i_Reset  => to_std_logic(SCREW_SM_SPIN_COND='1' and SCREW_SM_STATE=SCR_SPIN),
        i_Delay  => SCREW_SPIN_TMR_DELAY,
        o_Tick   => SCREW_SPIN_TMR_DN
    );

    SCREW_SM_SPIN_COND <= STAGE1_SM_FAIL_COND or STAGE3_SM_FAIL_COND;
    SCREW_SM_IDLE_COND <= SCREW_SPIN_TMR_DN;
    O_SCREW_MOTOR <= to_std_logic(SCREW_SM_STATE=SCR_SPIN);



    -- Display the current states --
    -- SS0 : entity SEVEN_SEG port map(num0, hex0);
    SS1 : entity SEVEN_SEG port map(num1, hex1);
    SS2 : entity SEVEN_SEG port map(num2, hex2);
    SS3 : entity SEVEN_SEG port map(num3, hex3);
    SS4 : entity SEVEN_SEG port map(num4, hex4);
    SS5 : entity SEVEN_SEG port map(num5, hex5);

    -- num5 <= t_state_mixer'pos(MIXER_SM_STATE);
    num5 <= t_state_feeder'pos(FEEDER_SM_STATE);
    num4 <= t_state_stage'pos(STAGE1_SM_STATE);
    num3 <= t_state_stage'pos(STAGE3_SM_STATE);
    -- num2 <= t_state_stage'pos(STAGE3_SM_STATE);
    num2 <= t_state_lift'pos(LIFT_SM_STATE);
    num1 <= t_state_screw'pos(SCREW_SM_STATE);

    MIXER_INTAKE_IR <= not I_MIXER_INTAKE_IR;
    FEEDER_IR       <= sw(0) or not I_FEEDER_IR;
    STAGE1_LIMIT    <= sw(1) or I_STAGE1_LIMIT;
    STAGE2_CLR      <= sw(2) or not I_STAGE2_CLR;
    STAGE2_IND      <= sw(3) or not I_STAGE2_IND;
    STAGE3_FSR      <= sw(4) or not I_STAGE3_FSR;
    -- LIFT_UP_LIMIT   <= not I_LIFT_UP_LIMIT;
    -- LIFT_DOWN_LIMIT <= not I_LIFT_DOWN_LIMIT;


    led(0) <= MIXER_INTAKE_IR;
    led(1) <= STAGE1_LIMIT_LATCH_Q;
    led(2) <= STAGE2_CLR_LATCH_Q;
    led(3) <= STAGE2_IND_LATCH_Q;
    led(4) <= STAGE3_FSR_LATCH_Q;
    
    -- RX : entity work.UART_RX
    -- generic map(g_CLK_FREQ/g_BAUD)
    -- port map (
    --     i_Clk       => clk,
    --     i_RX_Serial => rx_serial,
    --     o_RX_DV     => rx_dv,
    --     o_RX_Byte   => rx_byte
    -- );

    -- TX : entity work.UART_TX
    -- generic map(g_CLK_FREQ/g_BAUD)
    -- port map (
    --     i_Clk       => clk, 
    --     i_TX_DV     => tx_dv, 
    --     i_TX_Byte   => tx_byte, 
    --     o_TX_Active => tx_active, 
    --     o_TX_Serial => tx_serial, 
    --     o_TX_Done   => tx_done
    -- );
    

    -- TMR : entity TIMER
    --    generic map(50)
    --    port map(clk, '1', '0', 1000, tmr_dn);

    -- led(0) <= tx_done;

    -- num  <= to_integer(unsigned(rx_byte));
    -- dig0 <= num     mod 10;
    -- dig1 <= num/10  mod 10;
    -- dig2 <= num/100 mod 10;

    -- r_dig0 <= dig0 when rising_edge(tmr_dn);
    -- r_dig1 <= dig1 when rising_edge(tmr_dn);
    -- r_dig2 <= dig2 when rising_edge(tmr_dn);

    -- tx_dv <= tmr_dn; --not tx_active;
    -- tx_byte <= rx_byte;

    --   COM_RX : process is
    --   begin
    --      r_dig0 <= dig0;
    --      r_dig1 <= dig1;
    --      r_dig2 <= dig2;
    --      
    --      wait until rising_edge(rx_dv);
    --   end process;

end rtl;