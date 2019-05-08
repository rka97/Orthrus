library ieee, modelsim_lib;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use modelsim_lib.util.all;
library orthrus;
use orthrus.Constants.all;

entity ProcessorTB is
end ProcessorTB;

architecture TB of ProcessorTB is
    signal clk, reset, interrupt : std_logic := '0';

    signal read_mem, write_mem, write_double_mem : std_logic := '0';
    signal mem_address : std_logic_vector(15 downto 0);
    signal data_into_mem : std_logic_vector(31 downto 0);
    signal data_outof_mem : std_logic_vector(31 downto 0);
    signal inport_data, outport_data : std_logic_vector(15 downto 0) := (others => 'Z');

    signal IR1_buffered, IR2_buffered : std_logic_vector(31 downto 0);
    signal IR1_short, IR2_short : std_logic_vector(15 downto 0);
    signal new_pc_buff_dec : std_logic_vector(M-1 downto 0);

    signal zero_flag, negative_flag, carry_flag : std_logic;

    signal branch : std_logic;
    signal branch_address : std_logic_vector(M-1 downto 0);

    signal cw_1_buff_ex, cw_2_buff_ex : std_logic_vector(2*N-1 downto 0);
    signal RT1_buff_ex, RS1_buff_ex, RT2_buff_ex, RS2_buff_ex : std_logic_vector(N-1 downto 0);
    signal push_addr_1_buff_ex, push_addr_2_buff_ex, new_pc_buff_ex : std_logic_vector(M-1 downto 0);

    signal cw_1_buff_mem, cw_2_buff_mem : std_logic_vector(2*N-1 downto 0);
    signal A1Res_buff_mem, A2Res_buff_mem, RT1_buff_mem, RT2_buff_mem : std_logic_vector(N-1 downto 0);
    signal push_addr_1_buff_mem, push_addr_2_buff_mem, new_pc_buff_mem : std_logic_vector(M-1 downto 0);
    -- signal 

    constant period : time := 1 ns;

    begin
        IR1_short <= IR1_buffered(31 downto 16);
        IR2_short <= IR2_buffered(31 downto 16);
        Processor_inst : entity orthrus.Processor
        port map (
            clk => clk,
            reset => reset,
            
            interrupt => interrupt,
            inport_data_in => inport_data,
            out_port_data_out => outport_data,
            mem_data_in => data_outof_mem,
            mem_data_out => data_into_mem,
            mem_address_out => mem_address,
            read_mem => read_mem,
            write_mem => write_mem,
            write_double_mem => write_double_mem
        );
    
        ram_inst : entity orthrus.ram
            port map (
                clk => clk,
                read_in => read_mem,
                write_in => write_mem,
                write_double_in => write_double_mem,
                address_in => mem_address,
                data_in => data_into_mem,
                data_out => data_outof_mem
            );
        
        process is
        begin
            -- ASSUMPTION: SimpleTest.mem should be loaded in by the do file.
            init_signal_spy("/processortb/Processor_inst/branch", "/processortb/branch");
            init_signal_spy("/processortb/Processor_inst/branch_address", "/processortb/branch_address");

            init_signal_spy("/processortb/Processor_inst/IR1_buffered", "processortb/IR1_buffered");
            init_signal_spy("/processortb/Processor_inst/IR2_buffered", "processortb/IR2_buffered");
            init_signal_spy("/processortb/Processor_inst/new_pc_buff_dec", "processortb/new_pc_buff_dec");

            init_signal_spy("/processortb/Processor_inst/cw_1_buff_ex", "processortb/cw_1_buff_ex");
            init_signal_spy("/processortb/Processor_inst/RT1_buff_ex", "processortb/RT1_buff_ex");
            init_signal_spy("/processortb/Processor_inst/RS1_buff_ex", "processortb/RS1_buff_ex");
            init_signal_spy("/processortb/Processor_inst/push_addr_1_buff_ex", "processortb/push_addr_1_buff_ex");
            init_signal_spy("/processortb/Processor_inst/cw_2_buff_ex", "processortb/cw_2_buff_ex");
            init_signal_spy("/processortb/Processor_inst/RT2_buff_ex", "processortb/RT2_buff_ex");
            init_signal_spy("/processortb/Processor_inst/RS2_buff_ex", "processortb/RS2_buff_ex");
            init_signal_spy("/processortb/Processor_inst/push_addr_2_buff_ex", "processortb/push_addr_2_buff_ex");
            init_signal_spy("/processortb/Processor_inst/new_pc_buff_ex", "processortb/new_pc_buff_ex");

            init_signal_spy("/processortb/Processor_inst/cw_1_buff_mem", "processortb/cw_1_buff_mem");
            init_signal_spy("/processortb/Processor_inst/A1Res_buff_mem", "processortb/A1Res_buff_mem");
            init_signal_spy("/processortb/Processor_inst/RT1_buff_mem", "processortb/RT1_buff_mem");
            init_signal_spy("/processortb/Processor_inst/push_addr_1_buff_mem", "processortb/push_addr_1_buff_mem");
            init_signal_spy("/processortb/Processor_inst/cw_2_buff_mem", "processortb/cw_2_buff_mem");
            init_signal_spy("/processortb/Processor_inst/A2Res_buff_mem", "processortb/A2Res_buff_mem");
            init_signal_spy("/processortb/Processor_inst/RT2_buff_mem", "processortb/RT2_buff_mem");
            init_signal_spy("/processortb/Processor_inst/push_addr_2_buff_mem", "processortb/push_addr_2_buff_mem");
            init_signal_spy("/processortb/Processor_inst/new_pc_buff_mem", "processortb/new_pc_buff_mem");

            init_signal_spy("/processortb/Processor_inst/zero_flag", "processortb/zero_flag");
            init_signal_spy("/processortb/Processor_inst/carry_flag", "processortb/carry_flag");
            init_signal_spy("/processortb/Processor_inst/negative_flag", "processortb/negative_flag");

            reset <= '1';
            wait for period / 2;
            reset <= '1';
            wait for period / 2;
            reset <= '0';
            -- Fetching started
            wait for period * 7;
            wait for period; -- For the delay in values being available
            assert(IR1_short = INST_JMP & "111" & (7 downto 0 => '0')) report "IR1 != JMP R7!";
            assert(IR2_short = INST_NOP & (10 downto 0 => '0')) report "IR2 != NOP!";
            assert(branch = '1') report "Branch != 1!";
            assert(branch_address = X"0080") report "Branch address != 128!";
            wait for period;
            assert(IR1_short = INST_NOP & (10 downto 0 => '0')) report "IR1 != NOP after branching!";
            -- assert(IR1_short = INST_INC & "110" & (7 downto 0 => '0')) report "IR1 != INC R6!";
            assert(IR2_short = INST_NOP & (10 downto 0 => '0')) report "IR2 != NOP!";
            wait for period;
            assert(IR1_buffered = INST_LDM & "000" & "00000000" & X"00C9") report "IR1 != LDM R0, 201!";
            wait for period;
            assert(IR1_buffered = INST_LDM & "001" & "00000000" & X"0005") report "IR1 != LDM R1, 5!";
            assert(RT1_buff_ex = X"00C9") report "RT_ex for LDM R0, 201 is wrong!";
            wait for period;
            assert(IR1_buffered = INST_LDM & "010" & "00000000" & X"00C8") report "IR1 != LDM R2, 200!";
            assert(RT1_buff_ex = X"0005") report "RT_ex for LDM R1, 5 is wrong!";
            assert(RT1_buff_mem = X"00C9") report "RT_mem for LDM R0, 201 is wrong!";
            wait for period;
            -- LDD in decode
            inport_data <= X"F127";
            assert(IR1_short = INST_IN & "011" & (7 downto 0 => '0')) report "IR1 != IN R3";
            assert(IR2_short = INST_LDD & "100" & "101" & "00000") report "IR2 != LDD R4, R5!!";
            assert(RT1_buff_ex = X"00C8") report "RT_ex for LDM R2, 200 is wrong!";
            assert(RT1_buff_mem = X"0005") report "RT_mem for LDM R1, 5 is wrong!";
            wait for period;
            -- LDD in execute
            inport_data <= X"FFFF";
            assert(IR1_short = INST_NOP & (10 downto 0 => '0')) report "IR1 != NOP!";
            assert(IR2_short = INST_NOP & (10 downto 0 => '0')) report "IR2 != NOP!";
            assert(RT1_buff_ex = X"F127") report "IN to RT1 failed!";
            wait for period;
            assert(mem_address = (M-1 downto 0 => '0')) report "LDD from 0 failed!";
            -- LDD In MEM
            assert(IR1_short = INST_NOP & (10 downto 0 => '0')) report "IR1 != NOP!";
            assert(IR2_short = INST_NOP & (10 downto 0 => '0')) report "IR2 != NOP!";
            -- ADD In Fetch
            wait for period;
            -- LDD In WB
            -- ADD In Decode
            wait for period;
            -- Add In Execute
            assert(IR1_short = INST_ADD & "001" & "000" & "00000") report "IR1 != ADD R1, R0!";
            assert(IR2_short = INST_NOP & (10 downto 0 => '0')) report "IR2 != NOP!";
            wait for period;
            -- Add In MEM
            assert(IR1_short = INST_NOP & (10 downto 0 => '0')) report "IR1 != NOP!";
            assert(IR2_short = INST_SUB & "000" & "010" & "00000") report "IR2 != SUB R0, R2!";
            assert(cw_1_buff_ex(31 downto 28) = ALUOP_ADD and cw_1_buff_ex(27 downto 25) = "000" and cw_1_buff_ex(24 downto 22) = "001" and cw_1_buff_ex(9) = '1') report "CW for ADD R1, R0 is wrong!";
            -- assert(RT1_buff_ex = X"00C9") report "RT_ex for ADD R1, R0 is wrong!";
            -- assert(RS1_buff_ex = X"0005") report "RS for ADD R1, R0 is wrong!";
            wait for period;
            -- Add In WB
            assert(IR1_short = INST_NOT & "001" & (7 downto 0 => '0')) report "IR1 != NOT R1!";
            assert(cw_2_buff_ex(31 downto 28) = ALUOP_SUB and cw_2_buff_ex(27 downto 25) = "010" and cw_2_buff_ex(24 downto 22) = "000" and cw_2_buff_ex(9) = '1') report "CW for SUB R0, R2 is wrong!";
            wait for period;
            -- Ad Done
            wait for period * 200;
        end process;
        
        process is
        begin
            clk <= '0';
            wait for period / 2;
            clk <= '1';
            wait for period / 2;
        end process;
end TB;