
library ieee;
use ieee.std_logic_1164.all;
library orthrus;

entity tb_RAWHazardUnit is
end tb_RAWHazardUnit;

architecture tb of tb_RAWHazardUnit is

    signal ex_rs_code1           : std_logic_vector (2 downto 0);
    signal ex_rt_code1           : std_logic_vector (2 downto 0);
    signal ex_WBreg1             : std_logic;
    signal ex_out1               : std_logic_vector (15 downto 0);
    signal ex_rs_code2           : std_logic_vector (2 downto 0);
    signal ex_rt_code2           : std_logic_vector (2 downto 0);
    signal ex_WBreg2             : std_logic;
    signal ex_out2               : std_logic_vector (15 downto 0);
    signal mem_WBreg1            : std_logic;
    signal mem_rt_code1          : std_logic_vector (2 downto 0);
    signal mem_op_r1             : std_logic;
    signal mem_AR1               : std_logic_vector (15 downto 0);
    signal mem_op_w1             : std_logic;
    signal mem_WBreg2            : std_logic;
    signal mem_rt_code2          : std_logic_vector (2 downto 0);
    signal mem_op_r2             : std_logic;
    signal mem_AR2               : std_logic_vector (15 downto 0);
    signal mem_op_w2             : std_logic;
    signal wb_mdata              : std_logic_vector (31 downto 0);
    signal wb_WBreg1             : std_logic;
    signal wb_rt_code1           : std_logic_vector (2 downto 0);
    signal wb_AR1                : std_logic_vector (15 downto 0);
    signal wb_mem_op1            : std_logic;
    signal wb_WBreg2             : std_logic;
    signal wb_rt_code2           : std_logic_vector (2 downto 0);
    signal wb_AR2                : std_logic_vector (15 downto 0);
    signal wb_mem_op2            : std_logic;
    signal stall_DandE           : std_logic;
    signal input_mem_cw_z        : std_logic;
    signal load_forwarded_rs1    : std_logic;
    signal load_forwarded_rs2    : std_logic;
    signal load_forwarded_rt1    : std_logic;
    signal load_forwarded_rt2    : std_logic;
    signal load_forwarded_mdata1 : std_logic;
    signal load_forwarded_mdata2 : std_logic;
    signal ex_rs1                : std_logic_vector (15 downto 0);
    signal ex_rt1                : std_logic_vector (15 downto 0);
    signal ex_rs2                : std_logic_vector (15 downto 0);
    signal ex_rt2                : std_logic_vector (15 downto 0);
    signal mem_data1              : std_logic_vector (31 downto 0);
    signal mem_data2             : std_logic_vector (31 downto 0);

    constant period : time := 1 ns;
