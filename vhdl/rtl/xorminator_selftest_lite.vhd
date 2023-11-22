-- Copyright (c) 2022 Maarten Baert <info@maartenbaert.be>
-- Available under the MIT License - see LICENSE.txt for details.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity xorminator_selftest_lite is
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
end xorminator_selftest_lite;

architecture rtl of xorminator_selftest_lite is

    -- FSM
    signal r_counter     : unsigned(7 downto 0);
    signal r_subtest     : unsigned(2 downto 0);
    signal r_test_passed : std_logic;
    signal r_test_failed : std_logic;

    -- histogram value
    signal r_hist_value  : unsigned(7 downto 0);

begin

    -- outputs
    test_passed    <= r_test_passed;
    test_failed    <= r_test_failed;
    adv_done       <= '1' when r_counter = 255 else '0';
    adv_subtest    <= r_subtest;
    adv_hist_value <= r_hist_value;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                r_counter <= (others => '0');
                r_subtest <= (others => '0');
                r_test_passed <= '0';
                r_test_failed <= '0';
                r_hist_value <= (others => '0');
            else
                if raw_valid = '1' and r_test_failed = '0' then
                    r_counter <= r_counter + 1;
                    if r_counter = 255 then

                        -- determine whether the test has passed or failed
                        if r_hist_value < 32 or r_hist_value >= 224 then
                            r_test_passed <= '0';
                            r_test_failed <= '1';
                        else
                            r_subtest <= r_subtest + 1;
                            if r_subtest = 7 then
                                r_test_passed <= '1';
                            end if;
                        end if;

                        -- clear histogram value
                        r_hist_value <= (others => '0');

                    else

                        -- increment histogram value if selected bit is 1
                        if raw_data(to_integer(r_subtest)) = '1' then
                            r_hist_value <= r_hist_value + 1;
                        end if;

                    end if;
                end if;
            end if;
        end if;
    end process;

end rtl;
