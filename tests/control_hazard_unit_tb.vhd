library ieee;
use ieee.std_logic_1164.all;
library orthrus;
use orthrus.Constants.all;

entity HazardUnitTB is
end HazardUnitTB;

architecture TB of HazardUnitTB is
    
    signal branch1, ex_WBreg1, ex_mem_op1, ex_mem_op2, ex_WBreg2 : std_logic := 'Z';
    signal mem_WBreg1, mem_WBreg2, mem_writePC1, mem_writePC2, mem_mem_op1, mem_mem_op2 : std_logic := 'Z';
    signal wb_WBreg1, wb_WBreg2 :std_logic := 'Z';
    signal dec_rt_code1, ex_rt_code1, ex_rt_code2 : std_logic_vector(2 downto 0):= (others => 'Z');
    signal mem_rt_code1, mem_rt_code2, wb_rt_code1, wb_rt_code2 : std_logic_vector(2 downto 0) := (others => 'Z');
    signal ex_out1, ex_out2, mem_AR1, mem_AR2, wb_AR1, wb_AR2, branch_add : std_logic_vector(15 downto 0) := (others => 'Z');
    signal stall_d ,stall_e, stall_m, flush_e, flush_d, flush_d2, input_cw_ex_z, input_cw_mem_z, take_addr : std_logic := 'Z';

    constant period : time := 1 ns;

    begin
        hazard_unit_inst : entity orthrus.ControlHazardUnit
            port map (
                -- In from DEC BUFFER/STAGE -------------
                branch => branch1,
                dec_rt_code1 => dec_rt_code1,
                
                -- In from EX BUFFER -------------
                --pipe1
                ex_rt_code1 => ex_rt_code1,
                ex_WBreg1 => ex_WBreg1,
                ex_mem_op1 => ex_mem_op1,
                ex_out1 => ex_out1,
                ex_rt_code2 => ex_rt_code2,
                ex_WBreg2 => ex_WBreg2,
                ex_mem_op2 => ex_mem_op2,
                ex_out2 => ex_out2,

                -- In from MEM BUFFER -------------
                -- pipe 1
                mem_WBreg1 => mem_WBreg1,
                mem_rt_code1 => mem_rt_code1,
                mem_AR1 => mem_AR1,
                mem_writePC1 => mem_writePC1,
                mem_mem_op1 => mem_mem_op1,
                --pip2
                mem_WBreg2 => mem_WBreg2,
                mem_rt_code2 => mem_rt_code2,
                mem_AR2 => mem_AR2,
                mem_writePC2 => mem_writePC2,
                mem_mem_op2 => mem_mem_op2,

                -- In from WB BUFFER -------------
                --pipe 1
                wb_WBreg1 => wb_WBreg1,
                wb_rt_code1 => wb_rt_code1,
                wb_AR1 => wb_AR1,
                --pipe 2
                wb_WBreg2 => wb_WBreg2,
                wb_rt_code2 => wb_rt_code2,
                wb_AR2 => wb_AR2,
            
                -- Out to Buffers -------------
                --pipe1
                stall_d => stall_d,
                stall_e => stall_e,
                stall_m => stall_m,
                flush_e => flush_e,
                flush_d => flush_d,
                flush_d2 => flush_d2,
                input_cw_ex_z => input_cw_ex_z,
                input_cw_mem_z => input_cw_mem_z,

                ---Out to decode stage branch -------------
                take_addr => take_addr,
                branch_add => branch_add
            );      

        process is
        begin
            branch1 <= '1';
            dec_rt_code1 <= "000";

            ex_rt_code1 <= "001";
            ex_WBreg1 <= '1';
            ex_mem_op1 <= '0';
            ex_out1 <= x"0006";
            ex_rt_code2 <= "010";  --garbage
            ex_WBreg2 <= '0';  --garbage
            ex_mem_op2 <= '0';  --garbage
            ex_out2 <= x"0000";  --garbage
              --garbage
            mem_WBreg1 <= '0';
            mem_rt_code1 <= "000";
            mem_AR1 <= x"0000";
            mem_writePC1 <= '0';
            mem_mem_op1 <= '0';
            mem_WBreg2 <= '0';
            mem_rt_code2 <= "000";
            mem_AR2 <= x"0000";
            mem_writePC2 <= '0';
            mem_mem_op2 <= '0';

            wb_WBreg1 <= '1';
            wb_rt_code1 <= "101";
            wb_AR1 <= x"0004";
            wb_WBreg2 <= '0';
            wb_rt_code2 <= "000";
            wb_AR2 <= x"0003";
            wait for period;
            assert( stall_d='0' and stall_e='0' and stall_m='0'and  flush_e='0' and flush_d='0' and flush_d2='1' and input_cw_ex_z='0' and input_cw_mem_z='0' and take_addr='0') report "faild in the simple case!";
            
            wb_WBreg1 <= '1';
            wb_rt_code1 <= "000";
            wb_AR1 <= x"0004";
            wb_WBreg2 <= '0'; --garbage
            wb_rt_code2 <= "000";
            wb_AR2 <= x"0003";
            wait for period;
            assert( stall_d='0' and stall_e='0' and stall_m='0'and  flush_e='0' and flush_d='0' and flush_d2='1' and input_cw_ex_z='0' and input_cw_mem_z='0' and take_addr='1') report "faild in the simple case!";
            assert( branch_add = wb_AR1) report "address is not from write back!";
            
            mem_WBreg1 <= '0';
            mem_rt_code1 <= "011";
            mem_AR1 <= x"0000";
            mem_writePC1 <= '0';
            mem_mem_op1 <= '1';
            mem_WBreg2 <= '0';--garbage
            mem_rt_code2 <= "000";
            mem_AR2 <= x"0000";
            mem_writePC2 <= '0';
            mem_mem_op2 <= '0';

            wb_WBreg1 <= '0';
            wb_rt_code1 <= "101";
            wb_AR1 <= x"0004";
            wb_WBreg2 <= '0';
            wb_rt_code2 <= "000";
            wb_AR2 <= x"0003";
            wait for period;
            assert( stall_d='0' and stall_e='0' and stall_m='0'and  flush_e='0' and flush_d='0' and flush_d2='1' and input_cw_ex_z='0' and input_cw_mem_z='0' and take_addr='0') report "faild in the simple case!";
               
            wb_WBreg1 <= '0';
            wb_rt_code1 <= "101";
            wb_AR1 <= x"0004";
            wb_WBreg2 <= '1';
            wb_rt_code2 <= "000";
            wb_AR2 <= x"0002";
            wait for period;
            assert( stall_d='0' and stall_e='0' and stall_m='0'and  flush_e='0' and flush_d='0' and flush_d2='1' and input_cw_ex_z='0' and input_cw_mem_z='0' and take_addr='1') report "faild in the simple case!";
            assert( branch_add = wb_AR2) report "failed in talking address from WB";
            
            mem_WBreg1 <= '1';
            mem_rt_code1 <= "000";
            mem_AR1 <= x"0006";
            mem_writePC1 <= '0';
            mem_mem_op1 <= '1';
            mem_WBreg2 <= '0';--garbage
            mem_rt_code2 <= "000";
            mem_AR2 <= x"0000";
            mem_writePC2 <= '0';
            mem_mem_op2 <= '0';
            wait for period;
            assert( stall_d='1' and stall_e='1' and stall_m='0'and  flush_e='0' and flush_d='0' and flush_d2='1' and input_cw_ex_z='0' and input_cw_mem_z='1' and take_addr='0') report "faild in stall to take addr from memory!";           

            wb_WBreg1 <= '0';
            wb_rt_code1 <= "101";
            wb_AR1 <= x"0004";
            wb_WBreg2 <= '0';
            wb_rt_code2 <= "000";
            wb_AR2 <= x"0003";
            wait for period;
            assert( stall_d='1' and stall_e='1' and stall_m='0'and  flush_e='0' and flush_d='0' and flush_d2='1' and input_cw_ex_z='0' and input_cw_mem_z='1' and take_addr='0') report "faild in stall to take addr from memory!";
               
            ex_rt_code1 <= "001";
            ex_WBreg1 <= '1';
            ex_mem_op1 <= '0';
            ex_out1 <= x"0006";
            ex_rt_code2 <= "000"; 
            ex_WBreg2 <= '1'; 
            ex_mem_op2 <= '0'; 
            ex_out2 <= x"0070"; 

            mem_WBreg1 <= '0';
            mem_rt_code1 <= "000";
            mem_AR1 <= x"0000";
            mem_writePC1 <= '0';
            mem_mem_op1 <= '0';
            mem_WBreg2 <= '0';
            mem_rt_code2 <= "000";
            mem_AR2 <= x"0000";
            mem_writePC2 <= '0';
            mem_mem_op2 <= '0';

            wb_WBreg1 <= '0';
            wb_rt_code1 <= "101";
            wb_AR1 <= x"0004";
            wb_WBreg2 <= '0';
            wb_rt_code2 <= "000";
            wb_AR2 <= x"0003";
            wait for period;
            assert( stall_d='0' and stall_e='0' and stall_m='0'and  flush_e='0' and flush_d='0' and flush_d2='1' and input_cw_ex_z='0' and input_cw_mem_z='0' and take_addr='1') report "faild in the simple case!";
            assert( branch_add = ex_out2) report "failed in talking address from ALU";
           
            mem_WBreg1 <= '1';
            mem_rt_code1 <= "101";
            mem_AR1 <= x"0000";
            mem_writePC1 <= '0';
            mem_mem_op1 <= '1';
            mem_WBreg2 <= '0';
            mem_rt_code2 <= "000";
            mem_AR2 <= x"0000";
            mem_writePC2 <= '0';
            mem_mem_op2 <= '0';
            wait for period;
            assert( stall_d='1' and stall_e='0' and stall_m='0'and  flush_e='0' and flush_d='0' and flush_d2='1' and input_cw_ex_z='1' and input_cw_mem_z='0' and take_addr='1') report "faild in the simple case!";
            assert( branch_add = ex_out2) report "failed in talking address from ALU";
           
            mem_WBreg1 <= '0';
            mem_rt_code1 <= "000";
            mem_AR1 <= x"0000";
            mem_writePC1 <= '0';
            mem_mem_op1 <= '0';
            mem_WBreg2 <= '0';
            mem_rt_code2 <= "000";
            mem_AR2 <= x"0000";
            mem_writePC2 <= '0';
            mem_mem_op2 <= '0';

            wb_WBreg1 <= '1';
            wb_rt_code1 <= "101";
            wb_AR1 <= x"0004";
            wb_WBreg2 <= '0';
            wb_rt_code2 <= "000";
            wb_AR2 <= x"0003";
            wait for period;
            assert( stall_d='1' and stall_e='0' and stall_m='0'and  flush_e='0' and flush_d='0' and flush_d2='1' and input_cw_ex_z='1' and input_cw_mem_z='0' and take_addr='1') report "faild in the simple case!";
            assert( branch_add = ex_out2) report "failed in talking address from ALU";
           
            wb_WBreg1 <= '1';
            wb_rt_code1 <= "000";
            wb_AR1 <= x"0004";
            wb_WBreg2 <= '0';
            wb_rt_code2 <= "000";
            wb_AR2 <= x"0003";
            wait for period;
            assert( stall_d='1' and stall_e='0' and stall_m='0'and  flush_e='0' and flush_d='0' and flush_d2='1' and input_cw_ex_z='1' and input_cw_mem_z='0' and take_addr='1') report "faild in the simple case!";
            assert( branch_add = ex_out2) report "failed in talking address from ALU";
        
        end process;
end TB;