----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:38:04 03/10/2018 
-- Design Name: 
-- Module Name:    bbc_micro_ax309 - Behavioral 
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
--library UNISIM;
--use UNISIM.VComponents.all;

entity bbc_micro_ax309 is
	port (
			clk_50M00      : in    std_logic;
			ps2_kbd_clk    : in    std_logic;
			ps2_kbd_data   : in    std_logic;
			VGA_red        : out   std_logic_vector (4 downto 0);
			VGA_green      : out   std_logic_vector (5 downto 0);
			VGA_blue       : out   std_logic_vector (4 downto 0);
			VGA_vsync      : out   std_logic;
			VGA_hsync      : out   std_logic;
			SRAM_nOE       : out   std_logic;
			SRAM_nWE       : out   std_logic;
			SRAM_nCS1      : out  std_logic;
			SRAM_CS2			: out   std_logic;
			SRAM_nUB       : out   std_logic;
			SRAM_nLB       : out   std_logic;
			SRAM_A         : out   std_logic_vector (18 downto 0);
			SRAM_D         : inout std_logic_vector (15 downto 0);
			SDMISO         : in    std_logic;
			SDSS           : out   std_logic;
			SDCLK          : out   std_logic;
			SDMOSI         : out   std_logic;
			FLASH_CS       : out   std_logic;                     -- Active low FLASH chip select
			FLASH_SI       : out   std_logic;                     -- Serial output to FLASH chip SI pin
			FLASH_CK       : out   std_logic;                     -- FLASH clock
			FLASH_SO       : in    std_logic;                     -- Serial input from FLASH chip SO pin
			LEDs           : out   std_logic_vector (3 downto 0);
			BUTTONs        : in    std_logic_vector (3 downto 0);
			AVR_UART_tx    : out   std_logic;
			AVR_UART_rx    : in    std_logic
		);
end bbc_micro_ax309;

architecture Behavioral of bbc_micro_ax309 is
	signal clock_24        : std_logic;
	signal clock_27        : std_logic;
	signal clock_32        : std_logic;
	signal RAM_A           : std_logic_vector(18 downto 0);
	signal RAM_Din         : std_logic_vector(7 downto 0);
	signal RAM_Dout        : std_logic_vector(7 downto 0);
	signal RAM_nWE         : std_logic;
	signal RAM_nOE         : std_logic;
	signal RAM_nCS         : std_logic;
	
	signal SRAM_nCS        : std_logic;
	
	constant keyb_dip      : std_logic_vector(7 downto 0) := "00000000";
	signal caps_led		  : std_logic;
	signal shift_led		  : std_logic;
	
	constant vid_mode		  : std_logic_vector(3 downto 0) := "0000";
	constant m128_mode     : std_logic := '0';
	constant copro_mode    : std_logic := '0';
	
	signal m128_mode_1     : std_logic;
	signal m128_mode_2     : std_logic;
	
	signal powerup_reset_n : std_logic;
	signal hard_reset_n    : std_logic;
	
	-- stub out some of the unimplemented hardware as constants
	constant joystick1     : std_logic_vector(4 downto 0) := "00000";
	constant joystick2     : std_logic_vector(4 downto 0) := "00000";
	
	-- start address of user data in FLASH as obtained from bitmerge.py
	-- this is safely beyond the end of the bitstream
	constant user_address_beeb    : std_logic_vector(23 downto 0) := x"060000";
	constant user_address_master  : std_logic_vector(23 downto 0) := x"0A0000";
	signal   user_address         : std_logic_vector(23 downto 0);

	-- lenth of user data in FLASH = 256KB (16x 16K ROM) images
	constant user_length   : std_logic_vector(23 downto 0) := x"040000";

	-- high when FLASH is being copied to SRAM, can be used by user as active high reset
	signal bootstrap_busy  : std_logic;
