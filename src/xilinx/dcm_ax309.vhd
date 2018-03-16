----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:35:01 03/10/2018 
-- Design Name: 
-- Module Name:    dcm_ax309 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity dcm_ax309 is
    Port ( 	
				RESET : in std_logic;
				CLKIN : in  STD_LOGIC;
				CLK0_OUT : out  STD_LOGIC;
				CLK1_OUT : out  STD_LOGIC;
				CLK2_OUT : out  STD_LOGIC);
end dcm_ax309;

architecture Behavioral of dcm_ax309 is
  signal clkfbout         : std_logic;
  signal clkfbout_buf     : std_logic;
  signal clkout0          : std_logic;
  signal clkout1          : std_logic;
  signal clkout2          : std_logic;
  signal clkout3_unused   : std_logic;
  signal clkout4_unused   : std_logic;
  signal clkout5_unused   : std_logic;
  signal locked           : std_logic;
begin
  pll_base_inst : PLL_BASE
  generic map
   (BANDWIDTH            => "OPTIMIZED",
    CLK_FEEDBACK         => "CLKFBOUT",
    COMPENSATION         => "SYSTEM_SYNCHRONOUS",
    DIVCLK_DIVIDE        => 2,
    CLKFBOUT_MULT        => 41,
    CLKFBOUT_PHASE       => 0.000,
    CLKOUT0_DIVIDE       => 32,
    CLKOUT0_PHASE        => 0.000,
    CLKOUT0_DUTY_CYCLE   => 0.500,
    CLKOUT1_DIVIDE       => 38,
    CLKOUT1_PHASE        => 0.000,
    CLKOUT1_DUTY_CYCLE   => 0.500,
    CLKOUT2_DIVIDE       => 43,
    CLKOUT2_PHASE        => 0.000,
    CLKOUT2_DUTY_CYCLE   => 0.500,
    CLKIN_PERIOD         => 20.000,
    REF_JITTER           => 0.010)
  port map (
		-- Output clocks
		CLKFBOUT            => clkfbout,
		CLKOUT0             => clkout0,
		CLKOUT1             => clkout1,
		CLKOUT2             => clkout2,
		CLKOUT3             => clkout3_unused,
		CLKOUT4             => clkout4_unused,
		CLKOUT5             => clkout5_unused,
		-- Status and control signals
		LOCKED              => LOCKED,
		RST                 => RESET,
		-- Input clock control
		CLKFBIN             => clkfbout_buf,
		CLKIN               => CLKIN);
	 
	clkf_buf : BUFG port map (
		O => clkfbout_buf,
		I => clkfbout);
		
	clkout1_buf : BUFG port map (
		O   => CLK0_OUT,
		I   => clkout0);

	clkout2_buf : BUFG port map (
		O   => CLK1_OUT,
		I   => clkout1);

	clkout3_buf : BUFG port map (
		O   => CLK2_OUT,
		I   => clkout2);

end Behavioral;

