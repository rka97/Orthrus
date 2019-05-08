library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library orthrus;

entity ControlHazardUnit is
    generic (
        N      : natural := 16; -- number of bits in word.
        M      : natural := 16;  -- number of bits in memory address.
        L_BITS : natural := 3 -- log2(Number of registers)
    );

    port (
        -- In from DEC BUFFER/STAGE -------------
        branch       : in std_logic; --branch is always in first pipe
        dec_rt_code1 : in std_logic_vector(L_BITS-1 downto 0);
        
        -- In from EX BUFFER -------------
        --pipe1
        ex_rt_code1 : in std_logic_vector(L_BITS-1 downto 0);
        ex_WBreg1   : in std_logic;
        ex_mem_op1  : in std_logic;
        ex_out1     : in std_logic_vector(N-1 downto 0);
        ex_rt_code2 : in std_logic_vector(L_BITS-1 downto 0);
        ex_WBreg2   : in std_logic;
        ex_mem_op2  : in std_logic;
        ex_out2     : in std_logic_vector(N-1 downto 0);

        -- In from MEM BUFFER -------------
        -- pipe 1
        mem_WBreg1   : in std_logic; -- Is this op going to WB?
        mem_rt_code1 : in std_logic_vector(L_BITS-1 downto 0); -- code of dest Reg
        mem_AR1      : in std_logic_vector(N-1 downto 0);
        mem_writePC1 : in std_logic;
        mem_mem_op1  : in std_logic;
        --pip2
        mem_WBreg2   : in std_logic; -- Is this op going to WB?
        mem_rt_code2 : in std_logic_vector(L_BITS-1 downto 0); -- code of dest Reg
        mem_AR2      : in std_logic_vector(N-1 downto 0);
        mem_writePC2 : in std_logic;
        mem_mem_op2  : in std_logic;

        -- In from WB BUFFER -------------
        --pipe 1
        wb_WBreg1   : in std_logic;
        wb_rt_code1 : in std_logic_vector(L_BITS-1 downto 0);
        wb_AR1      : in std_logic_vector(N-1 downto 0);
        --pipe 2
        wb_WBreg2   : in std_logic;
        wb_rt_code2 : in std_logic_vector(L_BITS-1 downto 0);
        wb_AR2      : in std_logic_vector(N-1 downto 0);
    
        -- Out to Buffers -------------
        --pipe1
        stall_d        : out std_logic := 'Z';
        stall_e        : out std_logic := 'Z';
        stall_m        : out std_logic := 'Z';
        flush_e        : out std_logic := 'Z'; --Flush needs to be on edge
        flush_d        : out std_logic := 'Z';
        flush_d2       : out std_logic := 'Z';
        input_cw_ex_z  : out std_logic := 'Z';
        input_cw_mem_z : out std_logic := 'Z';

        ---Out to decode stage branch -------------
        take_addr  : out std_logic := 'Z';
        branch_add : out std_logic_vector(N-1 downto 0) := (others => 'Z')
    );
 end ControlHazardUnit;

 architecture bhv of ControlHazardUnit is
    -- 3   1   -1  
    -- 4   2   0
    begin   
        control_haz_rt: process(mem_writePC1,mem_writePC2)
        begin
            if mem_writePC1='1' or mem_writePC2='1' then
                flush_d<='1';
                flush_e<='1';
            end if;
        end process;

        control_haz_br: process(branch,dec_rt_code1,ex_rt_code2,ex_WBreg2,ex_mem_op1,
            ex_out1,ex_rt_code1,ex_WBreg1,ex_mem_op2,
            mem_rt_code2,mem_WBreg2,mem_mem_op2,mem_rt_code1,mem_WBreg1,mem_mem_op1,mem_AR2,mem_AR1,
            wb_rt_code2,wb_WBreg2,wb_AR2,wb_rt_code1,wb_WBreg1,wb_AR1)
        begin
            if branch='1'  then
                flush_d2<='1'; --only flush decode 2 buffer
                if dec_rt_code1=ex_rt_code2 and ex_WBreg2='1' and ex_mem_op2='1' then 
                    stall_d<='1';
                    input_cw_ex_z<='1';
                    take_addr<='0';
                    stall_e<='0';
                    input_cw_mem_z<='0';
                elsif dec_rt_code1=ex_rt_code2 and ex_WBreg2='1' then
                    branch_add<=ex_out2;
                    take_addr<='1';
                    stall_d<='0';
                    input_cw_ex_z<='0';
                    input_cw_mem_z<='0';
                    stall_e<='0';
                elsif dec_rt_code1=ex_rt_code1 and ex_WBreg1='1' and ex_mem_op1='1' then 
                    stall_d<='1';
                    input_cw_ex_z<='1';
                    take_addr<='1';
                    stall_e<='0';
                    input_cw_mem_z<='0';
                elsif dec_rt_code1=ex_rt_code1 and ex_WBreg1='1' then
                    branch_add<=ex_out1; 
                    stall_d<='0';
                    stall_e<='0';
                    input_cw_ex_z<='0';
                    input_cw_mem_z<='0';
                    take_addr<='1';
                elsif dec_rt_code1=mem_rt_code2 and mem_WBreg2='1' and  mem_mem_op2='1' then --and not (stalled_o='1')  then
                    stall_d<='1';
                    stall_e<='1';
                    input_cw_mem_z<='1';
                    take_addr<='0';
                    input_cw_ex_z<='0';
                elsif dec_rt_code1=mem_rt_code2 and mem_WBreg2='1' then
                    branch_add<=mem_AR2;
                    take_addr<='1';
                    input_cw_ex_z<='0';
                    input_cw_mem_z<='0';
                    stall_e<='0';
                    stall_d<='0';
                elsif dec_rt_code1=mem_rt_code1 and mem_WBreg1='1' and  mem_mem_op1='1' then--and not (stalled_o='1')  then
                    stall_d<='1';
                    stall_e<='1';
                    take_addr<='0';
                    input_cw_ex_z<='0';
                    input_cw_mem_z<='1';
                elsif dec_rt_code1=mem_rt_code1 and mem_WBreg1='1' then
                    branch_add<=mem_AR1;
                    input_cw_ex_z<='0';
                    take_addr<='1';
                    stall_d<='0';
                    stall_e<='0';
                    input_cw_mem_z<='0';
                elsif dec_rt_code1=wb_rt_code2 and wb_WBreg2='1' then
                    branch_add<=wb_AR2;
                    input_cw_ex_z<='0';
                    take_addr<='1';
                    stall_d<='0';
                    stall_e<='0';
                    input_cw_mem_z<='0';
                elsif dec_rt_code1=wb_rt_code1 and wb_WBreg1='1' then
                    branch_add<=wb_AR1;
                    input_cw_ex_z<='0';
                    take_addr<='1';
                    stall_d<='0';
                    stall_e<='0';
                    input_cw_mem_z<='0';
                else
                    branch_add<=(others => 'Z');
                    take_addr <='0';
                    stall_d <= '0';
                    stall_e <= '0';
                    stall_m <= '0';
                    flush_e <= '0'; 
                    flush_d <= '0';
                    input_cw_ex_z <= '0';
                    input_cw_mem_z <= '0';
                end if;
            else
                flush_d2<='0';
            end if;
        end process;         
    end bhv;