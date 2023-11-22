-- Copyright (c) 2022 Maarten Baert <info@maartenbaert.be>
-- Available under the MIT License - see LICENSE.txt for details.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package xorminator_internals is

    component xorminator_ctrl is
        port (

            -- clock and synchronous reset
            clk       : in std_logic;
            rst       : in std_logic;

            -- control output
            ctrl  : out std_logic_vector(7 downto 0)

        );
    end component;

    component xorminator_source is
        generic (
            loc_x : natural := 0;
            loc_y : natural := 0
        );
        port (

            -- clock and synchronous reset
            clk      : in std_logic;
            rst      : in std_logic;

            -- control input
            ctrl     : in std_logic_vector(7 downto 0);

            -- raw random data output
            raw_data : out std_logic_vector(7 downto 0)

        );
    end component;

    component xorminator_postproc_lite is
        port (

            -- clock and synchronous reset
            clk         : in std_logic;
            rst         : in std_logic;

            -- raw random data input
            raw_data    : in std_logic_vector(7 downto 0);

            -- postprocessed random data output
            result_data : out std_logic_vector(3 downto 0)

        );
    end component;

    component xorminator_postproc_full is
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
    end component;

    component xorminator_selftest_lite is
        port (

            -- clock and synchronous reset
            clk            : in std_logic;
            rst            : in std_logic;

            -- raw random data input
            raw_data       : in std_logic_vector(7 downto 0);
            raw_valid      : in std_logic;

            -- test result output
            test_passed    : out std_logic;
            test_failed    : out std_logic;

            -- advanced test result output
            adv_done       : out std_logic;
            adv_subtest    : out unsigned(2 downto 0);
            adv_hist_value : out unsigned(7 downto 0)

        );
    end component;

    component xorminator_selftest_full is
        port (

            -- clock and synchronous reset
            clk            : in std_logic;
            rst            : in std_logic;

            -- raw random data input
            raw_data_a     : in std_logic_vector(7 downto 0);
            raw_data_b     : in std_logic_vector(7 downto 0);
            raw_data_c     : in std_logic_vector(7 downto 0);
            raw_valid      : in std_logic;

            -- test result output
            test_passed    : out std_logic;
            test_failed    : out std_logic;

            -- advanced test result output
            adv_done       : out std_logic;
            adv_source     : out unsigned(1 downto 0);
            adv_subtest    : out unsigned(1 downto 0);
            adv_hist_min   : out unsigned(8 downto 0);
            adv_hist_max   : out unsigned(8 downto 0);
            adv_chisquared : out unsigned(11 downto 0)

        );
    end component;

end xorminator_internals;
