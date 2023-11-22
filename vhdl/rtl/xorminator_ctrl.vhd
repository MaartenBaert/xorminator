-- Copyright (c) 2022 Maarten Baert <info@maartenbaert.be>
-- Available under the MIT License - see LICENSE.txt for details.

library ieee;
use ieee.std_logic_1164.all;

entity xorminator_ctrl is
    port (

        -- clock and synchronous reset
        clk       : in std_logic;
        rst       : in std_logic;

        -- control output
        ctrl  : out std_logic_vector(7 downto 0)

    );
end xorminator_ctrl;

architecture rtl of xorminator_ctrl is

    -- oscillator control register
    signal r_ctrl : std_logic_vector(7 downto 0);

    -- prevent optimization of the control register
    attribute DONT_TOUCH : string;
    attribute DONT_TOUCH of r_ctrl : signal is "TRUE";

begin

    -- outputs
    ctrl <= r_ctrl;

    -- main process
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                r_ctrl <= (others => '1');
            else
                r_ctrl(0) <= r_ctrl(1) xor r_ctrl(3) xor r_ctrl(5);
                r_ctrl(1) <= r_ctrl(0) xor r_ctrl(2) xor r_ctrl(4) xor r_ctrl(5);
                r_ctrl(2) <= r_ctrl(2) xor r_ctrl(4) xor r_ctrl(7);
                r_ctrl(3) <= r_ctrl(3) xor r_ctrl(4) xor r_ctrl(6) xor r_ctrl(7);
                r_ctrl(4) <= r_ctrl(0) xor r_ctrl(2) xor r_ctrl(5);
                r_ctrl(5) <= r_ctrl(2) xor r_ctrl(3) xor r_ctrl(5) xor r_ctrl(6);
                r_ctrl(6) <= r_ctrl(1) xor r_ctrl(3) xor r_ctrl(7);
                r_ctrl(7) <= r_ctrl(0) xor r_ctrl(1) xor r_ctrl(2) xor r_ctrl(4);
            end if;
        end if;
    end process;

end rtl;
