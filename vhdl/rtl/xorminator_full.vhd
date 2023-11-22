-- Copyright (c) 2022 Maarten Baert <info@maartenbaert.be>
-- Available under the MIT License - see LICENSE.txt for details.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xorminator;
use xorminator.xorminator_internals.all;

entity xorminator_full is
    generic (
        loc_x : natural := 0;
        loc_y : natural := 0
    );
    port (

        -- clock and synchronous reset
        clk          : in std_logic;
        rst          : in std_logic;

        -- postprocessed random data output
        result_data  : out std_logic_vector(7 downto 0);
        result_valid : out std_logic;

        -- test result output
        test_passed  : out std_logic;
        test_failed  : out std_logic

    );
end xorminator_full;

architecture rtl of xorminator_full is

    signal ctrl       : std_logic_vector(7 downto 0);
    signal raw_data_a : std_logic_vector(7 downto 0);
    signal raw_data_b : std_logic_vector(7 downto 0);
    signal raw_data_c : std_logic_vector(7 downto 0);
    signal raw_valid  : std_logic;

    signal test_passed_a : std_logic;
    signal test_passed_b : std_logic;
    signal test_passed_c : std_logic;
    signal test_passed_d : std_logic;
    signal test_failed_a : std_logic;
    signal test_failed_b : std_logic;
    signal test_failed_c : std_logic;
    signal test_failed_d : std_logic;

    signal r_valid_counter : natural range 0 to 184;

begin

    raw_valid    <= '0' when r_valid_counter < 4   else '1';
    result_valid <= '0' when r_valid_counter < 184 else '1';

    test_passed <=
        test_passed_a and test_passed_b and test_passed_c and test_passed_d
        and not (test_failed_a or test_failed_b or test_failed_c or test_failed_d);
    test_failed <= test_failed_a or test_failed_b or test_failed_c or test_failed_d;

    ctrl_0: xorminator_ctrl port map (
        clk  => clk,
        rst  => rst,
        ctrl => ctrl
    );

    source_0: xorminator_source generic map (
        loc_x => loc_x,
        loc_y => loc_y + 0
    ) port map (
        clk      => clk,
        rst      => rst,
        ctrl     => ctrl,
        raw_data => raw_data_a
    );
    source_1: xorminator_source generic map (
        loc_x => loc_x,
        loc_y => loc_y + 1
    ) port map (
        clk      => clk,
        rst      => rst,
        ctrl     => ctrl,
        raw_data => raw_data_b
    );
    source_2: xorminator_source generic map (
        loc_x => loc_x,
        loc_y => loc_y + 2
    ) port map (
        clk      => clk,
        rst      => rst,
        ctrl     => ctrl,
        raw_data => raw_data_c
    );

    postproc_0: xorminator_postproc_full port map (
        clk         => clk,
        rst         => rst,
        raw_data_a  => raw_data_a,
        raw_data_b  => raw_data_b,
        raw_data_c  => raw_data_c,
        result_data => result_data
    );

    selftest_0: xorminator_selftest_lite port map (
        clk            => clk,
        rst            => rst,
        raw_data       => raw_data_a,
        raw_valid      => raw_valid,
        test_passed    => test_passed_a,
        test_failed    => test_failed_a,
        adv_done       => open,
        adv_subtest    => open,
        adv_hist_value => open
    );
    selftest_1: xorminator_selftest_lite port map (
        clk            => clk,
        rst            => rst,
        raw_data       => raw_data_b,
        raw_valid      => raw_valid,
        test_passed    => test_passed_b,
        test_failed    => test_failed_b,
        adv_done       => open,
        adv_subtest    => open,
        adv_hist_value => open
    );
    selftest_2: xorminator_selftest_lite port map (
        clk            => clk,
        rst            => rst,
        raw_data       => raw_data_c,
        raw_valid      => raw_valid,
        test_passed    => test_passed_c,
        test_failed    => test_failed_c,
        adv_done       => open,
        adv_subtest    => open,
        adv_hist_value => open
    );
    selftest_3: xorminator_selftest_full port map (
        clk            => clk,
        rst            => rst,
        raw_data_a     => raw_data_a,
        raw_data_b     => raw_data_b,
        raw_data_c     => raw_data_c,
        raw_valid      => raw_valid,
        test_passed    => test_passed_d,
        test_failed    => test_failed_d,
        adv_done       => open,
        adv_source     => open,
        adv_subtest    => open,
        adv_hist_min   => open,
        adv_hist_max   => open,
        adv_chisquared => open
    );

    -- main process
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                r_valid_counter <= 0;
            elsif r_valid_counter /= 184 then
                r_valid_counter <= r_valid_counter + 1;
            end if;
        end if;
    end process;

end rtl;
