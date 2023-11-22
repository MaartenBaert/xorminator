-- Copyright (c) 2022 Maarten Baert <info@maartenbaert.be>
-- Available under the MIT License - see LICENSE.txt for details.

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity xorminator_source is
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
end xorminator_source;

architecture rtl of xorminator_source is

    -- LUT truth tables
    constant lut_a : bit_vector(63 downto 0) := x"0000000099669696";
    constant lut_b : bit_vector(63 downto 0) := x"0000000066999696";
    constant lut_c : bit_vector(63 downto 0) := x"0000000066996969";
    constant lut_d : bit_vector(63 downto 0) := x"0000000099666969";

    -- wire delays for simulation (these values were chosen randomly)
    type wire_delays_t is array(0 to 3, 0 to 7) of natural;
    constant wire_delays : wire_delays_t := (
        (2600, 3700, 5700, 2600, 2200, 5200, 3800, 3800),
        (5200, 5400, 5700, 2100, 4200, 5800, 4800, 3600),
        (4400, 1500, 3500, 5500, 2600, 4500, 3600, 3800),
        (5400, 3800, 5400, 4300, 5600, 3000, 2300, 4600)
    );

    -- oscillator signals
    signal osc : std_logic_vector(7 downto 0);

    -- oscillator delay modeling
    type osc_i_t is array(0 to 3) of std_logic_vector(7 downto 0);
    signal osc_id : osc_i_t;
    signal osc_od : std_logic_vector(7 downto 0);

    -- sampling flip-flops
    signal osc_s1 : std_logic_vector(7 downto 0);
    signal osc_s2 : std_logic_vector(7 downto 0);

    -- prevent optimization of the oscillator and sampling flip-flops
    attribute DONT_TOUCH : string;
    attribute DONT_TOUCH of osc : signal is "TRUE";
    attribute DONT_TOUCH of osc_s1 : signal is "TRUE";
    attribute DONT_TOUCH of osc_s2 : signal is "TRUE";
    attribute DONT_TOUCH of trng_osc_0 : label is "TRUE";
    attribute DONT_TOUCH of trng_osc_1 : label is "TRUE";
    attribute DONT_TOUCH of trng_osc_2 : label is "TRUE";
    attribute DONT_TOUCH of trng_osc_3 : label is "TRUE";
    attribute DONT_TOUCH of trng_osc_4 : label is "TRUE";
    attribute DONT_TOUCH of trng_osc_5 : label is "TRUE";
    attribute DONT_TOUCH of trng_osc_6 : label is "TRUE";
    attribute DONT_TOUCH of trng_osc_7 : label is "TRUE";
    attribute DONT_TOUCH of trng_sff1_0 : label is "TRUE";
    attribute DONT_TOUCH of trng_sff1_1 : label is "TRUE";
    attribute DONT_TOUCH of trng_sff1_2 : label is "TRUE";
    attribute DONT_TOUCH of trng_sff1_3 : label is "TRUE";
    attribute DONT_TOUCH of trng_sff1_4 : label is "TRUE";
    attribute DONT_TOUCH of trng_sff1_5 : label is "TRUE";
    attribute DONT_TOUCH of trng_sff1_6 : label is "TRUE";
    attribute DONT_TOUCH of trng_sff1_7 : label is "TRUE";
    attribute DONT_TOUCH of trng_sff2_0 : label is "TRUE";
    attribute DONT_TOUCH of trng_sff2_1 : label is "TRUE";
    attribute DONT_TOUCH of trng_sff2_2 : label is "TRUE";
    attribute DONT_TOUCH of trng_sff2_3 : label is "TRUE";
    attribute DONT_TOUCH of trng_sff2_4 : label is "TRUE";
    attribute DONT_TOUCH of trng_sff2_5 : label is "TRUE";
    attribute DONT_TOUCH of trng_sff2_6 : label is "TRUE";
    attribute DONT_TOUCH of trng_sff2_7 : label is "TRUE";

    -- allow combinatorial loops in the oscillator
    attribute ALLOW_COMBINATORIAL_LOOPS : string;
    attribute ALLOW_COMBINATORIAL_LOOPS of osc : signal is "TRUE";

    -- manually specify location of LUTs and FFs
    attribute LOC : string;
    attribute LOC of trng_osc_0 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 0) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_osc_1 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 0) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_osc_2 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 0) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_osc_3 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 0) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_osc_4 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 1) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_osc_5 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 1) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_osc_6 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 1) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_osc_7 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 1) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_sff1_0 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 0) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_sff1_1 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 0) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_sff1_2 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 0) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_sff1_3 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 0) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_sff1_4 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 1) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_sff1_5 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 1) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_sff1_6 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 1) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_sff1_7 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 1) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_sff2_0 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 0) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_sff2_1 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 0) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_sff2_2 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 0) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_sff2_3 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 0) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_sff2_4 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 1) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_sff2_5 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 1) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_sff2_6 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 1) & "Y" & integer'image(loc_y + 0);
    attribute LOC of trng_sff2_7 : label is "SLICE_X" & integer'image(loc_x / 2 * 2 + 1) & "Y" & integer'image(loc_y + 0);

    -- manually specify placement of LUTs and FFs within the slice
    attribute BEL : string;
    attribute BEL of trng_osc_0 : label is "A6LUT";
    attribute BEL of trng_osc_1 : label is "B6LUT";
    attribute BEL of trng_osc_2 : label is "C6LUT";
    attribute BEL of trng_osc_3 : label is "D6LUT";
    attribute BEL of trng_osc_4 : label is "A6LUT";
    attribute BEL of trng_osc_5 : label is "B6LUT";
    attribute BEL of trng_osc_6 : label is "C6LUT";
    attribute BEL of trng_osc_7 : label is "D6LUT";
    attribute BEL of trng_sff1_0 : label is "AFF";
    attribute BEL of trng_sff1_1 : label is "BFF";
    attribute BEL of trng_sff1_2 : label is "CFF";
    attribute BEL of trng_sff1_3 : label is "DFF";
    attribute BEL of trng_sff1_4 : label is "AFF";
    attribute BEL of trng_sff1_5 : label is "BFF";
    attribute BEL of trng_sff1_6 : label is "CFF";
    attribute BEL of trng_sff1_7 : label is "DFF";
    attribute BEL of trng_sff2_0 : label is "A5FF";
    attribute BEL of trng_sff2_1 : label is "B5FF";
    attribute BEL of trng_sff2_2 : label is "C5FF";
    attribute BEL of trng_sff2_3 : label is "D5FF";
    attribute BEL of trng_sff2_4 : label is "A5FF";
    attribute BEL of trng_sff2_5 : label is "B5FF";
    attribute BEL of trng_sff2_6 : label is "C5FF";
    attribute BEL of trng_sff2_7 : label is "D5FF";

    -- lock pins of LUTs to prevent reordering
    attribute LOCK_PINS : string;
    attribute LOCK_PINS of trng_osc_0 : label is "I0:A4, I1:A6, I2:A3, I3:A2, I4:A1, I5:A5";
    attribute LOCK_PINS of trng_osc_1 : label is "I0:A5, I1:A1, I2:A2, I3:A3, I4:A6, I5:A4";
    attribute LOCK_PINS of trng_osc_2 : label is "I0:A5, I1:A1, I2:A2, I3:A3, I4:A6, I5:A4";
    attribute LOCK_PINS of trng_osc_3 : label is "I0:A4, I1:A6, I2:A3, I3:A2, I4:A1, I5:A5";
    attribute LOCK_PINS of trng_osc_4 : label is "I0:A4, I1:A6, I2:A3, I3:A2, I4:A1, I5:A5";
    attribute LOCK_PINS of trng_osc_5 : label is "I0:A5, I1:A1, I2:A2, I3:A3, I4:A6, I5:A4";
    attribute LOCK_PINS of trng_osc_6 : label is "I0:A5, I1:A1, I2:A2, I3:A3, I4:A6, I5:A4";
    attribute LOCK_PINS of trng_osc_7 : label is "I0:A4, I1:A6, I2:A3, I3:A2, I4:A1, I5:A5";

