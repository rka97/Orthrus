library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library orthrus;


entity WriteBackUnit is
    generic (
        N   : natural := 16; -- number of bits in word
        M   : natural := 16  -- number of bits in memory address
    );
    port (
        -- memory signals
        mem_data            : in std_logic_vector(N-1 downto 0);

        -- control signals
        control_word       : in std_logic_vector(31 downto 0);
      
        -- the IRs and new_pc
        alu_res           : in std_logic_vector(N-1 downto 0);
        to_out_port       : out std_logic_vector(N-1 downto 0);
        to_rf_write_data  : out std_logic_vector(N-1 downto 0);
        to_rf_write       : out std_logic;
        to_rf_write_sel   : out std_logic_vector(2 downto 0)
    );
end WriteBackUnit;

architecture Behavioral of WriteBackUnit is
    signal out_op : std_logic;
    signal WBreg  : std_logic;
    signal push_op : std_logic;
    signal pop_op  : std_logic;
    signal rti_op  : std_logic;
    signal ret_op  : std_logic;
    signal int_op  : std_logic;
    signal call_op : std_logic;
    signal load_op : std_logic;

    begin
        out_op <= control_word(20);
        WBreg <= control_word(21);
        push_op <= control_word(19);
        pop_op <= control_word(18);
        rti_op <= control_word(14);  -- both rti and ret are the same?
        ret_op <= control_word(14);
        int_op <= control_word(12);
        call_op <= control_word(15);
        load_op <= control_word(17);

        
        wb_process : process(WBreg, load_op, out_op, alu_res, control_word, mem_data)
        begin
            if WBreg = '1' and load_op = '0' then
                to_rf_write <= '1';
                to_rf_write_data <= alu_res;
                to_rf_write_sel <= control_word(27 downto 25);
            elsif WBreg = '1' and load_op = '1' then
                to_rf_write <= '1';
                to_rf_write_data <= mem_data;
                to_rf_write_sel <= control_word(27 downto 25);
            else
		        to_rf_write <= '0';
                to_rf_write_data <= (others =>'0');
                to_rf_write_sel <= (others => '0');
	        end if;
            if out_op = '1' then
                to_out_port <= alu_res;
	        else
		        to_out_port <= (others => '0');
	        end if;
        end process;
end Behavioral;
            





