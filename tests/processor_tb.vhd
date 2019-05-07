library ieee, modelsim_lib;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use modelsim_lib.util.all;
library orthrus;
use orthrus.Constants.all;

entity ProcessorTB is
end ProcessorTB;

architecture TB of ProcessorTB is
    signal clk, reset, interrupt : std_logic := 'Z';

    signal read_mem, write_mem, write_mem_mode : std_logic := 'Z';
    signal mem_address : std_logic_vector(15 downto 0);
    signal data_into_mem : std_logic_vector(31 downto 0);
    signal data_outof_mem : std_logic_vector(31 downto 0);
    signal inport_data : std_logic_vector(15 downto 0) := (others => 'Z');

    signal IR1_buffered, IR2_buffered : std_logic_vector(31 downto 0);
    signal IR1_short, IR2_short : std_logic_vector(15 downto 0);
    signal new_pc_buffered : std_logic_vector(M-1 downto 0);

    signal branch : std_logic;
    signal branch_address : std_logic_vector(M-1 downto 0);

    signal cw_1_buffered, cw_2_buffered : std_logic_vector(2*N-1 downto 0);
    signal RT1_buff, RS1_buff, RT2_buff, RS2_buff : std_logic_vector(N-1 downto 0);
    signal push_addr_1_buff, push_addr_2_buff : std_logic_vector(M-1 downto 0);

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

            mem_data_in => data_outof_mem,
            mem_data_out => data_into_mem,
            mem_address_out => mem_address,
            read_mem => read_mem,
            write_mem => write_mem,
            write_mem_mode => write_mem_mode
        );
    
        -- TODO: give the RAM a single word vs double word mode.
        ram_inst : entity orthrus.ram
            port map (
                clk => clk,
                read_in => read_mem,
                write_in => write_mem,
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
            init_signal_spy("/processortb/Processor_inst/new_pc_buffered", "processortb/new_pc_buffered");

            init_signal_spy("/processortb/Processor_inst/cw_1_buffered", "processortb/cw_1_buffered");
            init_signal_spy("/processortb/Processor_inst/RT1_buff", "processortb/RT1_buff");
            init_signal_spy("/processortb/Processor_inst/RS1_buff", "processortb/RS1_buff");
            init_signal_spy("/processortb/Processor_inst/push_addr_1_buff", "processortb/push_addr_1_buff");
            init_signal_spy("/processortb/Processor_inst/cw_2_buffered", "processortb/cw_2_buffered");
            init_signal_spy("/processortb/Processor_inst/RT2_buff", "processortb/RT2_buff");
            init_signal_spy("/processortb/Processor_inst/RS2_buff", "processortb/RS2_buff");
            init_signal_spy("/processortb/Processor_inst/push_addr_2_buff", "processortb/push_addr_2_buff");
            reset <= '1';
            wait for period / 2;
            reset <= '0';
            wait for period / 2;
            -- Fetching started
            wait for period;
            assert(IR1_short = INST_JMP & "111" & (7 downto 0 => '0')) report "IR1 != JMP R7!";
            assert(IR2_short = INST_NOP & (10 downto 0 => '0')) report "IR2 != NOP!";
            assert(branch = '1') report "Branch != 1!";
            assert(branch_address = (M-1 downto 0 => '0')) report "Branch address != 0!";
            wait for period;
            assert(IR1_short = INST_NOP & (10 downto 0 => '0')) report "IR1 != NOP after branching!";
            -- assert(IR1_short = INST_INC & "110" & (7 downto 0 => '0')) report "IR1 != INC R6!";
            assert(IR2_short = INST_NOP & (10 downto 0 => '0')) report "IR2 != NOP!";
            wait for period;
            assert(IR1_buffered = INST_LDM & "000" & "00000000" & X"00C9") report "IR1 != LDM R0, 201!";
            wait for period;
            assert(IR1_buffered = INST_LDM & "001" & "00000000" & X"0005") report "IR1 != LDM R1, 5!";
            assert(RT1_buff = X"00C9") report "RT for LDM R0, 201 is wrong!";
            wait for period;
            assert(IR1_buffered = INST_LDM & "010" & "00000000" & X"00C8") report "IR1 != LDM R2, 200!";
            assert(RT1_buff = X"0005") report "RT for LDM R1, 5 is wrong!";
            wait for period;
            inport_data <= X"F127";
            assert(IR1_short = INST_IN & "011" & (7 downto 0 => '0')) report "IR1 != IN R3, 7";
            assert(IR2_short = INST_NOP & (10 downto 0 => '0')) report "IR2 != NOP, Pre!!";
            assert(RT1_buff = X"00C8") report "RT for LDM R2, 200 is wrong!";
            wait for period;  -- Four NOPs are next!
            inport_data <= X"FFFF";
            assert(IR1_short = INST_NOP & (10 downto 0 => '0')) report "IR1 != NOP!";
            assert(IR2_short = INST_NOP & (10 downto 0 => '0')) report "IR2 != NOP!";
            assert(RT1_buff = X"F127") report "IN to RT1 failed!";
            wait for period;
            assert(IR1_short = INST_NOP & (10 downto 0 => '0')) report "IR1 != NOP!";
            assert(IR2_short = INST_NOP & (10 downto 0 => '0')) report "IR2 != NOP!";
            wait for period;
            assert(IR1_short = INST_ADD & "001" & "000" & "00000") report "IR1 != ADD R1, R0!";
            assert(IR2_short = INST_NOP & (10 downto 0 => '0')) report "IR2 != NOP!";
            wait for period;
            assert(IR1_short = INST_NOP & (10 downto 0 => '0')) report "IR1 != NOP!";
            assert(IR2_short = INST_SUB & "000" & "010" & "00000") report "IR2 != SUB R0, R2!";
            assert(cw_1_buffered(31 downto 28) = ALUOP_ADD and cw_1_buffered(27 downto 25) = "000" and cw_1_buffered(24 downto 22) = "001" and cw_1_buffered(9) = '1') report "CW for ADD R1, R0 is wrong!";
            -- assert(RT1_buff = X"00C9") report "RT for ADD R1, R0 is wrong!";
            -- assert(RS1_buff = X"0005") report "RS for ADD R1, R0 is wrong!";
            wait for period;
            assert(IR1_short = INST_NOT & "001" & (7 downto 0 => '0')) report "IR1 != NOT R1!";
            assert(cw_2_buffered(31 downto 28) = ALUOP_SUB and cw_2_buffered(27 downto 25) = "010" and cw_2_buffered(24 downto 22) = "000" and cw_2_buffered(9) = '1') report "CW for SUB R0, R2 is wrong!";
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