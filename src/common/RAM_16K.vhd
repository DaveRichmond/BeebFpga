library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity RAM_16K is
    port (
        clk     : in  std_logic;
        we_uP   : in  std_logic;
        ce      : in  std_logic;
        addr_uP : in  std_logic_vector (13 downto 0);
        D_uP    : in  std_logic_vector (7 downto 0);
        Q_uP    : out std_logic_vector (7 downto 0));
end;

architecture BEHAVIORAL of RAM_16K is

    type   ram_type is array (16383 downto 0) of std_logic_vector (7 downto 0);
    signal RAM                 : ram_type := (16383 downto 0 => X"ff");
    attribute RAM_STYLE        : string;
    attribute RAM_STYLE of RAM : signal is "BLOCK";

begin

    process (clk)
    begin
        if rising_edge(clk) then
            if (we_UP = '1' and ce = '1') then
                RAM(conv_integer(addr_uP(13 downto 0))) <= D_up;
            end if;
            Q_up <= RAM(conv_integer(addr_uP(13 downto 0)));
            
        end if;
    end process;
end BEHAVIORAL;



