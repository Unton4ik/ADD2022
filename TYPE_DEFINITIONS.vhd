library ieee;
use ieee.std_logic_1164.all;

package typedefs is
   type t_state_master is (MAST_IDLE, MAST_MIXING, MAST_SORTING, MAST_LIFTING);

   type t_state_mixer  is (MXR_IDLE, MXR_CLOSE, MXR_SPIN, MXR_RELEASE, MXR_RESET);
   type t_state_feeder is (FDR_IDLE, FDR_FEED);
   type t_state_stage  is (STG_IDLE, STG_TEST, STG_FAIL, STG_PASS, STG_RETURN);
   type t_state_lift   is (LFT_IDLE, LFT_GO_UP, LFT_WAIT, LFT_GO_DOWN);
   type t_state_screw  is (SCR_IDLE, SCR_SPIN);
end package;