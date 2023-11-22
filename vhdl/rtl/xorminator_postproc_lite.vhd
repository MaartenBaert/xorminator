-- Copyright (c) 2022 Maarten Baert <info@maartenbaert.be>
-- Available under the MIT License - see LICENSE.txt for details.

library ieee;
use ieee.std_logic_1164.all;

entity xorminator_postproc_lite is
    port (

        -- clock and synchronous reset
        clk         : in std_logic;
        rst         : in std_logic;

        -- raw random data input
        raw_data    : in std_logic_vector(7 downto 0);

        -- postprocessed random data output
        result_data : out std_logic_vector(3 downto 0)

    );
end xorminator_postproc_lite;

architecture rtl of xorminator_postproc_lite is

    -- xormix state
    signal r_state : std_logic_vector(15 downto 0);

begin

    -- output
    result_data <= r_state(3 downto 0);

    -- main process
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                r_state <= (others => '0');
            else
                r_state( 0) <= r_state( 5) xor r_state(11) xor r_state( 6) xor r_state( 8) xor r_state(10) xor raw_data(0);
                r_state( 1) <= r_state( 3) xor r_state(13) xor r_state( 8) xor r_state( 5) xor r_state(14) xor raw_data(1);
                r_state( 2) <= r_state(11) xor r_state(13) xor r_state( 4) xor r_state( 7) xor r_state( 3) xor raw_data(2);
                r_state( 3) <= r_state( 7) xor r_state( 6) xor r_state(15) xor r_state( 1) xor r_state(13) xor raw_data(3);
                r_state( 4) <= r_state(10) xor r_state(13) xor r_state( 2) xor r_state( 6) xor r_state( 9) xor raw_data(4);
                r_state( 5) <= r_state( 2) xor r_state(10) xor r_state(15) xor r_state( 4) xor r_state( 7) xor raw_data(5);
                r_state( 6) <= r_state( 4) xor r_state( 1) xor r_state( 2) xor r_state( 9) xor r_state(14) xor raw_data(6);
                r_state( 7) <= r_state( 6) xor r_state(12) xor r_state(13) xor r_state( 7) xor r_state( 8) xor raw_data(7);
                r_state( 8) <= r_state( 1) xor r_state( 4) xor r_state(14) xor r_state(12) xor r_state( 3) xor r_state(15);
                r_state( 9) <= r_state(10) xor r_state(14) xor r_state(11) xor r_state( 1) xor r_state( 9) xor r_state( 7);
                r_state(10) <= r_state(15) xor r_state( 2) xor r_state( 0) xor r_state(11) xor r_state( 5) xor r_state( 3);
                r_state(11) <= r_state( 3) xor r_state(12) xor r_state(11) xor r_state( 4) xor r_state(10) xor r_state( 8);
                r_state(12) <= r_state( 0) xor r_state(10) xor r_state(14) xor r_state( 5) xor r_state( 6) xor r_state( 2);
                r_state(13) <= r_state( 9) xor r_state( 5) xor r_state( 0) xor r_state(12) xor r_state( 1) xor r_state( 4);
                r_state(14) <= r_state( 9) xor r_state( 8) xor r_state( 0) xor r_state(15) xor r_state( 2) xor r_state(12);
                r_state(15) <= r_state( 0) xor r_state( 5) xor r_state(15) xor r_state( 3) xor r_state( 9) xor r_state( 1);
            end if;
        end if;
    end process;

end rtl;
