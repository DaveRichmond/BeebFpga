library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity CoPro6502 is
    port (

        -- Host 
        h_clk      : in    std_logic;
        h_cs_b     : in    std_logic;
        h_rdnw     : in    std_logic;
        h_addr     : in    std_logic_vector(2 downto 0);
        h_data_in  : in    std_logic_vector(7 downto 0);
        h_data_out : out   std_logic_vector(7 downto 0);
        h_rst_b    : in    std_logic;
        h_irq_b    : out    std_logic;

        -- Parasite Clock (32 MHz)
        clk_cpu    : in    std_logic;

        -- Clock speed:
        -- 00 = 16MHz
        -- 01 = 8MHz
        -- 10 = 4MHz
        -- 11 = 2MHz
        sw     : in    std_logic_vector(1 downto 0);

        test   : out    std_logic_vector(7 downto 0)
    );
end;

architecture BEHAVIORAL of CoPro6502 is

component tube port (
    h_addr     : in  std_logic_vector(2 downto 0);
    h_cs_b     : in  std_logic;
    h_data_in  : in  std_logic_vector(7 downto 0);
    h_data_out : out  std_logic_vector(7 downto 0);
    h_phi2     : in  std_logic;
    h_rdnw     : in  std_logic;
    h_rst_b    : in  std_logic;
    h_irq_b    : out  std_logic;
    p_addr     : in  std_logic_vector(2 downto 0);
    p_cs_b     : in  std_logic;
    p_data_in  : in  std_logic_vector(7 downto 0);
    p_data_out : out  std_logic_vector(7 downto 0);
    p_rdnw     : in  std_logic;
    p_phi2     : in  std_logic;
    p_rst_b    : out std_logic;
    p_nmi_b    : out std_logic;
    p_irq_b    : out std_logic;
    test   : out    std_logic_vector(7 downto 0)
    );
end component;

-------------------------------------------------
-- clock and reset signals
-------------------------------------------------

    signal cpu_clken     : std_logic;
    signal bootmode      : std_logic;
    signal RSTn          : std_logic;
    signal RSTn_sync     : std_logic;
    signal clken_counter : std_logic_vector (3 downto 0);
    signal reset_counter : std_logic_vector (8 downto 0);
    
-------------------------------------------------
-- parasite signals
-------------------------------------------------
    
    signal p_cs_b        : std_logic;
    signal p_data_out    : std_logic_vector (7 downto 0);

-------------------------------------------------
-- ram/rom signals
-------------------------------------------------

    signal ram_cs_b        : std_logic;
    signal ram_wr_int      : std_logic;
    signal rom_cs_b        : std_logic;
    signal rom_data_out    : std_logic_vector (7 downto 0);
    signal ram_data_out    : std_logic_vector (7 downto 0);

-------------------------------------------------
-- cpu signals
-------------------------------------------------

    signal cpu_R_W_n  : std_logic;
    signal cpu_addr   : std_logic_vector (23 downto 0);
    signal cpu_addr_us: unsigned (23 downto 0);
    signal cpu_din    : std_logic_vector (7 downto 0);
    signal cpu_dout   : std_logic_vector (7 downto 0);
    signal cpu_dout_us: unsigned (7 downto 0);
    signal cpu_IRQ_n  : std_logic;
    signal cpu_NMI_n  : std_logic;
    signal cpu_IRQ_n_sync  : std_logic;
    signal cpu_NMI_n_sync  : std_logic;
    signal sync       : std_logic;

begin