begin

    dut : entity orthrus.RAWHazardUnit
    port map (ex_rs_code1           => ex_rs_code1,
              ex_rt_code1           => ex_rt_code1,
              ex_WBreg1             => ex_WBreg1,
              ex_out1               => ex_out1,
              ex_rs_code2           => ex_rs_code2,
              ex_rt_code2           => ex_rt_code2,
              ex_WBreg2             => ex_WBreg2,
              ex_out2               => ex_out2,
              mem_WBreg1            => mem_WBreg1,
              mem_rt_code1          => mem_rt_code1,
              mem_op_r1             => mem_op_r1,
              mem_AR1               => mem_AR1,
              mem_op_w1             => mem_op_w1,
              mem_WBreg2            => mem_WBreg2,
              mem_rt_code2          => mem_rt_code2,
              mem_op_r2             => mem_op_r2,
              mem_AR2               => mem_AR2,
              mem_op_w2             => mem_op_w2,
              wb_mdata              => wb_mdata,
              wb_WBreg1             => wb_WBreg1,
              wb_rt_code1           => wb_rt_code1,
              wb_AR1                => wb_AR1,
              wb_mem_op1            => wb_mem_op1,
              wb_WBreg2             => wb_WBreg2,
              wb_rt_code2           => wb_rt_code2,
              wb_AR2                => wb_AR2,
              wb_mem_op2            => wb_mem_op2,
              stall_DandE           => stall_DandE,
              input_mem_cw_z        => input_mem_cw_z,
              load_forwarded_rs1    => load_forwarded_rs1,
              load_forwarded_rs2    => load_forwarded_rs2,
              load_forwarded_rt1    => load_forwarded_rt1,
              load_forwarded_rt2    => load_forwarded_rt2,
              load_forwarded_mdata1 => load_forwarded_mdata1,
              load_forwarded_mdata2 => load_forwarded_mdata2,
              ex_rs1                => ex_rs1,
              ex_rt1                => ex_rt1,
              ex_rs2                => ex_rs2,
              ex_rt2                => ex_rt2,
              mem_data1              => mem_data1,
              mem_data2             => mem_data2);

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        ex_rs_code1 <= (others => '0');
        ex_rt_code1 <= (others => '0');
        ex_WBreg1 <= '0';
        ex_out1 <= (others => '0');
        ex_rs_code2 <= (others => '0');
        ex_rt_code2 <= (others => '0');
        ex_WBreg2 <= '0';
        ex_out2 <= (others => '0');
        mem_WBreg1 <= '0';
        mem_rt_code1 <= (others => '0');
        mem_op_r1 <= '0';
        mem_AR1 <= (others => '0');
        mem_op_w1 <= '0';
        mem_WBreg2 <= '0';
        mem_rt_code2 <= (others => '0');
        mem_op_r2 <= '0';
        mem_AR2 <= (others => '0');
        mem_op_w2 <= '0';
        wb_mdata <= (others => '0');
        wb_WBreg1 <= '0';
        wb_rt_code1 <= (others => '0');
        wb_AR1 <= (others => '0');
        wb_mem_op1 <= '0';
        wb_WBreg2 <= '0';
        wb_rt_code2 <= (others => '0');
        wb_AR2 <= (others => '0');
        wb_mem_op2 <= '0';
        wait for period;
        -- EDIT Add stimuli here

        --mem-wb hazrad situation! pip1 note, both loaads could be raised. but wouldn't stay on, no mem op
        mem_rt_code1 <= "001"; ---- 1
        mem_op_w1 <= '1';  ---- 1
        wb_WBreg1 <= '1'; ------------x
        wb_rt_code1 <= "001";-------------x
        wb_AR1 <= x"0007";-----------x
        wb_WBreg2 <= '1';---- 1
        wb_rt_code2 <="001"; ---- 1
        wb_AR2 <= x"0004"; ---- 1
        wait for period;
        --- 1
        assert( load_forwarded_mdata1='1' and mem_data1=x"00000004") report "P1 mem-wb haz, first cond not met";
        mem_rt_code1 <= "001"; ---- 1
        mem_op_w1 <= '1';  ---- 1
        wb_WBreg1 <= '1'; ------------x
        wb_rt_code1 <= "001";-------------x
        wb_AR1 <= x"0007";-----------x
        wb_WBreg2 <= '0';---- 1
        wb_rt_code2 <="001"; ---- 1
        wb_AR2 <= x"0004"; ---- 1
        wait for period;
        --- x
        assert( load_forwarded_mdata1='1' and mem_data1=x"00000007") report "P1 mem-wb haz, second cond not met";
        --pipe2
        mem_rt_code2 <= "001"; ---- 1
        mem_op_w2 <= '1';  ---- 1
        wb_WBreg1 <= '1'; ------------x
        wb_rt_code1 <= "001";-------------x
        wb_AR1 <= x"0007";-----------x
        wb_WBreg2 <= '1';---- 1
        wb_rt_code2 <="001"; ---- 1
        wb_AR2 <= x"0004"; ---- 1
        wait for period;
        --- 1
        assert( load_forwarded_mdata2='1' and mem_data2=x"00000007") report "P2 mem-wb haz, first cond not met";
        mem_rt_code1 <= "001"; ---- 1
        mem_op_w1 <= '1';  ---- 1
        wb_WBreg1 <= '0'; ------------x
        wb_rt_code1 <= "001";-------------x
        wb_AR1 <= x"0007";-----------x
        wb_WBreg2 <= '1';---- 1
        wb_rt_code2 <="001"; ---- 1
        wb_AR2 <= x"0004"; ---- 1
        wait for period;
        --- x
        assert( load_forwarded_mdata2='1' and mem_data2=x"00000004") report "P2 mem-wb haz, second cond not met";
        wait for period;

        --mem-wb hazrad situation! pip1
          -- EDIT Add stimuli here
        ex_rs_code1 <= "001";
        ex_rt_code1 <= "000";
        mem_WBreg2 <= '1';
        mem_rt_code2 <= "001";
        mem_AR2 <= x"FFFF";
        wait for period;
        assert ex_rs1 = x"FFFF" and load_forwarded_rs1 = '1' report " Error in ex-mem between two pipes.";
        ex_rs_code1 <= "010";
        ex_rt_code1 <= "000";
        mem_WBreg2 <= '0';
        mem_WBreg1 <= '1';
        mem_rt_code1 <= "010";
        mem_AR1 <= x"FFF8";
        wait for period;
        assert ex_rs1 = x"FFF8" and load_forwarded_rs1 = '1' report " Error in ex-mem in the same pipe.";
        ex_rs_code1 <= "001";
        ex_rt_code1 <= "000";
        wb_WBreg2 <= '1';
        mem_WBreg1 <= '0';
        wb_rt_code2 <= "001";
        wb_AR2 <= x"BBBB";
        wait for period ;
        assert ex_rs1 = x"BBBB" and load_forwarded_rs1 = '1' report " Error in ex-wb between two pipes.";
        ex_rs_code1 <= "001";
        ex_rt_code1 <= "000";
        wb_WBreg2 <= '0';
        wb_WBreg1 <= '1';
        wb_rt_code1 <= "001";
        wb_AR1 <= x"BBBB";
        wait for period;
        assert ex_rs1 = x"BBBB" and load_forwarded_rs1 = '1' report "Error in ex-wb in the same pipe.";
        --- between rs and rt in pipe 1
        ex_rs_code1 <= "010";
        ex_rt_code1 <= "100";
        mem_WBreg1  <= '1';
        mem_rt_code1 <= "100";
        mem_AR1 <= x"ACAC";
        wait for period;
        assert ex_rt1 = x"ACAC" and load_forwarded_rt1 = '1' report "Error in the same pipe between two rt's";
        ex_rs_code1 <= "010";
        ex_rt_code1 <= "100";
        mem_WBreg1  <= '1';
        mem_rt_code1 <= "010";
        mem_AR1 <= x"ACAC";
        wait for period;
        assert ex_rs1 = x"ACAC" and load_forwarded_rs1 = '1' report "Error in the same pipe between rt and rs";
        ex_rs_code1 <= "010";
        ex_rt_code1 <= "100";
        mem_WBreg1  <= '0';
        wb_WBreg1 <= '1';
        mem_rt_code1 <= "000";
        wb_rt_code1 <= "010";
        wb_AR1 <= x"ACAC";
        wait for period;
        assert ex_rs1 = x"ACAC" and load_forwarded_rs1 = '1' report "Error in the same pipe between rt and rs in write back";
        ex_rs_code2 <= "010";
        ex_rt_code2 <= "100";
        mem_WBreg2  <= '1';
        mem_rt_code2 <= "010";
        mem_AR2 <= x"ACAC";
        wait for period;
        assert ex_rs2 = x"ACAC" and load_forwarded_rs2 = '1' report "Error in the same pipe2 between rt and rs";
        ex_rs_code2 <= "010";
        ex_rt_code2 <= "100";
        mem_WBreg2  <= '0';
        wb_WBreg2 <= '1';
        mem_rt_code2 <= "000";
        wb_rt_code2 <= "010";
        wb_AR1 <= x"ACAC";
        wait for period;
        assert ex_rs2 = x"ACAC" and load_forwarded_rs2 = '1' report "Error in the same pipe between rt and rs in write back";
