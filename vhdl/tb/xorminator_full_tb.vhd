-- Copyright (c) 2022 Maarten Baert <info@maartenbaert.be>
-- Available under the MIT License - see LICENSE.txt for details.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xorminator;
use xorminator.xorminator.all;
use xorminator.xorminator_internals.all;

entity xorminator_full_tb is
end xorminator_full_tb;

architecture bhv of xorminator_full_tb is

    -- clock and reset
    signal clk : std_logic;
    signal rst : std_logic;

    -- dut signals
    signal result_data  : std_logic_vector(7 downto 0);
    signal result_valid : std_logic;
    signal test_passed  : std_logic;
    signal test_failed  : std_logic;

    -- flag to stop simulation
    signal run : boolean := true;

begin

    dut_0: xorminator_full port map (
        clk          => clk,
        rst          => rst,
        result_data  => result_data,
        result_valid => result_valid,
        test_passed  => test_passed,
        test_failed  => test_failed
    );

    -- clock process
    process
    begin
        while run loop
            clk <= '1';
            wait for 5 ns;
            clk <= '0';
            wait for 5 ns;
        end loop;
        wait;
    end process;

    -- reset process
    process
    begin
        rst <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        rst <= '0';
        for i in 0 to 3000 loop
            wait until rising_edge(clk);
        end loop;
        rst <= '1';
        wait until rising_edge(clk);
        run <= false;
        wait;
    end process;

end bhv;
