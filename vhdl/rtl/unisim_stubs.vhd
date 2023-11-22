-- Copyright (c) 2022 Maarten Baert <info@maartenbaert.be>
-- Available under the MIT License - see LICENSE.txt for details.

-- This file contains stubs for some primitives from the Xilinx Unisim library.
-- This is meant to support verification with open-source tools like GHDL
-- without depending on the official Xilinx Unisim library.

library ieee;
use ieee.std_logic_1164.all;

package vcomponents is

    component LUT6 is
        generic (
            INIT : bit_vector(63 downto 0) := X"0000000000000000"
        );
        port (
            O : out std_ulogic;
            I0 : in std_ulogic;
            I1 : in std_ulogic;
            I2 : in std_ulogic;
            I3 : in std_ulogic;
            I4 : in std_ulogic;
            I5 : in std_ulogic
        );
    end component;

    component FDRE is
        generic (
            INIT : std_ulogic := '0'
        );
        port (
            C : in std_ulogic;
            CE : in std_ulogic;
            D : in std_ulogic;
            Q : out std_ulogic;
            R : in std_ulogic
        );
    end component;

end vcomponents;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LUT6 is
    generic (
        INIT : bit_vector(63 downto 0) := X"0000000000000000"
    );
    port (
        O : out std_ulogic;
        I0 : in std_ulogic;
        I1 : in std_ulogic;
        I2 : in std_ulogic;
        I3 : in std_ulogic;
        I4 : in std_ulogic;
        I5 : in std_ulogic
    );
end LUT6;

architecture rtl of LUT6 is
    signal mux6 : std_ulogic_vector(63 downto 0);
    signal mux5 : std_ulogic_vector(31 downto 0);
    signal mux4 : std_ulogic_vector(15 downto 0);
    signal mux3 : std_ulogic_vector( 7 downto 0);
    signal mux2 : std_ulogic_vector( 3 downto 0);
    signal mux1 : std_ulogic_vector( 1 downto 0);
    signal mux0 : std_ulogic_vector( 0 downto 0);
begin
    mux6 <= to_stdulogicvector(INIT);
    mux5 <= (mux6(63 downto 32) and (31 downto 0 => I5)) or (mux6(31 downto 0) and not (31 downto 0 => I5)) or (mux6(63 downto 32) and mux6(31 downto 0));
    mux4 <= (mux5(31 downto 16) and (15 downto 0 => I4)) or (mux5(15 downto 0) and not (15 downto 0 => I4)) or (mux5(31 downto 16) and mux5(15 downto 0));
    mux3 <= (mux4(15 downto  8) and ( 7 downto 0 => I3)) or (mux4( 7 downto 0) and not ( 7 downto 0 => I3)) or (mux4(15 downto  8) and mux4( 7 downto 0));
    mux2 <= (mux3( 7 downto  4) and ( 3 downto 0 => I2)) or (mux3( 3 downto 0) and not ( 3 downto 0 => I2)) or (mux3( 7 downto  4) and mux3( 3 downto 0));
    mux1 <= (mux2( 3 downto  2) and ( 1 downto 0 => I1)) or (mux2( 1 downto 0) and not ( 1 downto 0 => I1)) or (mux2( 3 downto  2) and mux2( 1 downto 0));
    mux0 <= (mux1( 1 downto  1) and ( 0 downto 0 => I0)) or (mux1( 0 downto 0) and not ( 0 downto 0 => I0)) or (mux1( 1 downto  1) and mux1( 0 downto 0));
    O <= mux0(0);
end rtl;

library ieee;
use ieee.std_logic_1164.all;

entity FDRE is
    generic (
        INIT : std_ulogic := '0'
    );
    port (
        C : in std_ulogic;
        CE : in std_ulogic;
        D : in std_ulogic;
        Q : out std_ulogic;
        R : in std_ulogic
    );
end FDRE;

architecture rtl of FDRE is
    signal reg : std_ulogic := INIT;
begin
    Q <= reg;
    process(C)
    begin
        if C = 'U' or C = 'X' then
            reg <= reg xor C;
        elsif rising_edge(C) then
            reg <= ((D and CE) or (reg and not CE) or (D and reg)) and not R;
        end if;
    end process;
end rtl;
