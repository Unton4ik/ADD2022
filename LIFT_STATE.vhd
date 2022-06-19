library ieee;
use ieee.std_logic_1164.all;

use work.all;
use work.typedefs.all;

entity LIFT_STATE is
    port (
        i_Clock : in std_logic;
        i_Reset : in std_logic := '0';

        i_Go_Up_Cond   : in std_logic := '0';
        i_Wait_Cond    : in std_logic := '0';
        i_Go_Down_Cond : in std_logic := '0';
        i_Idle_Cond    : in std_logic := '0';

        o_State : out t_state_lift
    );
end LIFT_STATE;

architecture rtl of LIFT_STATE is
    signal fstate     : t_state_lift;
    signal reg_fstate : t_state_lift;
begin
    process (i_Clock, reg_fstate)
    begin
        if (i_Clock = '1' and i_Clock'event) then 
            fstate <= reg_fstate;
        end if;
    end process;

    process (fstate, i_Reset, i_Go_Up_Cond, i_Go_Down_Cond, i_Idle_Cond)
    begin
        if (i_Reset = '1') then
            reg_fstate <= LFT_IDLE;
            o_State <= LFT_IDLE;
        else
            o_State <= LFT_IDLE;
            case fstate is
                when LFT_IDLE =>
                    if (i_Go_Up_Cond = '1') then
                        reg_fstate <= LFT_GO_UP;
                    else
                        reg_fstate <= LFT_IDLE;
                    end if;
                    o_State <= LFT_IDLE;

                when LFT_GO_UP =>
                    if (i_Wait_Cond = '1') then
                        reg_fstate <= LFT_WAIT;
                    else
                        reg_fstate <= LFT_GO_UP;
                    end if;
                    o_State <= LFT_GO_UP;

                when LFT_WAIT =>
                    if (i_Go_Down_Cond = '1') then
                        reg_fstate <= LFT_GO_DOWN;
                    else
                        reg_fstate <= LFT_WAIT;
                    end if;
                    o_State <= LFT_WAIT;
                
                when LFT_GO_DOWN =>
                    if (i_Idle_Cond = '1') then
                        reg_fstate <= LFT_IDLE;
                    else
                        reg_fstate <= LFT_GO_DOWN;
                    end if;
                    o_State <= LFT_GO_DOWN;

                when others =>
                    report "Undefined state";
            end case;
        end if;
    end process;
end rtl;