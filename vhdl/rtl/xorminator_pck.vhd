-- Copyright (c) 2022 Maarten Baert <info@maartenbaert.be>
-- Available under the MIT License - see LICENSE.txt for details.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package xorminator is

    component xorminator_lite is
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
    end component;

    component xorminator_full is
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
    end component;

end xorminator;