---------------------------------------------------------------------
-- instantiated components
---------------------------------------------------------------------

    inst_tuberom : entity work.tuberom_65c102 port map (
        CLK             => clk_cpu,
        ADDR            => cpu_addr(10 downto 0),
        DATA            => rom_data_out
    );

    inst_r65c02: entity work.r65c02 port map(
        reset    => RSTn_sync,
        clk      => clk_cpu,
        enable   => cpu_clken,
        nmi_n    => cpu_NMI_n_sync,
        irq_n    => cpu_IRQ_n_sync,
        di       => unsigned(cpu_din),
        do       => cpu_dout_us,
        addr     => cpu_addr_us(15 downto 0),
        nwe      => cpu_R_W_n,
        sync     => sync,
        sync_irq => open
        );
        cpu_dout <= std_logic_vector(cpu_dout_us);
        cpu_addr <= std_logic_vector(cpu_addr_us);

    inst_tube: tube port map (
        h_addr          => h_addr,
        h_cs_b          => h_cs_b,
        h_data_in       => h_data_in,
        h_data_out      => h_data_out,
        h_phi2          => not h_clk,
        h_rdnw          => h_rdnw,
        h_rst_b         => h_rst_b,
        h_irq_b         => h_irq_b,
        p_addr          => cpu_addr(2 downto 0),
        p_cs_b          => not((not p_cs_b) and cpu_clken),
        p_data_in       => cpu_dout,
        p_data_out      => p_data_out,
        p_rdnw          => cpu_R_W_n,
        p_phi2          => clk_cpu,
        p_rst_b         => RSTn,
        p_nmi_b         => cpu_NMI_n,
        p_irq_b         => cpu_IRQ_n,
        test            => test
    );

    Inst_RAM_16K: entity work.RAM_16K PORT MAP(
        clk     => clk_cpu,
        we_uP   => ram_wr_int,
        ce      => '1',
        addr_uP => cpu_addr(13 downto 0),
        D_uP    => cpu_dout,
        Q_uP    => ram_data_out
    );

    p_cs_b <= '0' when cpu_addr(15 downto 3) = "1111111011111" else '1';

    rom_cs_b <= '0' when cpu_addr(15 downto 11) = "11111" and cpu_R_W_n = '1' and bootmode = '1' else '1';

    ram_cs_b <= '0' when p_cs_b = '1' and rom_cs_b = '1' else '1';
    
    ram_wr_int <= ((not ram_cs_b) and (not cpu_R_W_n) and cpu_clken);

    cpu_din <=
        p_data_out   when p_cs_b      = '0' else
        rom_data_out when rom_cs_b    = '0' else
        ram_data_out when ram_cs_b    = '0' else
        x"f1";
            
--------------------------------------------------------
-- boot mode generator
--------------------------------------------------------
    boot_gen : process(clk_cpu, RSTn_sync)
    begin
        if RSTn_sync = '0' then
            bootmode <= '1';
        elsif rising_edge(clk_cpu) then
            if p_cs_b = '0' then
                bootmode <= '0';
            end if;
        end if;
    end process;

--------------------------------------------------------
-- power up reset
--------------------------------------------------------
    reset_gen : process(clk_cpu)
    begin
        if rising_edge(clk_cpu) then
            if (reset_counter(8) = '0') then
                reset_counter <= reset_counter + 1;
            end if;
            RSTn_sync <= RSTn AND reset_counter(8);
        end if;
    end process;

--------------------------------------------------------
-- interrupt synchronization
--------------------------------------------------------
    sync_gen : process(clk_cpu, RSTn_sync)
    begin
        if RSTn_sync = '0' then
            cpu_NMI_n_sync <= '1';
            cpu_IRQ_n_sync <= '1';
        elsif rising_edge(clk_cpu) then
            if (cpu_clken = '1') then
                cpu_NMI_n_sync <= cpu_NMI_n;
                cpu_IRQ_n_sync <= cpu_IRQ_n;
            end if;
        end if;
    end process;

--------------------------------------------------------
-- clock enable generator
--------------------------------------------------------
    clk_gen : process(clk_cpu)
    begin
        if rising_edge(clk_cpu) then
            clken_counter <= clken_counter + 1;
            case "00" & sw(1 downto 0) is
               when x"0"   =>
                   cpu_clken     <= clken_counter(0);
               when x"1"   =>
                   cpu_clken     <= clken_counter(1) and clken_counter(0);
               when x"2"   =>
                   cpu_clken     <= clken_counter(2) and clken_counter(1) and clken_counter(0);
               when x"3"   =>
                   cpu_clken     <= clken_counter(3) and clken_counter(2) and clken_counter(1) and clken_counter(0);
               when others =>
                   cpu_clken     <= clken_counter(0);
            end case;
        end if;
    end process;


    -- test <= RSTn & RSTn_sync &  h_rst_b & cpu_NMI_n_sync &  cpu_IRQ_n_sync & bootmode & "00";
    
end BEHAVIORAL;


