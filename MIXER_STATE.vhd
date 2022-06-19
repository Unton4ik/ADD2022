library ieee;
use ieee.std_logic_1164.all;

use work.all;
use work.typedefs.all;

entity MIXER_STATE is
    port (
        i_Clock : in std_logic;
        i_Reset : in std_logic := '0';

        i_Close_Cond   : in std_logic := '0';
        i_Spin_Cond    : in std_logic := '0';
        i_Release_Cond : in std_logic := '0';
        i_Reset_Cond   : in std_logic := '0';
        i_Idle_Cond    : in std_logic := '0';

        o_State : out t_state_mixer
    );
end MIXER_STATE;

architecture rtl of MIXER_STATE is
    signal fstate     : t_state_mixer;
    signal reg_fstate : t_state_mixer;
begin
    process (i_Clock, reg_fstate)
    begin
        if (i_Clock = '1' and i_Clock'event) then 
            fstate <= reg_fstate;
        end if;
    end process;

    process (fstate, i_Reset, i_Close_Cond, i_Spin_Cond,
             i_Release_Cond, i_Reset_Cond, i_Idle_Cond)
    begin
        if (i_Reset = '1') then
            reg_fstate <= MXR_IDLE;
            o_State <= MXR_IDLE;
        else
            o_State <= MXR_IDLE;
            case fstate is
                when MXR_IDLE =>
                    if (i_Close_Cond = '1') then
                        reg_fstate <= MXR_CLOSE;
                    else
                        reg_fstate <= MXR_IDLE;
                    end if;
                    o_State <= MXR_IDLE;

                when MXR_CLOSE =>
                    if (i_Spin_Cond = '1') then
                        reg_fstate <= MXR_SPIN;
                    else
                        reg_fstate <= MXR_CLOSE;
                    end if;
                    o_State <= MXR_CLOSE;
                
                when MXR_SPIN =>
                    if (i_Release_Cond = '1') then
                        reg_fstate <= MXR_RELEASE;
                    else
                        reg_fstate <= MXR_SPIN;
                    end if;
                    o_State <= MXR_SPIN;

                when MXR_RELEASE =>
                    if (i_Reset_Cond = '1') then
                        reg_fstate <= MXR_RESET;
                    else
                        reg_fstate <= MXR_RELEASE;
                    end if;
                    o_State <= MXR_RELEASE;

                when MXR_RESET =>
                        if (i_Idle_Cond = '1') then
                            reg_fstate <= MXR_IDLE;
                        else
                            reg_fstate <= MXR_RESET;
                        end if;
                    o_State <= MXR_RESET;

                when others =>
                    report "Undefined state";
            end case;
        end if;
    end process;
end rtl;