-- Copyright (c) 2022 Maarten Baert <info@maartenbaert.be>
-- Available under the MIT License - see LICENSE.txt for details.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xorminator;
use xorminator.xorminator.all;
use xorminator.xorminator_internals.all;

entity xorminator_source_tb is
end xorminator_source_tb;

architecture bhv of xorminator_source_tb is

    -- clock and reset
    signal clk : std_logic;
    signal rst : std_logic;

    -- ctrl signals
    signal ctrl : std_logic_vector(7 downto 0);

    -- core signals
    signal raw_data : std_logic_vector(7 downto 0);

    -- postproc signals
    signal result_data : std_logic_vector(3 downto 0);

    -- flag to stop simulation
    signal run : boolean := true;

begin

    ctrl_0: xorminator_ctrl port map (
        clk       => clk,
        rst       => rst,
        ctrl      => ctrl
    );

    core_0: xorminator_source port map (
        clk       => clk,
        rst       => rst,
        ctrl      => ctrl,
        raw_data  => raw_data
    );

    postproc_0: xorminator_postproc_lite port map (
        clk          => clk,
        rst          => rst,
        raw_data     => raw_data,
        result_data  => result_data
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
        for i in 0 to 99 loop
            wait until rising_edge(clk);
        end loop;
        rst <= '1';
        wait until rising_edge(clk);
        run <= false;
        wait;
    end process;

end bhv;