begin

    -- outputs
    raw_data <= osc_s2;

    -- oscillator
    trng_osc_0: LUT6 generic map (INIT => lut_a) port map (O => osc_od(0), I0 => osc_id(0)(1), I1 => osc_id(1)(2), I2 => osc_id(2)(4), I3 => osc_id(3)(5), I4 => ctrl(0), I5 => rst);
    trng_osc_1: LUT6 generic map (INIT => lut_b) port map (O => osc_od(1), I0 => osc_id(0)(0), I1 => osc_id(1)(3), I2 => osc_id(2)(5), I3 => osc_id(3)(4), I4 => ctrl(1), I5 => rst);
    trng_osc_2: LUT6 generic map (INIT => lut_a) port map (O => osc_od(2), I0 => osc_id(0)(3), I1 => osc_id(1)(0), I2 => osc_id(2)(6), I3 => osc_id(3)(7), I4 => ctrl(2), I5 => rst);
    trng_osc_3: LUT6 generic map (INIT => lut_b) port map (O => osc_od(3), I0 => osc_id(0)(2), I1 => osc_id(1)(1), I2 => osc_id(2)(7), I3 => osc_id(3)(6), I4 => ctrl(3), I5 => rst);
    trng_osc_4: LUT6 generic map (INIT => lut_a) port map (O => osc_od(4), I0 => osc_id(0)(5), I1 => osc_id(1)(6), I2 => osc_id(2)(0), I3 => osc_id(3)(1), I4 => ctrl(4), I5 => rst);
    trng_osc_5: LUT6 generic map (INIT => lut_b) port map (O => osc_od(5), I0 => osc_id(0)(4), I1 => osc_id(1)(7), I2 => osc_id(2)(1), I3 => osc_id(3)(0), I4 => ctrl(5), I5 => rst);
    trng_osc_6: LUT6 generic map (INIT => lut_c) port map (O => osc_od(6), I0 => osc_id(0)(7), I1 => osc_id(1)(4), I2 => osc_id(2)(2), I3 => osc_id(3)(3), I4 => ctrl(6), I5 => rst);
    trng_osc_7: LUT6 generic map (INIT => lut_d) port map (O => osc_od(7), I0 => osc_id(0)(6), I1 => osc_id(1)(5), I2 => osc_id(2)(3), I3 => osc_id(3)(2), I4 => ctrl(7), I5 => rst);

    -- oscillator delay modeling
    gen_osc_delay1: for i in 0 to 7 generate
        osc(i) <= osc_od(i) after 1000 ps;
        gen_osc_delay2: for j in 0 to 3 generate
            osc_id(j)(i) <= transport osc(i) after wire_delays(j, i) * 1 ps;
        end generate;
    end generate;

    -- sampling flip-flops, first stage
    trng_sff1_0: FDRE port map (C => clk, CE => '1', D => osc(0), Q => osc_s1(0), R => rst);
    trng_sff1_1: FDRE port map (C => clk, CE => '1', D => osc(1), Q => osc_s1(1), R => rst);
    trng_sff1_2: FDRE port map (C => clk, CE => '1', D => osc(2), Q => osc_s1(2), R => rst);
    trng_sff1_3: FDRE port map (C => clk, CE => '1', D => osc(3), Q => osc_s1(3), R => rst);
    trng_sff1_4: FDRE port map (C => clk, CE => '1', D => osc(4), Q => osc_s1(4), R => rst);
    trng_sff1_5: FDRE port map (C => clk, CE => '1', D => osc(5), Q => osc_s1(5), R => rst);
    trng_sff1_6: FDRE port map (C => clk, CE => '1', D => osc(6), Q => osc_s1(6), R => rst);
    trng_sff1_7: FDRE port map (C => clk, CE => '1', D => osc(7), Q => osc_s1(7), R => rst);

    -- sampling flip-flops, second stage
    trng_sff2_0: FDRE port map (C => clk, CE => '1', D => osc_s1(0), Q => osc_s2(0), R => rst);
    trng_sff2_1: FDRE port map (C => clk, CE => '1', D => osc_s1(1), Q => osc_s2(1), R => rst);
    trng_sff2_2: FDRE port map (C => clk, CE => '1', D => osc_s1(2), Q => osc_s2(2), R => rst);
    trng_sff2_3: FDRE port map (C => clk, CE => '1', D => osc_s1(3), Q => osc_s2(3), R => rst);
    trng_sff2_4: FDRE port map (C => clk, CE => '1', D => osc_s1(4), Q => osc_s2(4), R => rst);
    trng_sff2_5: FDRE port map (C => clk, CE => '1', D => osc_s1(5), Q => osc_s2(5), R => rst);
    trng_sff2_6: FDRE port map (C => clk, CE => '1', D => osc_s1(6), Q => osc_s2(6), R => rst);
    trng_sff2_7: FDRE port map (C => clk, CE => '1', D => osc_s1(7), Q => osc_s2(7), R => rst);

end rtl;
