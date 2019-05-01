library ieee, modelsim_lib;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use modelsim_lib.util.all;
library orthrus;
use orthrus.Constants.all;

entity RegisterFileTB is
end RegisterFileTB;

architecture TB of RegisterFileTB is
    signal clk :   std_logic := '0';
    signal reset :   std_logic := '0';

    -- Port 1 signals
    signal read_1, write_1 :   std_logic := '0';
    signal sel_read_1  :   std_logic_vector(2 downto 0) := (others => '0');
    signal sel_write_1 :   std_logic_vector(2 downto 0) := (others => '0');
    signal data_in_1   :   std_logic_vector(15 downto 0) := (others => '0');
    signal data_out_1  :   std_logic_vector(15 downto 0) := (others => '0');

    -- Port 2 signals
    signal read_2, write_2 :   std_logic := '0';
    signal sel_read_2  :   std_logic_vector(2 downto 0) := (others => '0');
    signal sel_write_2 :   std_logic_vector(2 downto 0) := (others => '0');
    signal data_in_2   :   std_logic_vector(15 downto 0) := (others => '0');
    signal data_out_2  :   std_logic_vector(15 downto 0) := (others => '0');
    
    begin
        reg_file_inst : entity orthrus.RegisterFile
            port map (
                clk => clk, 
                reset => reset,
                read_1 => read_1, 
                write_1 => write_1,
                sel_read_1 => sel_read_1, 
                sel_write_1 => sel_write_1,
                data_in_1 => data_in_1, 
                data_out_1 => data_out_1,
                read_2 => read_2, 
                write_2 => write_2,
                sel_read_2 => sel_read_2, 
                sel_write_2 => sel_write_2,
                data_in_2 => data_in_2, 
                data_out_2 => data_out_2
            );

        process is
            begin
                reset <= '1';
                wait for CLK_PERIOD;
                reset <= '0';
                write_1 <= '1';
                sel_write_1 <= "010";
                data_in_1 <= X"0123";
                write_1 <= '1';
                sel_write_2 <= "110";
                data_in_2 <= X"ABCD";
                write_2 <= '1';
                wait for CLK_PERIOD;
                write_1 <= '1';
                sel_write_1 <= "011";
                data_in_1 <= X"6789";
                write_2 <= '1';
                sel_write_2 <= "111";
                data_in_2 <= X"4567";
                read_1 <= '1';
                sel_read_1 <= "010";
                read_2 <= '1';
                sel_read_2 <= "110";
                wait for CLK_PERIOD;
                assert(data_out_1 = X"0123") report "Writing/Reading register 010 failed!";
                assert(data_out_2 = X"ABCD") report "Writing/Reading register 110 failed!";
                write_1 <= '1';
                sel_write_1 <= "000";
                data_in_1 <= X"0125";
                write_2 <= '1';
                sel_write_2 <= "000";
                data_in_2 <= X"FEDC";
                read_1 <= '1';
                sel_read_1 <= "011";
                read_2 <= '1';
                sel_read_2 <= "111";
                wait for CLK_PERIOD;
                assert(data_out_1 = X"6789") report "Writing/Reading register 010 failed!";
                assert(data_out_2 = X"4567") report "Writing/Reading register 110 failed!";
                wait for CLK_PERIOD;
                data_in_1 <= (others => '0');
                data_in_2 <= (others => '0');
                write_1 <= '0';
                write_2 <= '0';
                read_1 <= '1';
                sel_read_1 <= "000";
                read_2 <= '0';
                wait for CLK_PERIOD;
                assert(data_out_1 = X"FEDC") report "Prioritizing input 2 failed!";
                assert(data_out_2 = X"0000") report "Output not zero when read is zero!";
            end process;

        process is
            begin
                clk <= '0';
                wait for CLK_PERIOD / 2;
                clk <= '1';
                wait for CLK_PERIOD / 2;
            end process;
end TB;