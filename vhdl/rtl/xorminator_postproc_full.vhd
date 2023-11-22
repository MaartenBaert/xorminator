-- Copyright (c) 2022 Maarten Baert <info@maartenbaert.be>
-- Available under the MIT License - see LICENSE.txt for details.

library ieee;
use ieee.std_logic_1164.all;

entity xorminator_postproc_full is
    port (

        -- clock and synchronous reset
        clk         : in std_logic;
        rst         : in std_logic;

        -- raw random data inputs
        raw_data_a  : in std_logic_vector(7 downto 0);
        raw_data_b  : in std_logic_vector(7 downto 0);
        raw_data_c  : in std_logic_vector(7 downto 0);

        -- postprocessed random data output
        result_data : out std_logic_vector(7 downto 0)

    );
end xorminator_postproc_full;

architecture rtl of xorminator_postproc_full is

    -- constants
    constant advance : natural := 8;

    -- trivium state registers
    signal r_state_a : std_logic_vector(92 downto 0);
    signal r_state_b : std_logic_vector(83 downto 0);
    signal r_state_c : std_logic_vector(110 downto 0);

begin

    -- output
    result_data <=
        r_state_c(advance + 44 downto 45) xor r_state_c(advance - 1 downto 0) xor
        r_state_a(advance + 26 downto 27) xor r_state_a(advance - 1 downto 0) xor
        r_state_b(advance + 14 downto 15) xor r_state_b(advance - 1 downto 0);

    -- main process
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                r_state_a <= (others => '0');
                r_state_b <= (others => '0');
                r_state_c <= (others => '0');
            else
                r_state_a( 92 - advance downto 0) <= r_state_a( 92 downto advance);
                r_state_b( 83 - advance downto 0) <= r_state_b( 83 downto advance);
                r_state_c(110 - advance downto 0) <= r_state_c(110 downto advance);
                r_state_a( 92 downto  93 - advance) <=
                    r_state_c(advance + 44 downto 45) xor r_state_c(advance - 1 downto 0) xor
                    (r_state_c(advance downto 1) and r_state_c(advance + 1 downto 2)) xor
                    r_state_a(advance + 23 downto 24) xor raw_data_a;
                r_state_b( 83 downto  84 - advance) <=
                    r_state_a(advance + 26 downto 27) xor r_state_a(advance - 1 downto 0) xor
                    (r_state_a(advance downto 1) and r_state_a(advance + 1 downto 2)) xor
                    r_state_b(advance +  5 downto  6) xor raw_data_b;
                r_state_c(110 downto 111 - advance) <=
                    r_state_b(advance + 14 downto 15) xor r_state_b(advance - 1 downto 0) xor
                    (r_state_b(advance downto 1) and r_state_b(advance + 1 downto 2)) xor
                    r_state_c(advance + 23 downto 24) xor raw_data_c;
            end if;
        end if;
    end process;

end rtl;
