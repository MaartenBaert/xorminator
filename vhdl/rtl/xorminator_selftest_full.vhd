-- Copyright (c) 2022 Maarten Baert <info@maartenbaert.be>
-- Available under the MIT License - see LICENSE.txt for details.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity xorminator_selftest_full is
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
end xorminator_selftest_full;

architecture rtl of xorminator_selftest_full is

    -- Square lookup table, calculated as follows:
    --   table = ((arange(512) - 256)**2 / 64).reshape(-1, 2).mean(axis=1).round().astype(int)
    --   print(',\n'.join(', '.join(f'x"{x:03x}"' for x in row) for row in table.reshape(-1, 16)))
    -- We need to use a signal instead of a constant to make ROM_STYLE work.
    -- Also, the table is 12-bit even though only 10 bits are actually used because otherwise they can't be entered in hexadecimal format.
    type t_square is array(0 to 2**8 - 1) of unsigned(11 downto 0);
    signal c_square : t_square := (
        x"3fc", x"3ec", x"3dc", x"3cd", x"3bd", x"3ae", x"39e", x"38f", x"380", x"371", x"363", x"354", x"345", x"337", x"329", x"31b",
        x"30d", x"2ff", x"2f1", x"2e3", x"2d6", x"2c8", x"2bb", x"2ae", x"2a1", x"294", x"287", x"27a", x"26e", x"261", x"255", x"249",
        x"23d", x"231", x"225", x"21a", x"20e", x"203", x"1f7", x"1ec", x"1e1", x"1d6", x"1cc", x"1c1", x"1b6", x"1ac", x"1a2", x"198",
        x"18e", x"184", x"17a", x"170", x"167", x"15d", x"154", x"14b", x"142", x"139", x"130", x"127", x"11f", x"116", x"10e", x"106",
        x"0fe", x"0f6", x"0ee", x"0e7", x"0df", x"0d8", x"0d0", x"0c9", x"0c2", x"0bb", x"0b5", x"0ae", x"0a7", x"0a1", x"09b", x"095",
        x"08f", x"089", x"083", x"07d", x"078", x"072", x"06d", x"068", x"063", x"05e", x"059", x"054", x"050", x"04b", x"047", x"043",
        x"03f", x"03b", x"037", x"034", x"030", x"02d", x"029", x"026", x"023", x"020", x"01e", x"01b", x"018", x"016", x"014", x"012",
        x"010", x"00e", x"00c", x"00a", x"009", x"007", x"006", x"005", x"004", x"003", x"002", x"001", x"001", x"000", x"000", x"000",
        x"000", x"000", x"000", x"001", x"001", x"002", x"002", x"003", x"004", x"005", x"007", x"008", x"009", x"00b", x"00d", x"00f",
        x"011", x"013", x"015", x"017", x"01a", x"01c", x"01f", x"022", x"025", x"028", x"02b", x"02e", x"032", x"035", x"039", x"03d",
        x"041", x"045", x"049", x"04e", x"052", x"057", x"05b", x"060", x"065", x"06a", x"070", x"075", x"07a", x"080", x"086", x"08c",
        x"092", x"098", x"09e", x"0a4", x"0ab", x"0b1", x"0b8", x"0bf", x"0c6", x"0cd", x"0d4", x"0db", x"0e3", x"0ea", x"0f2", x"0fa",
        x"102", x"10a", x"112", x"11b", x"123", x"12c", x"134", x"13d", x"146", x"14f", x"159", x"162", x"16b", x"175", x"17f", x"189",
        x"193", x"19d", x"1a7", x"1b1", x"1bc", x"1c6", x"1d1", x"1dc", x"1e7", x"1f2", x"1fd", x"208", x"214", x"21f", x"22b", x"237",
        x"243", x"24f", x"25b", x"268", x"274", x"281", x"28d", x"29a", x"2a7", x"2b4", x"2c2", x"2cf", x"2dc", x"2ea", x"2f8", x"306",
        x"314", x"322", x"330", x"33e", x"34d", x"35b", x"36a", x"379", x"388", x"397", x"3a6", x"3b5", x"3c5", x"3d4", x"3e4", x"3f4"
    );

    -- FSM
    type t_state is (STATE_CLEAR, STATE_COUNT, STATE_PROCESS, STATE_DONE, STATE_HALT);
    signal r_state       : t_state;
    signal r_counter     : unsigned(15 downto 0);
    signal r_source      : unsigned(1 downto 0);
    signal r_subtest     : unsigned(1 downto 0);
    signal r_test_passed : std_logic;
    signal r_test_failed : std_logic;

    -- raw data delay register
    signal r_raw_data_s : std_logic_vector(7 downto 0);
    signal r_raw_data_d : std_logic_vector(7 downto 0);

    -- current histogram index and value
    signal r_hist_index : unsigned(7 downto 0);
    signal r_hist_value : unsigned(8 downto 0);

    -- histogram min/max test
    signal r_hist_min : unsigned(8 downto 0);
    signal r_hist_max : unsigned(8 downto 0);

    -- chi-square test
    signal r_chisquared_value : unsigned(11 downto 0);

    -- histogram memory
    type t_histogram is array(0 to 2**8 - 1) of unsigned(8 downto 0);
    signal r_histogram : t_histogram;

    -- use LUTs for lookup table and histogram
    attribute ROM_STYLE : string;
    attribute RAM_STYLE : string;
    attribute ROM_STYLE of c_square : signal is "distributed";
    attribute RAM_STYLE of r_histogram : signal is "distributed";

