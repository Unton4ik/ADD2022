library ieee;
use ieee.std_logic_1164.all;

use work.all;
use work.typedefs.all;

entity STAGE_STATE is
    port (
        i_Clock : in std_logic;
        i_Reset : in std_logic := '0';

        i_Test_Cond   : in std_logic := '0';
        i_Fail_Cond   : in std_logic := '0';
        i_Pass_Cond   : in std_logic := '0';
        i_Return_Cond : in std_logic := '0';
        i_Idle_Cond   : in std_logic := '0';

        o_State : out t_state_stage
    );
end STAGE_STATE;

architecture rtl of STAGE_STATE is
    signal fstate     : t_state_stage;
    signal reg_fstate : t_state_stage;
begin
    process (i_Clock, reg_fstate)
    begin
        if (i_Clock = '1' and i_Clock'event) then 
            fstate <= reg_fstate;
        end if;
    end process;

    process (fstate, i_Reset, i_Test_Cond, i_Fail_Cond,
            i_Pass_Cond, i_Return_Cond, i_Idle_Cond)
    begin
        if (i_Reset = '1') then
            reg_fstate <= STG_IDLE;
            o_State <= STG_IDLE;
        else
            o_State <= STG_IDLE;
            case fstate is
                when STG_IDLE =>
                    if (i_Test_Cond = '1') then
                        reg_fstate <= STG_TEST;
                    else
                        reg_fstate <= STG_IDLE;
                    end if;
                    o_State <= STG_IDLE;

                when STG_TEST =>
                    if (i_Fail_Cond = '1') then
                        reg_fstate <= STG_FAIL;
                    elsif (i_Pass_Cond = '1') then
                        reg_fstate <= STG_PASS;
                    else
                        reg_fstate <= STG_TEST;
                    end if;
                    o_State <= STG_TEST;
                
                when STG_FAIL =>
                    if (i_Return_Cond = '1') then 
                        reg_fstate <= STG_RETURN;
                    else
                        reg_fstate <= STG_FAIL;
                    end if;
                    o_State <= STG_FAIL;
                
                when STG_PASS =>
                    if (i_Return_Cond = '1') then
                        reg_fstate <= STG_RETURN;
                    else
                        reg_fstate <= STG_PASS;
                    end if;
                    o_State <= STG_PASS;
                
                when STG_RETURN =>
                    if (i_Idle_Cond = '1') then 
                        reg_fstate <= STG_IDLE;
                    else
                        reg_fstate <= STG_RETURN;
                    end if;
                    o_State <= STG_RETURN;

                when others =>
                    report "Undefined state";
            end case;
        end if;
    end process;
end rtl;