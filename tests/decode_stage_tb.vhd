library ieee;
use ieee.std_logic_1164.all;
library orthrus;
use orthrus.Constants.all;

entity DecodeStageTB is
end DecodeStageTB;

architecture TB of DecodeStageTB is
    signal clk, reset, stall : std_logic := '0';
    signal sp_write : std_logic := '0';
    signal sp_data_in : std_logic_vector(M-1 downto 0) := (others => '0');

    signal rf_write_1, rf_write_2 : std_logic := '0';
    signal rf_write_1_addr, rf_write_2_addr : std_logic_vector(2 downto 0) := (others => '0');
    signal rf_data_in_1, rf_data_in_2 : std_logic_vector(M-1 downto 0) := (others => '0');

    signal inport_data_in : std_logic_vector(M-1 downto 0) := (others => '1');

    signal IR1, IR2 : std_logic_vector(2*N-1 downto 0) := (others => '0');
    signal new_pc : std_logic_vector(M-1 downto 0) := (others => '0');

    signal zero_flag, negative_flag, carry_flag : std_logic := '0';

    -- Stage outputs
    signal branch : std_logic;
    signal branch_address : std_logic_vector(M-1 downto 0);

    signal control_word_1, control_word_2 : std_logic_vector(2*N-1 downto 0);
    signal RT1, RS1, RT2, RS2 : std_logic_vector(N-1 downto 0);

    signal push_addr_1, push_addr_2 : std_logic_vector(M-1 downto 0);

    constant period : time := CLK_PERIOD;
begin
    DecodeStage_inst : entity orthrus.DecodeStage
        port map (
            clk => clk,
            reset => reset,
            stall => stall,
            -- sp_write => sp_write,
            -- sp_data_in => sp_data_in,
            rf_write_1 => rf_write_1,
            rf_write_1_addr => rf_write_1_addr,
            rf_data_in_1 => rf_data_in_1,
            rf_write_2 => rf_write_2,
            rf_write_2_addr => rf_write_2_addr,
            rf_data_in_2 => rf_data_in_2,
            inport_data_in => inport_data_in,
            IR1 => IR1,
            IR2 => IR2, 
            new_pc => new_pc,
            zero_flag => zero_flag,
            negative_flag => negative_flag,
            carry_flag => carry_flag,
            take_addr => '0',
            branch_forwarded_addr => (M-1 downto 0 => '0'),
            branch => branch,
            branch_address => branch_address,
            control_word_1 => control_word_1,
            RT1 => RT1, RS1 => RS1,
            control_word_2 => control_word_2,
            RT2 => RT2, RS2 => RS2,
            push_addr_1 => push_addr_1,
            push_addr_2 => push_addr_2
        );

    process is
    begin
        reset <= '1';
        wait for period / 2;
        reset <= '0';
        wait for period / 2;
        IR1 <= INST_NOP & (10 downto 0 => '0') & (15 downto 0 => '0');
        IR2 <= INST_NOT & "010" & (7 downto 0 => '0') & (15 downto 0 => '0');
        rf_write_1 <= '1';
        rf_write_1_addr <= "000";
        rf_data_in_1 <= X"1234";
        rf_write_2 <= '1';
        rf_write_2_addr <= "010";
        rf_data_in_2 <= X"422D";
        wait for period;
        assert(control_word_1 = (31 downto 0 => '0')) report "NOP is decoded incorrectly!";
        assert(control_word_2(31 downto 28) = ALUOP_NOT) report "NOT ALU Op is wrong!";
        assert(control_word_2(27 downto 25) = "010") report "NOT Register addr is wrong!";
        assert(RT2 = X"422D") report "RT2 for NOT is incorrect!";
        rf_write_1 <= '1';
        rf_write_1_addr <= "100";
        rf_data_in_1 <= X"21FF";
        rf_write_2 <= '0';
        IR1 <= INST_ADD & "000" & "100" & "00000" & (15 downto 0 => '0');
        IR2 <= INST_SHR & "010" & "000" & "0101" & "0" & (15 downto 0 => '0');
        wait for period;
        assert(control_word_1(31 downto 28) = ALUOP_ADD) report "ADD ALU Op is wrong!";
        assert(control_word_1(24 downto 22) = "000") report "RS addr for ADD is incorrect!";
        assert(RS1 = X"1234") report "RS for ADD is incorrect!";
        assert(control_word_1(27 downto 25) = "100") report "RT addr for ADD is incorrect!";
        assert(RT1 = X"21FF") report "RT for ADD is incorrect!";
        assert(control_word_2(31 downto 28) = ALUOP_SHR) report "SHR ALU Op is wrong!";
        assert(control_word_2(27 downto 25) = "010") report "RT addr for SHR is incorrect!";
        assert(RT2 = X"422D") report "RT for SHR is incorrect!";
        assert(control_word_2(6 downto 3) = "0101") report "ShiftAmount for SHR is incorrect!";
        rf_write_1 <= '1';
        rf_write_1_addr <= "110";
        rf_data_in_1 <= X"FEAC";
        IR1 <= INST_LDM & "111" & "000" & "00000" & X"9BAC";
        IR2 <= INST_STD & "110" & "100" & "00000" & (15 downto 0 => '0');
        wait for period;
        rf_write_1 <= '0';
        assert(control_word_1(31 downto 28) = ALUOP_PASSB) report "LDM ALU Op is wrong!";
        assert(control_word_1(27 downto 25) = "111") report "LDM load address is wrong!";
        assert(RT1 = X"9BAC") report "LDM RT is incorrect!";
        assert(control_word_2(31 downto 28) = ALUOP_PASSA) report "STD ALU Op is wrong!";
        assert(control_word_2(27 downto 25) = "100") report "RT Address for STD is wrong!";
        assert(RT2 = X"21FF") report "RT value for STD is wrong!";
        assert(control_word_2(24 downto 22) = "110") report "RS Address for STD is wrong!";
        assert(RS2 = X"FEAC") report "RS value for STD is wrong!";
        wait for period;
        wait for period * 10;
    end process;

    process is
    begin
        clk <= '0';
        wait for period / 2;
        clk <= '1';
        wait for period / 2;
    end process;
end TB;