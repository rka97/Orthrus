library ieee, modelsim_lib;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use modelsim_lib.util.all;
library orthrus;
use orthrus.Constants.all;

entity FetchStageTB is
end FetchStageTB;

architecture TB of FetchStageTB is
    signal clk, reset, stall, interrupt : std_logic := '0';
    signal branch, wpc1_write, wpc2_write : std_logic := '0';
    signal read_mem, write_mem : std_logic;
    signal address, branch_address : std_logic_vector(15 downto 0);
    signal data_into_mem : std_logic_vector(31 downto 0);
    signal data_outof_mem : std_logic_vector(31 downto 0);
    signal IR1, IR2 : std_logic_vector(31 downto 0);
    signal new_pc : std_logic_vector(15 downto 0);
    signal ir1_op : std_logic_vector(4 downto 0);
    signal ir2_op : std_logic_vector(4 downto 0);
    constant period : time := 1 ns;
begin
    ir1_op <= IR1(31 downto 31-5+1);
    ir2_op <= IR2(31 downto 31-5+1);
    ram_inst : entity orthrus.ram
        port map (
            clk => clk,
            read_in => read_mem,
            write_in => write_mem,
            write_double_in => '0',
            address_in => address,
            data_in => data_into_mem,
            data_out => data_outof_mem
        );
    
    FetchStage_inst : entity orthrus.FetchStage
        port map (
            clk => clk,
            reset => reset,
            read_mem => read_mem,
            mem_data_in => data_outof_mem,
            mem_address_out => address,
            stall => stall,
            interrupt => interrupt,
            branch => branch,
            branch_address => branch_address,
            wpc1_write => wpc1_write,
            wpc2_write => wpc2_write,
            IR1 => IR1,
            IR2 => IR2,
            new_pc => new_pc
        );
    
    process is
    begin
        -- RAM should be loaded up with OneOperand.mem.
        reset <= '1';
        wait for period / 2; -- ASUMPTION: the reset is latched and lifted off the processor only on the RISING edge of the clock. 
        reset <= '0';
        wait for period;
        assert (ir1_op = INST_SETC) report "IR1 is wrong for STC! value = " & integer'image(to_integer(unsigned(IR1(31 downto 31-5+1))));
        assert(ir2_op = INST_NOP) report "IR2 is wrong for NOP!";
        assert(new_pc = X"000C") report "new_pc is wrong!";
        wait for period;
        assert(ir1_op = INST_CLRC) report "IR2 is wrong for CLRC!";
        assert(ir2_op = INST_NOT) report "IR2 is wrong for NOT1";
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