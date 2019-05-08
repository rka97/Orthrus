library ieee, modelsim_lib;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use modelsim_lib.util.all;
library orthrus;
use orthrus.Constants.all;

entity Processor is
    port (
        clk : in std_logic;
        reset : in std_logic;

        interrupt : in std_logic;
        inport_data_in : in std_logic_vector(N-1 downto 0);
        out_port_data_out : out std_logic_vector(N-1 downto 0);

        mem_data_in : in std_logic_vector(2*N-1 downto 0);
        mem_data_out : out std_logic_vector(2*N-1 downto 0);
        mem_address_out : out std_logic_vector(M-1 downto 0);
        read_mem : out std_logic;
        write_mem : out std_logic;
        write_double_mem : out std_logic
    );
end Processor;

architecture Structural of Processor is
    -- Generics
    signal not_clk : std_logic;

    -- Buffer register controls & Hazards
    signal stall_fetch, stall_decode, stall_execute, stall_mem, stall_wb : std_logic := '0';
    signal ctrl_hazard_stall_decode_buf, ctrl_hazard_stall_execute_buf, ctrl_hazard_stall_memory_buf : std_logic;
    signal ctrl_hazard_flush_decode_buf, ctrl_hazard_flush_execute_buf, ctrl_hazard_flush_decode2 : std_logic;
    signal ctrl_hazard_stall_execute, ctrl_hazard_stall_mem : std_logic;
    
    signal branch_take_forwarded_addr : std_logic;
    signal branch_forwarded_addr : std_logic_vector(M-1 downto 0);

    signal reset_decode_buffer, reset_ex_buffer, reset_mem_buffer, reset_wb_buffer : std_logic := '0';
    signal load_decode_buf, load_ex_buf, load_mem_buf, load_wb_buf : std_logic;

    -- Signals generate by the Fetch Stage
    signal fetch_read_mem : std_logic;
    signal fetch_addr_out : std_logic_vector(M-1 downto 0);
    signal IR1_fetch : std_logic_vector(2*N-1 downto 0);
    signal IR2_fetch : std_logic_vector(2*N-1 downto 0);
    signal new_pc_fetch : std_logic_vector(M-1 downto 0);

    -- Signals generated by the Decode Stage buffers
    signal IR1_buffered : std_logic_vector(2*N-1 downto 0);
    signal IR2_buffered : std_logic_vector(2*N-1 downto 0);
    signal new_pc_buff_dec : std_logic_vector(M-1 downto 0);

    signal IR1_Op : std_logic_vector(4 downto 0);

    -- Signals generated by the Decode Stage
    signal branch : std_logic;
    signal branch_address : std_logic_vector(M-1 downto 0);
    -- signal reset_zero_flag, reset_carry_flag, reset_negative_flag : std_logic;
    signal reset_flags_dec : std_logic_vector(2 downto 0);
    signal cw_1_decode, cw_2_decode : std_logic_vector(2*N-1 downto 0);
    signal RT1_dec, RS1_dec, RT2_dec, RS2_dec : std_logic_vector(N-1 downto 0);
    signal push_addr_1_dec, push_addr_2_dec : std_logic_vector(M-1 downto 0);

    -- Signals generated by the EX Stage buffers
    signal cw_1_buff_ex, cw_2_buff_ex : std_logic_vector(2*N-1 downto 0);
    signal RT1_buff_ex, RS1_buff_ex, RT2_buff_ex, RS2_buff_ex : std_logic_vector(N-1 downto 0);
    signal push_addr_1_buff_ex, push_addr_2_buff_ex, new_pc_buff_ex : std_logic_vector(M-1 downto 0);
    signal reset_flags_buff_ex : std_logic_vector(2 downto 0);

    -- Signals generated by the EX Stage
    signal A1Res, A2Res : std_logic_vector(N-1 downto 0);
    signal flags : std_logic_vector(N-1 downto 0);
    signal zero_flag, negative_flag, carry_flag : std_logic;

    -- Signals generated by the MEM Stage buffers
    signal cw_1_buff_mem, cw_2_buff_mem : std_logic_vector(2*N-1 downto 0);
    signal A1Res_buff_mem, A2Res_buff_mem, RT1_buff_mem, RT2_buff_mem : std_logic_vector(N-1 downto 0);
    signal push_addr_1_buff_mem, push_addr_2_buff_mem, new_pc_buff_mem : std_logic_vector(M-1 downto 0);

    -- Signals generated by the MEM stage
    signal wpc1_write, wpc2_write : std_logic;
    signal mem_stage_read_mem, mem_stage_write_mem, mem_stage_write_double : std_logic;
    signal mem_stage_address : std_logic_vector(M-1 downto 0);
    signal mem_stage_data : std_logic_vector(2*N-1 downto 0);

    -- Signals generated by the WB Stage buffers
    signal cw_1_buff_wb, cw_2_buff_wb : std_logic_vector(2*N-1 downto 0);
    signal A1Res_buff_wb, A2Res_buff_wb : std_logic_vector(N-1 downto 0);
    signal MData_buff_wb_in : std_logic_vector(N-1 downto 0);
    signal MData_buff_wb_out : std_logic_vector(N-1 downto 0);

    -- Signals generated by the WB stage
    -- signal sp_write : std_logic := '0';
    -- signal sp_data  : std_logic_vector(M-1 downto 0) := (others => '0');
    signal rf_write_1, rf_write_2 : std_logic := '0';
    signal rf_write_1_addr, rf_write_2_addr : std_logic_vector(2 downto 0) := (others => '0');
    signal rf_data_in_1, rf_data_in_2 : std_logic_vector(N-1 downto 0) := (others => '0');



    ------------- raw hazzard signals
    signal load_forwarded_rs1 : std_logic; --To decide what data will be used, standard or forwared
    signal load_forwarded_rs2 :   std_logic;
    signal load_forwarded_rt1 :   std_logic;
    signal load_forwarded_rt2 :   std_logic;
    signal load_forwarded_mdata1 :   std_logic;
    signal load_forwarded_mdata2 :   std_logic;
    signal mem_store1 :std_logic;
    signal mem_store2 :std_logic;
    signal ex_rs1_for:   std_logic_vector(N-1 downto 0); --actual data forwarded
    signal ex_rt1_for:   std_logic_vector(N-1 downto 0);
    signal ex_rs2_for:   std_logic_vector(N-1 downto 0);
    signal ex_rt2_for:   std_logic_vector(N-1 downto 0);
    signal mem_data1_for:   std_logic_vector(2*N-1 downto 0);
    signal mem_data2_for:  std_logic_vector(2*N-1 downto 0);
    signal stall_DandE :std_logic;

    signal input_mem_cw_z: std_logic;
    signal mem_cw_1_in: std_logic_vector(2*N-1 downto 0);
    signal mem_cw_2_in: std_logic_vector(2*N-1 downto 0);
    signal ex_rs1_input: std_logic_vector(N-1 downto 0);
    signal ex_rt1_input: std_logic_vector(N-1 downto 0);
    signal ex_rs2_input: std_logic_vector(N-1 downto 0);
    signal ex_rt2_input: std_logic_vector(N-1 downto 0);
    signal wb_mdata: std_logic_vector(2*N-1 downto 0);


    signal stall_fetch_2 : std_logic;

    -- function IsMemOp (
    --     cw : in std_logic_vector(31 downto 0)
    -- ) return std_logic is
    -- begin
    --     if (cw(19) = '1' or cw(18) = '1' or cw(17) = '1' or cw(16) = '1' or cw(14) = '1' or cw(1) = '1') then
    --         return '1';
    --     else
    --         return '0';
    --     end if;
    -- end IsMemOp;
    begin
        not_clk <= not(clk);
        IR1_Op <= IR1_buffered(31 downto 27);

        stall_decode <= ctrl_hazard_stall_decode_buf or stall_DandE;
        stall_execute <= ctrl_hazard_stall_execute_buf or stall_DandE;
        stall_mem <= ctrl_hazard_stall_memory_buf;
        stall_wb <= '0';

        reset_decode_buffer <= reset;
        reset_ex_buffer <= reset;
        reset_mem_buffer <= reset;
        reset_wb_buffer <= reset;

        load_decode_buf <= '1' when stall_decode = '0' and reset = '0' else '0';
        load_ex_buf <= '1' when stall_execute = '0' and reset = '0' else '0';
        load_mem_buf <= '1' when stall_mem = '0' and reset = '0' else '0';
        load_wb_buf <= '1' when stall_wb = '0' and reset = '0' else '0';
        
        zero_flag <= flags(0);
        negative_flag <= flags(1);
        carry_flag <= flags(2);

        read_mem <= '0' when mem_stage_write_mem = '1' else mem_stage_read_mem or fetch_read_mem;
        write_mem <= mem_stage_write_mem;
        write_double_mem <= mem_stage_write_double;

        stall_fetch <= mem_stage_read_mem or mem_stage_write_mem or stall_decode or stall_fetch_2;
        stall_fetch_2 <= '1' when (IR1_buffered(31 downto 27) = INST_RET or 
                                  IR1_buffered(31 downto 27) = INST_RTI or
                                  cw_1_buff_ex(14) = '1' or 
                                  cw_1_buff_mem(14) = '1' or 
                                  cw_1_buff_ex(1) = '1' or 
                                  cw_1_buff_mem(1) = '1') else  
                                '0';
        mem_address_out <= mem_stage_address when stall_fetch = '1' else fetch_addr_out; 
        
        mem_data_out <= mem_data1_for when load_forwarded_mdata1='1' else
                        mem_data2_for when load_forwarded_mdata2='1' else
                        mem_stage_data;
        -- TODO: Generalize MData buffer size.
        MData_buff_wb_in <= mem_stage_data(15 downto 0) when mem_stage_write_mem = '1' else
                            mem_data_in(15 downto 0) when mem_stage_read_mem = '1' else
                            (others => '0');
        -- Fetch Stage instantiations
        FetchStage_inst : entity orthrus.FetchStage
        port map (
            clk => clk,
            reset => reset,
            read_mem => fetch_read_mem,
            mem_data_in => mem_data_in,
            mem_address_out => fetch_addr_out,
            stall => stall_fetch,
            interrupt => interrupt,
            branch => branch,
            branch_address => branch_address,
            wpc1_write => wpc1_write,
            wpc2_write => wpc2_write,
            IR1 => IR1_fetch,
            IR2 => IR2_fetch,
            new_pc => new_pc_fetch
        );

        -- Decode Stage buffers
        IR1_inst : entity orthrus.Reg
            generic map ( n => 2*N )
            port map (
                clk => not_clk, d => IR1_fetch, q => IR1_buffered,
                rst_data => (others => '0'), load => load_decode_buf, reset => reset_decode_buffer
            );
        IR2_inst : entity orthrus.Reg
            generic map ( n => 2*N )
            port map (
                clk => not_clk, d => IR2_fetch, q => IR2_buffered,
                rst_data => (others => '0'), load => load_decode_buf, reset => reset_decode_buffer 
            );
        new_pc_buff_dec_inst : entity orthrus.Reg
            generic map ( n => M )
            port map (
                clk => not_clk, d => new_pc_fetch, q => new_pc_buff_dec,
                rst_data => (others => '0'), load => load_decode_buf, reset => reset_decode_buffer 
            );
        
        -- Decode Stage instantiations
        DecodeStage_inst : entity orthrus.DecodeStage
            generic map ( N => N, M => M, L_BITS => 3 )
            port map (
                clk => clk,
                reset => reset,
                stall => stall_decode,

                -- sp_write => sp_write,
                -- sp_data_in => sp_data,
                rf_write_1 => rf_write_1,
                rf_write_1_addr => rf_write_1_addr,
                rf_data_in_1 => rf_data_in_1,
                rf_write_2 => rf_write_2,
                rf_write_2_addr => rf_write_2_addr,
                rf_data_in_2 => rf_data_in_2,

                inport_data_in => inport_data_in,
                IR1 => IR1_buffered,
                IR2 => IR2_buffered,
                new_pc => new_pc_buff_dec,
                
                zero_flag => zero_flag,
                negative_flag => negative_flag,
                carry_flag => carry_flag,

                take_addr => branch_take_forwarded_addr,
                branch_forwarded_addr => branch_forwarded_addr,

                branch => branch,
                branch_address => branch_address,
                reset_flags => reset_flags_dec,

                control_word_1 => cw_1_decode,
                RT1 => RT1_dec,
                RS1 => RS1_dec,
                control_word_2 => cw_2_decode,
                RT2 => RT2_dec,
                RS2 => RS2_dec,
                push_addr_1 => push_addr_1_dec,
                push_addr_2 => push_addr_2_dec
            );
        -- Execute Stage buffers
        ex_rs1_input<=  ex_rs1_for when load_forwarded_rs1='1' else
                        RS1_buff_ex;

        ex_rt1_input<=  ex_rt1_for when load_forwarded_rt1='1' else
                         RT1_buff_ex;

        ex_rs2_input<=  ex_rs2_for when load_forwarded_rs2='1' else
                        RS2_buff_ex;

        ex_rt2_input<=  ex_rt2_for when load_forwarded_rt2='1' else
                        RT2_buff_ex;

        control_word_1_inst : entity orthrus.Reg
            generic map ( n => 2*N )
            port map (
                clk => not_clk, d => cw_1_decode, q => cw_1_buff_ex,
                rst_data => (others => '0'), load => load_ex_buf, reset => reset_ex_buffer
            );
        RT1_inst : entity orthrus.Reg
            generic map ( n => N )
            port map (
                clk => not_clk, d => RT1_dec, q => RT1_buff_ex,
                rst_data => (others => '0'), load => load_ex_buf, reset => reset_ex_buffer 
            );
        RS1_inst : entity orthrus.Reg
            generic map ( n => N )
            port map (
                clk => not_clk, d => RS1_dec, q => RS1_buff_ex,
                rst_data => (others => '0'), load => load_ex_buf, reset => reset_ex_buffer 
            );
        push_addr_1_inst : entity orthrus.Reg
            generic map ( n => N )
            port map (
                clk => not_clk, d => push_addr_1_dec, q => push_addr_1_buff_ex,
                rst_data => (others => '0'), load => load_ex_buf, reset => reset_ex_buffer 
            );
        control_word_2_inst : entity orthrus.Reg
            generic map ( n => 2*N )
            port map (
                clk => not_clk, d => cw_2_decode, q => cw_2_buff_ex,
                rst_data => (others => '0'), load => load_ex_buf, reset => reset_ex_buffer 
            );
        RT2_inst : entity orthrus.Reg
            generic map ( n => N )
            port map (
                clk => not_clk, d => RT2_dec, q => RT2_buff_ex,
                rst_data => (others => '0'), load => load_ex_buf, reset => reset_ex_buffer 
            );
        RS2_inst : entity orthrus.Reg
            generic map ( n => N )
            port map (
                clk => not_clk, d => RS2_dec, q => RS2_buff_ex,
                rst_data => (others => '0'), load => load_ex_buf, reset => reset_ex_buffer 
            );
        push_addr_2_inst : entity orthrus.Reg
            generic map ( n => N )
            port map (
                clk => not_clk, d => push_addr_2_dec, q => push_addr_2_buff_ex,
                rst_data => (others => '0'), load => load_ex_buf, reset => reset_ex_buffer 
            );
        new_pc_ex_buf : entity orthrus.Reg
            generic map ( n => M )
            port map (
                clk => not_clk, d => new_pc_buff_dec, q => new_pc_buff_ex,
                rst_data => (others => '0'), load => load_ex_buf, reset => reset_ex_buffer 
            );
        reset_flags_buf_inst : entity orthrus.Reg
            generic map ( n => 3 )
            port map (
                clk => not_clk, d => reset_flags_dec, q => reset_flags_buff_ex, 
                rst_data => (others => '0'), load => load_ex_buf, reset => reset_ex_buffer
            );
        -- Execute Stage Instantiations
        ExecuteStage_inst : entity orthrus.ExecuteStage
            generic map ( N => N )
            port map (
                clk => clk,
                reset => reset,
                
                ControlW_1 => cw_1_buff_ex,
                A1 => ex_rs1_input,
                B1 => ex_rt1_input,
                F1 => A1Res,

                ControlW_2 => cw_2_buff_ex,
                A2 => ex_rs2_input,
                B2 => ex_rt2_input,
                F2 => A2Res,

                reset_flags => reset_flags_buff_ex,
                Flags => flags,

                cw_z => ctrl_hazard_stall_execute
            );
        -- Memory Stage buffers
        mem_cw_1_in<= (others=>'0') when input_mem_cw_z='1' else
                        cw_1_buff_ex;
        mem_cw_2_in<= (others=>'0') when input_mem_cw_z='1' else
        cw_2_buff_ex;
        mem_cw_1_inst : entity orthrus.Reg
            generic map ( n => 2*N )
            port map (
                clk => not_clk, d => mem_cw_1_in, q => cw_1_buff_mem,
                rst_data => (others => '0'), load => load_mem_buf, reset => reset_mem_buffer 
            );
        mem_A1Res_inst : entity orthrus.Reg
            generic map ( n => N )
            port map (
                clk => not_clk, d => A1Res, q => A1Res_buff_mem,
                rst_data => (others => '0'), load => load_mem_buf, reset => reset_mem_buffer 
            );
        mem_RT1_inst : entity orthrus.Reg
            generic map (n => N)
            port map (
                clk => not_clk, d => RT1_buff_ex, q => RT1_buff_mem,
                rst_data => (others => '0'), load => load_mem_buf, reset => reset_mem_buffer 
            );
        mem_push_addr_1_inst : entity orthrus.Reg
            generic map ( n => M )
            port map (
                clk => not_clk, d => push_addr_1_buff_ex, q => push_addr_1_buff_mem,
                rst_data => (others => '0'), load => load_mem_buf, reset => reset_mem_buffer 
            );
        mem_cw_2_inst : entity orthrus.Reg
            generic map ( n => 2*N )
            port map (
                clk => not_clk, d => mem_cw_2_in, q => cw_2_buff_mem,
                rst_data => (others => '0'), load => load_mem_buf, reset => reset_mem_buffer 
            );
        mem_A2Res_inst : entity orthrus.Reg
            generic map ( n => N )
            port map (
                clk => not_clk, d => A2Res, q => A2Res_buff_mem,
                rst_data => (others => '0'), load => load_mem_buf, reset => reset_mem_buffer 
            );
        mem_RT2_inst : entity orthrus.Reg
            generic map (n => N)
            port map (
                clk => not_clk, d => RT2_buff_ex, q => RT2_buff_mem,
                rst_data => (others => '0'), load => load_mem_buf, reset => reset_mem_buffer 
            );
        mem_push_addr_2_inst : entity orthrus.Reg
            generic map ( n => M )
            port map (
                clk => not_clk, d => push_addr_2_buff_ex, q => push_addr_2_buff_mem,
                rst_data => (others => '0'), load => load_mem_buf, reset => reset_mem_buffer 
            );
        new_pc_mem_buf : entity orthrus.Reg
            generic map ( n => M )
            port map (
                clk => not_clk, d => new_pc_buff_ex, q => new_pc_buff_mem,
                rst_data => (others => '0'), load => load_mem_buf, reset => reset_mem_buffer 
            );
        -- Memory Stage instantiations

        MemoryStage_inst : entity orthrus.MemoryStage
            generic map ( N => N, M => M, buffer_unit => 2*N)
            port map (
                ControlW1 => cw_1_buff_mem,
                ar_S1 => A1Res_buff_mem,
                ar_T1 => RT1_buff_mem,
                push_addr_1 => push_addr_1_buff_mem,

                ControlW2 => cw_2_buff_mem,
                ar_S2 => A2Res_buff_mem,
                ar_T2 => RT2_buff_mem,
                push_addr_2 => push_addr_2_buff_mem,

                cw_z => ctrl_hazard_stall_mem,

                new_PC => new_pc_buff_mem,

                PC_Write1 => wpc1_write,
                PC_Write2 => wpc2_write,
                M_Addr => mem_stage_address,
                M_Data => mem_stage_data,
                M_Rqst_r => mem_stage_read_mem,
                M_Rqst_w => mem_stage_write_mem,
                M_write_double => mem_stage_write_double,
                cw_z=>'0'
            );
        -- WB Stage buffers
        wb_cw_1_inst : entity orthrus.Reg
            generic map ( n => 2*N )
            port map (
                clk => not_clk, d => cw_1_buff_mem, q => cw_1_buff_wb,
                rst_data => (others => '0'), load => load_wb_buf, reset => reset_wb_buffer 
            );
        wb_A1Res_inst : entity orthrus.Reg
            generic map ( n => N )
            port map (
                clk => not_clk, d => A1Res_buff_mem, q => A1Res_buff_wb,
                rst_data => (others => '0'), load => load_wb_buf, reset => reset_wb_buffer 
            );
        wb_cw_2_inst : entity orthrus.Reg
            generic map ( n => 2*N )
            port map (
                clk => not_clk, d => cw_2_buff_mem, q => cw_2_buff_wb,
                rst_data => (others => '0'), load => load_wb_buf, reset => reset_wb_buffer 
            );
        wb_A2Res_inst : entity orthrus.Reg
            generic map ( n => N )
            port map (
                clk => not_clk, d => A2Res_buff_mem, q => A2Res_buff_wb,
                rst_data => (others => '0'), load => load_wb_buf, reset => reset_wb_buffer 
            );
        wb_MData_inst : entity orthrus.Reg
            generic map ( n => N )
            port map (
                clk => not_clk, d => MData_buff_wb_in, q => MData_buff_wb_out,
                rst_data => (others => '0'), load => load_wb_buf, reset => reset_wb_buffer 
            );
        
        -- WB Stage Instantiations
        WriteBackStage_inst : entity orthrus.WriteBackStage
            generic map ( N => N, M => M )
            port map (
                clk => clk,
                reset => reset,

                mem_data => MData_buff_wb_out,
                control_word_1 => cw_1_buff_wb,
                alu_res_1 => A1Res_buff_wb,
                control_word_2 => cw_2_buff_wb,
                alu_res_2 => A2Res_buff_wb,

                to_out_port => out_port_data_out,

                to_rf_write_data_1 => rf_data_in_1,
                to_rf_write_1 => rf_write_1,
                to_rf_write_sel_1 => rf_write_1_addr,

                to_rf_write_data_2 => rf_data_in_2,
                to_rf_write_2 => rf_write_2,
                to_rf_write_sel_2 => rf_write_2_addr
            );

            --------------------------
            mem_store1<='1' when cw_1_buff_mem(16)='1' or cw_1_buff_mem(19)='1'
            else '0';
            mem_store2<='1' when cw_2_buff_mem(16)='1' or cw_2_buff_mem(19)='1'
            else '0';
            MData_buff_wb_out<=wb_mdata(N-1 downto 0);

            raw_haz_unit: entity orthrus.RAWHazardUnit
            generic map ( N => N, M => M, L_BITS=>3, buffer_unit=>2*N )
            port map(
                ex_rs_code1 => cw_1_buff_ex(24 downto 22),
                ex_rt_code1 => cw_1_buff_ex(27 downto 25),
                ex_WBreg1=>  cw_1_buff_ex(21),
                ex_out1=> A1Res,
                ex_rs_code2 => cw_2_buff_ex(24 downto 22),
                ex_rt_code2 => cw_2_buff_ex(27 downto 25),
                ex_WBreg2=> cw_2_buff_ex(21),
                ex_out2=> A2Res,
                mem_WBreg1 =>cw_1_buff_mem(21),
                mem_rt_code1 =>cw_1_buff_mem(27 downto 25),
                mem_op_r1  => cw_1_buff_mem(2),
                mem_AR1     => A1Res_buff_mem,
                mem_op_w1 => mem_store1,
                mem_WBreg2 => cw_2_buff_mem(21),
                mem_rt_code2=>cw_2_buff_mem(27 downto 25),
                mem_op_r2  =>cw_2_buff_mem(2),
                mem_AR2   => A2Res_buff_mem,
                mem_op_w2 => mem_store2,
                wb_mdata  => wb_mdata,
                wb_WBreg1   =>  cw_1_buff_wb(21),
                wb_rt_code1=>cw_1_buff_wb(27 downto 25),
                wb_AR1    => A1Res_buff_wb,
                wb_mem_op1=> cw_1_buff_wb(2),
                wb_WBreg2  => cw_2_buff_wb(21),
                wb_rt_code2=>cw_2_buff_wb(27 downto 25),
                wb_AR2    => A2Res_buff_wb,
                wb_mem_op2=>cw_2_buff_wb(2),
                stall_DandE => stall_DandE,
                input_mem_cw_z =>input_mem_cw_z,
                load_forwarded_rs1=> load_forwarded_rs1,
                load_forwarded_rs2=> load_forwarded_rs2,
                load_forwarded_rt1=>load_forwarded_rt1,
                load_forwarded_rt2=> load_forwarded_rt2,
                load_forwarded_mdata1=> load_forwarded_mdata1,
                load_forwarded_mdata2=>load_forwarded_mdata2,
                ex_rs1=>ex_rs1_for,
                ex_rt1=>ex_rt1_for,
                ex_rs2=>ex_rs2_for,
                ex_rt2=>ex_rt2_for,
                mem_data1=>mem_data1_for,
                mem_data2=>mem_data2_for
            );

        
        -- Control Hazard Unit
        ControlHazardUnit_inst : entity orthrus.ControlHazardUnit
            generic map ( N => N, M => M, L_BITS => 3)
            port map (
                branch => branch,
                dec_rt_code1 => IR1_buffered(26 downto 24),

                ex_rt_code1 => cw_1_buff_ex(27 downto 25),
                ex_WBReg1 => cw_1_buff_ex(21),
                ex_mem_op1 => cw_1_buff_ex(2),
                ex_out1 => A1Res,
                ex_rt_code2 => cw_2_buff_ex(27 downto 25),
                ex_WBReg2 => cw_2_buff_ex(21),
                ex_mem_op2 => cw_2_buff_ex(2),
                ex_out2 => A2Res,

                -- cw_1_buff_mem => cw_1_buff_mem,
                -- cw_2_buff_mem => cw_2_buff_mem,
                mem_WBreg1 => cw_1_buff_mem(21),
                mem_rt_code1 => cw_1_buff_mem(27 downto 25),
                mem_AR1 => A1Res_buff_mem,
                mem_writePC1 => wpc1_write,
                mem_mem_op1 => cw_1_buff_mem(2),

                mem_WBreg2 => cw_2_buff_mem(21),
                mem_rt_code2 => cw_2_buff_mem(27 downto 25),
                mem_AR2 => A2Res_buff_mem,
                mem_writePC2 => wpc2_write,
                mem_mem_op2 => cw_2_buff_mem(2),

                wb_WBreg1 => rf_write_1,
                wb_rt_code1 => rf_write_1_addr,
                wb_AR1 => rf_data_in_1,
                wb_WBreg2 => rf_write_2,
                wb_rt_code2 => rf_write_2_addr,
                wb_AR2 => rf_data_in_2,

                stall_d => ctrl_hazard_stall_decode_buf,
                stall_e => ctrl_hazard_stall_execute_buf,
                stall_m => ctrl_hazard_stall_memory_buf,
                
                flush_d => ctrl_hazard_flush_decode_buf,
                flush_e => ctrl_hazard_flush_execute_buf,
                flush_d2 => ctrl_hazard_flush_decode2,

                input_cw_ex_z => ctrl_hazard_stall_execute,
                input_cw_mem_z => ctrl_hazard_stall_mem,

                take_addr => branch_take_forwarded_addr,
                branch_add => branch_forwarded_addr
            );
end Structural;