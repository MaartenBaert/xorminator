-- Copyright (c) 2022 Maarten Baert <info@maartenbaert.be>
-- Available under the MIT License - see LICENSE.txt for details.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xorminator;
use xorminator.xorminator_internals.all;

entity xorminator_lite is
    generic (
        loc_x : natural := 0;
        loc_y : natural := 0
    );
    port (

        -- clock and synchronous reset
        clk          : in std_logic;
        rst          : in std_logic;

        -- postprocessed random data output
        result_data  : out std_logic_vector(3 downto 0);
        result_valid : out std_logic;

        -- test result output
        test_passed  : out std_logic;
        test_failed  : out std_logic

    );
end xorminator_lite;

architecture rtl of xorminator_lite is

    signal ctrl     : std_logic_vector(7 downto 0);
    signal raw_data : std_logic_vector(7 downto 0);
    signal raw_valid : std_logic;

    signal r_valid_counter : natural range 0 to 8;

begin

    raw_valid    <= '0' when r_valid_counter < 4 else '1';
    result_valid <= '0' when r_valid_counter < 8 else '1';

    ctrl_0: xorminator_ctrl port map (
        clk  => clk,
        rst  => rst,
        ctrl => ctrl
    );

    source_0: xorminator_source generic map (
        loc_x => loc_x,
        loc_y => loc_y
    ) port map (
        clk      => clk,
        rst      => rst,
        ctrl     => ctrl,
        raw_data => raw_data
    );

    postproc_0: xorminator_postproc_lite port map (
        clk         => clk,
        rst         => rst,
        raw_data    => raw_data,
        result_data => result_data
    );

    selftest_0: xorminator_selftest_lite port map (
        clk            => clk,
        rst            => rst,
        raw_data       => raw_data,
        raw_valid      => raw_valid,
        test_passed    => test_passed,
        test_failed    => test_failed,
        adv_done       => open,
        adv_subtest    => open,
        adv_hist_value => open
    );

    -- main process
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                r_valid_counter <= 0;
            elsif r_valid_counter /= 8 then
                r_valid_counter <= r_valid_counter + 1;
            end if;
        end if;
    end process;

end rtl;