---------------------------------------------
        ex_rt_code2<="111";
        ex_rt_code1<="111";
        ex_WBreg1<='1';
        mem_rt_code1<="000";
        mem_rt_code2<="111";
        mem_WBreg2  <= '1';
        mem_WBreg1  <= '1';
        mem_op_r2<='1';
        mem_op_r1<='1';
        ex_out1<=x"0006";
        wait for period;
        assert ex_rt2<=x"0006" and  load_forwarded_rt2='1' report "error in pipe two ex-ex";
        assert input_mem_cw_z='1' and load_forwarded_rt1='0' and stall_DandE='1' report "error in mem+op pipe1";
      
        ex_rs_code1 <= (others => '0');
        ex_rt_code1 <= (others => '0');
        ex_WBreg1 <= '0';
        ex_out1 <= (others => '0');
        ex_rs_code2 <= (others => '0');
        ex_rt_code2 <= (others => '0');
        ex_WBreg2 <= '0';
        ex_out2 <= (others => '0');
        mem_WBreg1 <= '0';
        mem_rt_code1 <= (others => '0');
        mem_op_r1 <= '0';
        mem_AR1 <= (others => '0');
        mem_op_w1 <= '0';
        mem_WBreg2 <= '0';
        mem_rt_code2 <= (others => '0');
        mem_op_r2 <= '0';
        mem_AR2 <= (others => '0');
        mem_op_w2 <= '0';
        wb_mdata <= (others => '0');
        wb_WBreg1 <= '0';
        wb_rt_code1 <= (others => '0');
        wb_AR1 <= (others => '0');
        wb_mem_op1 <= '0';
        wb_WBreg2 <= '0';
        wb_rt_code2 <= (others => '0');
        wb_AR2 <= (others => '0');
        wb_mem_op2 <= '0';
        wait for period;

        ex_rt_code2<="111";
        ex_rt_code1<="111";
        ex_WBreg1<='1';
        mem_op_r2<='1';
        mem_op_r1<='1';
        ex_out1<=x"0007";
        ex_rs_code1<="101";
        wb_mem_op1<='1';
        wb_WBreg1<='1';
        wb_rt_code1<="101";
        wb_mdata<=x"00000010";
        wait for period;
        assert ex_rt2<=x"0007" and input_mem_cw_z='0'and load_forwarded_rt2='1' report "error in pipe two ex-ex";
        assert ex_rs1<=x"0010" and load_forwarded_rs1='1' and stall_DandE='0' report "error in wb-wbsame pipe p1";
      

  
        -- EDIT Add stimuli here

        wait;
    end process;

end tb;