begin
	bbc_micro : entity work.bbc_micro_core
	generic map (
		IncludeAMXMouse    => false,
		IncludeSID         => false,
		IncludeMusic5000   => false,
		IncludeICEDebugger => false,
		IncludeCoPro6502   => true,
		IncludeCoProSPI    => false,
		IncludeCoProEXT	 => false,
		UseOrigKeyboard    => false,
		UseT65Core         => false,
		UseAlanDCore       => true
	)
	port map (
		clock_32       => clock_32,
		clock_24       => clock_24,
		clock_27       => clock_27,
		hard_reset_n   => hard_reset_n,
		ps2_kbd_clk    => ps2_kbd_clk,
		ps2_kbd_data   => ps2_kbd_data,
		video_red      => VGA_red(4 downto 1),
		video_green    => VGA_green(5 downto 2),
		video_blue     => VGA_blue(4 downto 1),
		video_vsync    => VGA_vsync,
		video_hsync    => VGA_hsync,
		ext_nOE        => RAM_nOE,
		ext_nWE        => RAM_nWE,
		ext_nCS        => RAM_nCS,
		ext_A          => RAM_A,
		ext_Dout       => RAM_Dout,
		ext_Din        => RAM_Din,
		SDMISO         => SDMISO,
		SDSS           => SDSS,
		SDCLK          => SDCLK,
		SDMOSI         => SDMOSI,
		caps_led       => caps_led,
		shift_led      => shift_led,
		keyb_dip       => keyb_dip,
		vid_mode       => vid_mode,
		joystick1      => joystick1,
		joystick2      => joystick2,
		avr_RxD        => AVR_UART_rx,
		avr_TxD        => AVR_UART_tx,
		cpu_addr       => open,
		m128_mode      => m128_mode,
		copro_mode     => copro_mode,
		p_spi_ssel     => '0',
		p_spi_sck      => '0',
		p_spi_mosi     => '0',
		p_spi_miso     => open,
		p_irq_b        => open,
		p_nmi_b        => open,
		p_rst_b        => open,
		test           => open,
		-- original keyboard not yet supported on the Duo
		ext_keyb_led1  => open,
		ext_keyb_led2  => open,
		ext_keyb_led3  => open,
		ext_keyb_1mhz  => open,
		ext_keyb_en_n  => open,
		ext_keyb_pa    => open,
		ext_keyb_rst_n => '1',
		ext_keyb_ca2   => '1',
		ext_keyb_pa7   => '1'        
	);
	LEDs(0) <= caps_led;
	LEDs(1) <= shift_led;
	
	--------------------------------------------------------
	-- Clock Generation
	--------------------------------------------------------
	inst_dcm : entity work.dcm_ax309 port map (
		RESET    => '0',
		CLKIN => clk_50M00,
		CLK0_OUT => clock_32,
		CLK1_OUT => clock_27,
		CLK2_OUT => clock_24
	);
	
	--------------------------------------------------------
	-- ram interface
	--------------------------------------------------------
	
	SRAM_nUB <= '1';
	SRAM_nLB <= '0';
	SRAM_nCS1 <= SRAM_nCS;
	SRAM_CS2 <= not SRAM_nCS;

	
	--------------------------------------------------------
	-- BOOTSTRAP SPI FLASH to SRAM
	--------------------------------------------------------

	user_address <= user_address_master when m128_mode = '1' else user_address_beeb;
	inst_bootstrap: entity work.bootstrap
	generic map (
		user_length     => user_length
	)
	port map(
		clock           => clock_32,
		powerup_reset_n => powerup_reset_n,
		bootstrap_busy  => bootstrap_busy,
		user_address    => user_address,
		RAM_nOE         => RAM_nOE,
		RAM_nWE         => RAM_nWE,
		RAM_nCS         => RAM_nCS,
		RAM_A           => RAM_A,
		RAM_Din         => RAM_Din,
		RAM_Dout        => RAM_Dout,
		SRAM_nOE        => SRAM_nOE,
		SRAM_nWE        => SRAM_nWE,
		SRAM_nCS        => SRAM_nCS,
		SRAM_A(18 downto 0) => SRAM_A,
		SRAM_A(20 downto 19) => open,
		SRAM_D          => SRAM_D(7 downto 0),
		FLASH_CS        => FLASH_CS,
		FLASH_SI        => FLASH_SI,
		FLASH_CK        => FLASH_CK,
		FLASH_SO        => FLASH_SO
	);
	powerup_reset_n <= BUTTONS(0);
	hard_reset_n <= powerup_reset_n and not bootstrap_busy;

end Behavioral;

