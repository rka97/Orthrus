library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library orthrus;


entity RAWHazardUnit is
  
    generic (
        N : natural := 16;
        M : natural := 16;
        L_BITS : natural := 3;
        buffer_unit : natural := 32
        );


        port (
        --- In from EX
        -- pipe 1
        ex_rs_code1 : in std_logic_vector(L_BITS-1 downto 0);
        ex_rt_code1 : in std_logic_vector(L_BITS-1 downto 0);
        ex_WBreg1: in std_logic; --signal in cw1 for wb
        ex_out1: in std_logic_vector(N-1 downto 0); --out of ex unit1(NOT OUT OF ARES REG)
        -- pipe 2
        ex_rs_code2 : in std_logic_vector(L_BITS-1 downto 0);
        ex_rt_code2 : in std_logic_vector(L_BITS-1 downto 0);
        ex_WBreg2: in std_logic;
        ex_out2: in std_logic_vector(N-1 downto 0);

        ---- IN from memory buffer.
        -- pipe1
        mem_WBreg1 : in std_logic;
        mem_rt_code1:  in std_logic_vector(L_BITS-1 downto 0);
        mem_op_r1  : in std_logic;
        mem_AR1     : in std_logic_vector(N-1 downto 0); --Ares reg in mem buffer 1
        mem_op_w1 : in std_logic; --raised push or std only!!!!
        -- pipe2
        mem_WBreg2 : in std_logic;
        mem_rt_code2:  in std_logic_vector(L_BITS-1 downto 0);
        mem_op_r2  : in std_logic;
        mem_AR2   : in std_logic_vector(N-1 downto 0);
        mem_op_w2 : in std_logic; 

        ----- IN from writeback buffer.
        wb_mdata    : in std_logic_vector(buffer_unit-1 downto 0);
        -- pipe1
        wb_WBreg1   : in std_logic;
        wb_rt_code1:in std_logic_vector(L_BITS-1 downto 0);
        wb_AR1    : in std_logic_vector(N-1 downto 0);
        wb_mem_op1  :in std_logic; --accessed memory as read 
         -- pipe2
        wb_WBreg2  : in std_logic;
        wb_rt_code2:in std_logic_vector(L_BITS-1 downto 0);
        wb_AR2    : in std_logic_vector(N-1 downto 0);
        wb_mem_op2  :in std_logic;

        ---- OUT to buffers.
        stall_DandE : out std_logic; --Will stall (as in preserve val of) decode and execute bbuffers
        input_mem_cw_z: out std_logic;-- input into memory cw a NOP . (use mux as this signal for sel)

        ---- OUT to ex unit 
        load_forwarded_rs1 : out std_logic; --To decide what data will be used, standard or forwared
        load_forwarded_rs2 : out std_logic;
        load_forwarded_rt1 : out std_logic;
        load_forwarded_rt2 : out std_logic;
        load_forwarded_mdata1 : out std_logic;
        load_forwarded_mdata2 : out std_logic;

        ex_rs1: out std_logic_vector(N-1 downto 0); --actual data forwarded
        ex_rt1: out std_logic_vector(N-1 downto 0);
        ex_rs2: out std_logic_vector(N-1 downto 0);
        ex_rt2: out std_logic_vector(N-1 downto 0);
        mem_data1: out std_logic_vector(buffer_unit-1 downto 0);
        mem_data2: out std_logic_vector(buffer_unit-1 downto 0)

    );

end RAWHazardUnit;