begin

    -- outputs
    test_passed    <= r_test_passed;
    test_failed    <= r_test_failed;
    adv_done       <= '1' when r_state = STATE_DONE else '0';
    adv_source     <= r_source;
    adv_subtest    <= r_subtest;
    adv_hist_min   <= r_hist_min;
    adv_hist_max   <= r_hist_max;
    adv_chisquared <= r_chisquared_value;

    process(clk)

        -- calculations
        variable v_incremented     : unsigned(9 downto 0);
        variable v_histogram_wdata : unsigned(8 downto 0);
        variable v_histogram_wen   : std_logic;
        variable v_chisquared_temp : unsigned(12 downto 0);

        -- next state related
        variable v_state_next      : t_state;
        variable v_counter_next    : unsigned(15 downto 0);
        variable v_preprocessed    : std_logic_vector(7 downto 0);
        variable v_hist_index_next : unsigned(7 downto 0);

    begin
        if rising_edge(clk) then
            if rst = '1' then
                r_state <= STATE_CLEAR;
                r_counter <= (others => '0');
                r_source <= (others => '0');
                r_subtest <= (others => '0');
                r_test_passed <= '0';
                r_test_failed <= '0';
                r_raw_data_s <= (others => '0');
                r_raw_data_d <= (others => '0');
                r_hist_index <= (others => '0');
                r_hist_value <= (others => '0');
                r_hist_min <= (others => '1');
                r_hist_max <= (others => '0');
                r_chisquared_value <= (others => '0');
            else

                -- FSM
                v_state_next := r_state;
                v_counter_next := r_counter;
                v_histogram_wdata := (others => '0');
                v_histogram_wen := '0';
                case r_state is

                    when STATE_CLEAR =>

                        -- increment counter
                        if r_counter(7 downto 0) = 255 then
                            v_state_next := STATE_COUNT;
                            v_counter_next := (others => '0');
                        else
                            v_counter_next := r_counter + 1;
                        end if;

                        -- clear test registers
                        r_hist_min <= (others => '1');
                        r_hist_max <= (others => '0');
                        r_chisquared_value <= (others => '0');

                        -- clear histogram value
                        v_histogram_wen := '1';

                    when STATE_COUNT =>

                        -- increment counter
                        if r_counter = 65535 then
                            v_state_next := STATE_PROCESS;
                            v_counter_next := (others => '0');
                        else
                            v_counter_next := r_counter + 1;
                        end if;

                        -- increment histogram value
                        v_incremented := resize(r_hist_value, 10) + 1;
                        if v_incremented(9) = '1' then
                            r_test_passed <= '0';
                            r_test_failed <= '1';
                            v_histogram_wdata := (others => '1');
                        else
                            v_histogram_wdata := v_incremented(8 downto 0);
                        end if;
                        v_histogram_wen := '1';

                    when STATE_PROCESS =>

                        -- increment counter
                        if r_counter(7 downto 0) = 255 then
                            v_state_next := STATE_DONE;
                            v_counter_next := (others => '0');
                        else
                            v_counter_next := r_counter + 1;
                        end if;

                        -- check that histogram values are within tolerance
                        if r_hist_value < 112 or r_hist_value >= 448 then
                            r_test_passed <= '0';
                            r_test_failed <= '1';
                        end if;

                        -- update histogram min/max
                        if r_hist_value < r_hist_min then
                            r_hist_min <= r_hist_value;
                        end if;
                        if r_hist_value > r_hist_max then
                            r_hist_max <= r_hist_value;
                        end if;

                        -- update chi-squared value
                        v_chisquared_temp := resize(r_chisquared_value, 13) + c_square(to_integer(r_hist_value(8 downto 1)));
                        if v_chisquared_temp(12) = '1' then
                            r_test_passed <= '0';
                            r_test_failed <= '1';
                            r_chisquared_value <= (others => '1');
                        else
                            r_chisquared_value <= v_chisquared_temp(11 downto 0);
                        end if;

                    when STATE_DONE =>

                        -- check that chi-squared value is within tolerance
                        if r_chisquared_value >= 3584 then
                            v_state_next := STATE_HALT;
                            r_test_passed <= '0';
                            r_test_failed <= '1';
                        else
                            v_state_next := STATE_CLEAR;
                            if r_source < 2 then
                                r_source <= r_source + 1;
                            else
                                r_source <= (others => '0');
                                r_subtest <= r_subtest + 1;
                                if r_subtest = 3 then
                                    r_test_passed <= '1';
                                end if;
                            end if;
                        end if;

                    when STATE_HALT =>
                        -- do nothing

                end case;
                r_state <= v_state_next;
                r_counter <= v_counter_next;

                -- write to memory
                if v_histogram_wen = '1' then
                    r_hist_value <= v_histogram_wdata;
                    r_histogram(to_integer(r_hist_index)) <= v_histogram_wdata;
                end if;

                -- input preprocessing
                case r_source is
                    when "00" =>
                        r_raw_data_s <= raw_data_a;
                    when "01" =>
                        r_raw_data_s <= raw_data_b;
                    when others =>
                        r_raw_data_s <= raw_data_c;
                end case;
                r_raw_data_d <= r_raw_data_s;
                case r_subtest is
                    when "00" =>
                        v_preprocessed(0) := r_raw_data_s(0) xor r_raw_data_d(0);
                        v_preprocessed(1) := r_raw_data_d(1) xor r_raw_data_s(1);
                        v_preprocessed(2) := r_raw_data_d(2) xor r_raw_data_s(2);
                        v_preprocessed(3) := r_raw_data_s(3) xor r_raw_data_d(3);
                        v_preprocessed(4) := r_raw_data_d(4) xor r_raw_data_s(4);
                        v_preprocessed(5) := r_raw_data_s(5) xor r_raw_data_d(5);
                        v_preprocessed(6) := r_raw_data_s(6) xor r_raw_data_d(6);
                        v_preprocessed(7) := r_raw_data_d(7) xor r_raw_data_s(7);
                    when "01" =>
                        v_preprocessed(0) := r_raw_data_s(0) xor r_raw_data_s(1);
                        v_preprocessed(1) := r_raw_data_d(1) xor r_raw_data_d(0);
                        v_preprocessed(2) := r_raw_data_d(2) xor r_raw_data_d(3);
                        v_preprocessed(3) := r_raw_data_s(3) xor r_raw_data_s(2);
                        v_preprocessed(4) := r_raw_data_d(4) xor r_raw_data_d(5);
                        v_preprocessed(5) := r_raw_data_s(5) xor r_raw_data_s(4);
                        v_preprocessed(6) := r_raw_data_s(6) xor r_raw_data_s(7);
                        v_preprocessed(7) := r_raw_data_d(7) xor r_raw_data_d(6);
                    when "10" =>
                        v_preprocessed(0) := r_raw_data_s(0) xor r_raw_data_s(2);
                        v_preprocessed(1) := r_raw_data_d(1) xor r_raw_data_d(3);
                        v_preprocessed(2) := r_raw_data_d(2) xor r_raw_data_d(0);
                        v_preprocessed(3) := r_raw_data_s(3) xor r_raw_data_s(1);
                        v_preprocessed(4) := r_raw_data_d(4) xor r_raw_data_d(6);
                        v_preprocessed(5) := r_raw_data_s(5) xor r_raw_data_s(7);
                        v_preprocessed(6) := r_raw_data_s(6) xor r_raw_data_s(4);
                        v_preprocessed(7) := r_raw_data_d(7) xor r_raw_data_d(5);
                    when "11" =>
                        v_preprocessed(0) := r_raw_data_s(0) xor r_raw_data_s(4);
                        v_preprocessed(1) := r_raw_data_d(1) xor r_raw_data_d(5);
                        v_preprocessed(2) := r_raw_data_d(2) xor r_raw_data_d(6);
                        v_preprocessed(3) := r_raw_data_s(3) xor r_raw_data_s(7);
                        v_preprocessed(4) := r_raw_data_d(4) xor r_raw_data_d(0);
                        v_preprocessed(5) := r_raw_data_s(5) xor r_raw_data_s(1);
                        v_preprocessed(6) := r_raw_data_s(6) xor r_raw_data_s(2);
                        v_preprocessed(7) := r_raw_data_d(7) xor r_raw_data_d(3);
                    when others => -- to keep simulation happy (X, U, ...)
                end case;

                -- determine next address
                if v_state_next = STATE_COUNT then
                    v_hist_index_next := unsigned(v_preprocessed);
                else
                    v_hist_index_next := unsigned(v_counter_next(7 downto 0));
                end if;

                -- read from memory if necessary
                if v_hist_index_next /= r_hist_index then
                    r_hist_index <= v_hist_index_next;
                    r_hist_value <= r_histogram(to_integer(v_hist_index_next));
                end if;

            end if;
        end if;
    end process;

end rtl;