architecture struct of RAWHazardUnit is
    --pipe 1 rs
    signal  stall_DandEs1        : std_logic;
    signal input_mem_cw_zs1 : std_logic;
    -- pipe 1 rt
    signal stall_DandEt1        : std_logic;
    signal input_mem_cw_zt1 :std_logic;
    --pipe 2 rs
    signal stall_DandEs2        : std_logic;
    signal input_mem_cw_zs2 :std_logic;
    -- pipe 2 rt
    signal stall_DandEt2        : std_logic;
    signal input_mem_cw_zt2 :std_logic;


    begin

    --- MEM-WB RAW hazzards
    --pipe 1
    mem_wb_hz_1: process(mem_op_w1,mem_rt_code1,wb_rt_code2,wb_rt_code1,wb_AR1,wb_AR2,wb_WBreg2,wb_WBreg1)
    begin
        if mem_op_w1='1' and mem_rt_code1=wb_rt_code2 and wb_WBreg2='1' then
            load_forwarded_mdata1<='1';
            mem_data1 <=(buffer_unit-1 downto N=>'0')&wb_AR2(N-1 downto 0);
        elsif mem_op_w1='1' and mem_rt_code1=wb_rt_code1 and wb_WBreg1='1' then
            load_forwarded_mdata1<='1';
            mem_data1<=(buffer_unit-1 downto N=>'0')& wb_AR1(N-1 downto 0);
        else
            mem_data1 <=(others=>'0');
            load_forwarded_mdata1<='0';
        end if;
    end process;
     --pipe 2
     mem_wb_hz_2: process(mem_op_w2,mem_rt_code2,wb_rt_code2,wb_rt_code1,wb_AR1,wb_AR2,wb_WBreg2,wb_WBreg1)
     begin
         if mem_op_w2='1' and mem_rt_code2=wb_rt_code1 and wb_WBreg1='1' then
             load_forwarded_mdata2<='1';
             mem_data2<= (buffer_unit-1 downto N=>'0')&wb_AR1(N-1 downto 0);
         elsif mem_op_w2='1' and mem_rt_code2=wb_rt_code2 and wb_WBreg2='1' then
             load_forwarded_mdata2<='1';
             mem_data2<= (buffer_unit-1 downto N=>'0')&wb_AR2(N-1 downto 0);
         else
             mem_data2 <=(others=>'0');
             load_forwarded_mdata2<='0';
         end if;
     end process;


    ----- EX RAW hazzards

    stall_DandE<=   '1' when stall_DandEs1 ='1' or stall_DandEt1 ='1' or stall_DandEs2 ='1' or stall_DandEt2 ='1' else
                    '0';

    input_mem_cw_z<=    '1' when input_mem_cw_zs1 ='1' or input_mem_cw_zt1 ='1' or input_mem_cw_zs2 ='1' or input_mem_cw_zt2 ='1' else
                        '0';
        
        
    -- PIPE 1--
    raw_haz_comp_s1 : entity orthrus.RAWHazardComponent 
    port map(
        i_am_pipe => '0',
        ex_r_code => ex_rs_code1, 
        ex_rt_code_otherpipe => ex_rt_code2,
        ex_WBreg_otherpipe => ex_WBreg2,
        ex_out_otherpipe => ex_out2,
        mem_WBreg_mypipe => mem_WBreg1,
        mem_rt_code_mypipe=> mem_rt_code1,
        mem_op_r_mypipe   => mem_op_r1,
        mem_AR_mypipe     => mem_AR1,
        mem_WBreg_otherpipe  => mem_WBreg2, 
        mem_rt_code_otherpipe=> mem_rt_code2,
        mem_op_r_otherpipe   => mem_op_r2, 
        mem_AR_otherpipe     => mem_AR2,
        wb_mdata    => wb_mdata,
        wb_WBreg_mypipe   => wb_WBreg1,
        wb_rt_code_mypipe => wb_rt_code1,
        wb_AR_mypipe      => wb_AR1,
        wb_mem_op_mypipe  => wb_mem_op1,
        wb_WBreg_otherpipe   => wb_WBreg2,
        wb_rt_code_otherpipe => wb_rt_code2,
        wb_AR_otherpipe      => wb_AR2,
        wb_mem_op_otherpipe  => wb_mem_op2,
        stall_DandE     => stall_DandEs1,
        input_mem_cw_z => input_mem_cw_zs1, 
        load_forwarded => load_forwarded_rs1,
        ex_r=> ex_rs1
    );

    raw_haz_comp_t1 : entity orthrus.RAWHazardComponent 
    port map(
        i_am_pipe => '0',
        ex_r_code => ex_rt_code1, 
        ex_rt_code_otherpipe => ex_rt_code2,
        ex_WBreg_otherpipe => ex_WBreg2,
        ex_out_otherpipe => ex_out2,
        mem_WBreg_mypipe => mem_WBreg1,
        mem_rt_code_mypipe=> mem_rt_code1,
        mem_op_r_mypipe   => mem_op_r1,
        mem_AR_mypipe     => mem_AR1,
        mem_WBreg_otherpipe  => mem_WBreg2, 
        mem_rt_code_otherpipe=> mem_rt_code2,
        mem_op_r_otherpipe   => mem_op_r2, 
        mem_AR_otherpipe     => mem_AR2,
        wb_mdata    => wb_mdata,
        wb_WBreg_mypipe   => wb_WBreg1,
        wb_rt_code_mypipe => wb_rt_code1,
        wb_AR_mypipe      => wb_AR1,
        wb_mem_op_mypipe  => wb_mem_op1,
        wb_WBreg_otherpipe   => wb_WBreg2,
        wb_rt_code_otherpipe => wb_rt_code2,
        wb_AR_otherpipe      => wb_AR2,
        wb_mem_op_otherpipe  => wb_mem_op2,
        stall_DandE     => stall_DandEt1,
        input_mem_cw_z=> input_mem_cw_zt1, 
        load_forwarded => load_forwarded_rt1,
        ex_r=> ex_rt1
    );

    -- PIPE 2--
    raw_haz_comp_s2 : entity orthrus.RAWHazardComponent 
    port map(
        i_am_pipe => '1',
        ex_r_code => ex_rs_code2, 
        ex_rt_code_otherpipe => ex_rt_code1,
        ex_WBreg_otherpipe => ex_WBreg1,
        ex_out_otherpipe => ex_out1,
        mem_WBreg_mypipe => mem_WBreg2,
        mem_rt_code_mypipe=> mem_rt_code2,
        mem_op_r_mypipe   => mem_op_r2,
        mem_AR_mypipe     => mem_AR2,
        mem_WBreg_otherpipe  => mem_WBreg1, 
        mem_rt_code_otherpipe=> mem_rt_code1,
        mem_op_r_otherpipe   => mem_op_r1, 
        mem_AR_otherpipe     => mem_AR1,
        wb_mdata    => wb_mdata,
        wb_WBreg_mypipe   => wb_WBreg2,
        wb_rt_code_mypipe => wb_rt_code2,
        wb_AR_mypipe      => wb_AR2,
        wb_mem_op_mypipe  => wb_mem_op2,
        wb_WBreg_otherpipe   => wb_WBreg1,
        wb_rt_code_otherpipe => wb_rt_code1,
        wb_AR_otherpipe      => wb_AR1,
        wb_mem_op_otherpipe  => wb_mem_op1,
        stall_DandE     => stall_DandEs2,
        input_mem_cw_z=> input_mem_cw_zs2, 
        load_forwarded => load_forwarded_rs2,
        ex_r=> ex_rs2
    );

    raw_haz_comp_t2 : entity orthrus.RAWHazardComponent 
    port map(
        i_am_pipe => '1',
        ex_r_code => ex_rt_code2, 
        ex_rt_code_otherpipe => ex_rt_code1,
        ex_WBreg_otherpipe => ex_WBreg1,
        ex_out_otherpipe => ex_out1,
        mem_WBreg_mypipe => mem_WBreg2,
        mem_rt_code_mypipe=> mem_rt_code2,
        mem_op_r_mypipe   => mem_op_r2,
        mem_AR_mypipe     => mem_AR2,
        mem_WBreg_otherpipe  => mem_WBreg1, 
        mem_rt_code_otherpipe=> mem_rt_code1,
        mem_op_r_otherpipe   => mem_op_r1, 
        mem_AR_otherpipe     => mem_AR1,
        wb_mdata    => wb_mdata,
        wb_WBreg_mypipe   => wb_WBreg2,
        wb_rt_code_mypipe => wb_rt_code2,
        wb_AR_mypipe      => wb_AR2,
        wb_mem_op_mypipe  => wb_mem_op2,
        wb_WBreg_otherpipe   => wb_WBreg1,
        wb_rt_code_otherpipe => wb_rt_code1,
        wb_AR_otherpipe      => wb_AR1,
        wb_mem_op_otherpipe  => wb_mem_op1,
        stall_DandE     => stall_DandEt2,
        input_mem_cw_z=> input_mem_cw_zt2, 
        load_forwarded => load_forwarded_rt2,
        ex_r=> ex_rt2
    );




end struct;