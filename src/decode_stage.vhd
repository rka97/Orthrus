library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library orthrus;
use orthrus.Constants.all;

entity DecodeStage is
    generic (
        N   : natural := 16; -- number of bits in word.
        M   : natural := 16;  -- number of bits in memory address.
        L_BITS : natural := 3 -- log2(Number of registers)
    );

    port (
        clk             :   in std_logic;
        reset           :   in std_logic;

        -- control signals
        -- stall           :   in std_logic;
        -- for the stack pointer
        -- sp_write        :   in std_logic;
        -- sp_data_in      :   in std_logic_vector(M-1 downto 0);
        -- for the register file / from the WB stage
        rf_write_1      :   in std_logic;
        rf_write_1_addr :   in std_logic_vector(L_BITS-1 downto 0);
        rf_data_in_1    :   in std_logic_vector(N-1 downto 0);
        rf_write_2      :   in std_logic;
        rf_write_2_addr :   in std_logic_vector(L_BITS-1 downto 0);
        rf_data_in_2    :   in std_logic_vector(N-1 downto 0);

        -- Input data
        inport_data_in  :   in std_logic_vector(N-1 downto 0);
        -- From the IF buffer
        IR1             :   in std_logic_vector(2*N-1 downto 0);
        IR2             :   in std_logic_vector(2*N-1 downto 0);
        new_pc          :   in std_logic_vector(M-1 downto 0);
        -- from the EX stage
        zero_flag       :   in std_logic;
        negative_flag   :   in std_logic;
        carry_flag      :   in std_logic;

        -- output control signals
        branch          :   out std_logic;
        branch_address  :   out std_logic_vector(M-1 downto 0);

        control_word_1  :   out std_logic_vector(2*N-1 downto 0);
        RT1             :   out std_logic_vector(N-1 downto 0);
        RS1             :   out std_logic_vector(N-1 downto 0);

        control_word_2  :   out std_logic_vector(2*N-1 downto 0);
        RT2             :   out std_logic_vector(N-1 downto 0);
        RS2             :   out std_logic_vector(N-1 downto 0);
        
        -- Addresses to push to when RS/RT are too small for the address to fit (like with PUSH/POP).
        push_addr_1     :   out std_logic_vector(M-1 downto 0);
        push_addr_2     :   out std_logic_vector(M-1 downto 0)
    );
end DecodeStage;

architecture Behavioral of DecodeStage is
    -- Register File signals
    signal rs1_read, rt1_read : std_logic;
    signal rs1_addr, rt1_addr : std_logic_vector(L_BITS-1 downto 0); 
    signal rf_rs1_data, rf_rt1_data : std_logic_vector(N-1 downto 0);
    signal rs2_read, rt2_read : std_logic;
    signal rs2_addr, rt2_addr : std_logic_vector(L_BITS-1 downto 0); 
    signal rf_rs2_data, rf_rt2_data : std_logic_vector(N-1 downto 0);

    -- Control Word 
    signal cw_data_1, cw_data_2 : std_logic_vector(2*N-1 downto 0);

    signal IR1_Op, IR2_Op : std_logic_vector(4 downto 0);
    signal In_Op_1, In_Op_2, LDM_Op_1, LDM_Op_2 : std_logic;

    signal will_branch_1 : std_logic;
    signal will_branch_2 : std_logic;
    signal br_data_in, br_data_out : std_logic_vector(M downto 0);

    -- Stack pointer management
    signal sp_load_in : std_logic;
    signal sp_data : std_logic_vector(M-1 downto 0);
    signal sp_subtract : std_logic;
    signal sp_increment : integer range 0 to 2;
    signal sp_data_incremented : std_logic_vector(M-1 downto 0);
    signal sp_data_reg : std_logic_vector(M-1 downto 0);
    begin
        control_word_1 <= cw_data_1(31 downto 3) & "00" & cw_data_1(0);
        control_word_2 <= cw_data_2(31 downto 3) & "00" & cw_data_2(0);

        rt1_addr <= cw_data_1(27 downto 25);
        rs1_addr <= cw_data_1(24 downto 22);
        rt2_addr <= cw_data_2(27 downto 25);
        rs2_addr <= cw_data_2(24 downto 22);
        
        In_Op_1 <= cw_data_1(11);
        In_Op_2 <= cw_data_2(11);
        LDM_Op_1 <= cw_data_1(10);
        LDM_Op_2 <= cw_data_2(10);

        IR1_Op <= IR1(2*N-1 downto 2*N-5);
        IR2_Op <= IR2(2*N-1 downto 2*N-5);

        RT1 <= rf_rt1_data when rt1_read = '1' else         -- Load from RF when requested
               inport_data_in when In_Op_1 = '1' else       -- Latch data in from the IN port
               IR1(N-1 downto 0) when LDM_Op_1 = '1' else (others => '0');   -- Take the data on the IR
        RS1 <= rf_rs1_data when rs1_read = '1' else (others => '0');

        RT2 <= rf_rt2_data when rt2_read = '1' else         -- Load from RF when requested
               inport_data_in when In_Op_2 = '1' else       -- Latch data in from the IN port
               IR2(N-1 downto 0) when LDM_Op_2 = '1' else (others => '0');    -- Take the data on the IR
        RS2 <= rf_rs2_data when rs2_read = '1' else (others => '0');
        
        will_branch_1 <= '1' when IR1_Op = INST_JMP or IR1_Op = INST_CALL else
                         zero_flag when IR1_Op = INST_JZ else
                         negative_flag when IR1_Op = INST_JN else
                         carry_flag when IR1_Op = INST_JC else
                         '0';

        will_branch_2 <= '1' when IR2_Op = INST_JMP or IR2_Op = INST_CALL else
                         zero_flag when IR2_Op = INST_JZ else
                         negative_flag when IR2_Op = INST_JN else
                         carry_flag when IR2_Op = INST_JC else
                         '0';
        
        -- TODO: Branch address padding.
        branch <= br_data_out(0);
        branch_address <= br_data_out(M downto 1);
        br_data_in(0) <= will_branch_1 or will_branch_2;
        br_data_in(M downto 1) <= rf_rt1_data when will_branch_1 = '1' else
                                  rf_rt2_data when will_branch_2 = '1' else
                                  (others => '0');

        push_addr_1 <= sp_data when IR1_Op = INST_PUSH or IR1_Op = INST_CALL or IR1_Op = INST_ITR else 
                       sp_data_incremented when IR1_Op = INST_POP or IR1_Op = INST_RET or IR1_Op = INST_RTI else 
                       (others => '0');
        push_addr_2 <= sp_data when IR2_Op = INST_PUSH or IR2_Op = INST_CALL or IR2_Op = INST_ITR else 
                       sp_data_incremented when IR2_Op = INST_POP or IR2_Op = INST_RET or IR2_Op = INST_RTI else 
                       (others => '0');
        
        -- For managing the stack pointer
        -- sp_data <= sp_data_in when sp_write = '1' else sp_data_reg;
        sp_data_incremented <= std_logic_vector(unsigned(sp_data) + to_unsigned(sp_increment, M)) when sp_subtract = '0' else std_logic_vector(unsigned(sp_data) - to_unsigned(sp_increment, M));

        branch_reg_inst : entity orthrus.Reg
            generic map ( n => M + 1)
            port map (
                clk => clk,
                load => '1',
                reset => reset,
                d => br_data_in,
                q => br_data_out,
                rst_data => (others => '0')
            );

        stack_pointer_reg_inst: entity orthrus.Reg
            generic map (n => M)
            port map (
                clk => clk,
                load => sp_load_in,
                reset => reset,
                d => sp_data_incremented,
                q => sp_data_reg,
                rst_data => (others => '0')
            );
        
        register_file_inst : entity orthrus.RegisterFile
                generic map ( W => N, L_BITS => L_BITS )
                port map (
                    clk => clk,
                    reset => reset,

                    read_1_1 => rs1_read,
                    sel_read_1_1 => rs1_addr,
                    data_out_1_1 => rf_rs1_data,

                    read_1_2 => rt1_read,
                    sel_read_1_2 => rt1_addr,
                    data_out_1_2 => rf_rt1_data,

                    write_1 => rf_write_1,
                    sel_write_1 => rf_write_1_addr,
                    data_in_1 => rf_data_in_1,

                    read_2_1 => rs2_read,
                    sel_read_2_1 => rs2_addr,
                    data_out_2_1 => rf_rs2_data,

                    read_2_2 => rt2_read,
                    sel_read_2_2 => rt2_addr,
                    data_out_2_2 => rf_rt2_data,

                    write_2 => rf_write_2,
                    sel_write_2 => rf_write_2_addr,
                    data_in_2 => rf_data_in_2    
                );
                
        decode_unit_1 : entity orthrus.DecodeUnit
            generic map ( N => N, L_BITS => L_BITS)
            port map (
                IR => IR1,
                ALUOp => cw_data_1(31 downto 28),
                rt_read => rt1_read,
                RTAddr => cw_data_1(27 downto 25),
                rs_read => rs1_read,
                RSAddr => cw_data_1(24 downto 22),
                WBReg => cw_data_1(21),
                Out_Op => cw_data_1(20),
                Push_Op => cw_data_1(19),
                Pop_Op => cw_data_1(18),
                Load_Op => cw_data_1(17),
                STD_Op => cw_data_1(16),
                Call_Op => cw_data_1(15),
                RET_Op => cw_data_1(14),
                RestoreFlags => cw_data_1(13),
                ITR_Op => cw_data_1(12),
                In_Op => cw_data_1(11),
                LDM_Op => cw_data_1(10),
                UpdateFlags => cw_data_1(9),
                SETC_Op => cw_data_1(8),
                CLRC_Op => cw_data_1(7),
                ShiftAmt => cw_data_1(6 downto 3),
                mem_load => cw_data_1(2),
                -- cw_data_1(1) is free.
                push_double => cw_data_1(0)
            );

        decode_unit_2 : entity orthrus.DecodeUnit
            generic map ( N => N, L_BITS => L_BITS)
            port map (
                IR => IR2,
                ALUOp => cw_data_2(31 downto 28),
                rt_read => rt2_read,
                RTAddr => cw_data_2(27 downto 25),
                rs_read => rs2_read,
                RSAddr => cw_data_2(24 downto 22),
                WBReg => cw_data_2(21),
                Out_Op => cw_data_2(20),
                Push_Op => cw_data_2(19),
                Pop_Op => cw_data_2(18),
                Load_Op => cw_data_2(17),
                STD_Op => cw_data_2(16),
                Call_Op => cw_data_2(15),
                RET_Op => cw_data_2(14),
                RestoreFlags => cw_data_2(13),
                ITR_Op => cw_data_2(12),
                In_Op => cw_data_2(11),
                LDM_Op => cw_data_2(10),
                UpdateFlags => cw_data_2(9),
                SETC_Op => cw_data_2(8),
                CLRC_Op => cw_data_2(7),
                ShiftAmt => cw_data_2(6 downto 3),
                mem_load => cw_data_2(2),
                -- cw_data_2(1) is free.
                push_double => cw_data_2(0)
            );

        -- TODO: Stack Pointer management.
        -- comp_new_sp : process(sp_write, IR1_Op, IR2_Op)
        comp_new_sp : process(IR2_Op, IR1_Op)
        begin
            if IR2_Op = INST_PUSH then
                sp_increment <= 1;
                sp_subtract <= '1';
                sp_load_in <= '1';
            elsif IR2_Op = INST_RET or IR2_Op = INST_RTI then
                sp_increment <= 2;
                sp_subtract <= '0';
                sp_load_in <= '1';
            elsif IR2_Op = INST_CALL or IR2_Op = INST_ITR then
                sp_increment <= 2;
                sp_subtract <= '1';
                sp_load_in <= '1';
            elsif IR2_Op = INST_POP then
                sp_increment <= 1;
                sp_subtract <= '0';
                sp_load_in <= '1';
            elsif IR1_Op = INST_PUSH then
                sp_increment <= 1;
                sp_subtract <= '1';
                sp_load_in <= '1';
            elsif IR1_Op = INST_RET or IR1_Op = INST_RTI then
                sp_increment <= 2;
                sp_subtract <= '0';
                sp_load_in <= '1';
            elsif IR1_Op = INST_CALL or IR1_Op = INST_ITR then
                sp_increment <= 2;
                sp_subtract <= '1';
                sp_load_in <= '1';
            elsif IR1_Op = INST_POP then
                sp_increment <= 1;
                sp_subtract <= '0';
                sp_load_in <= '1';
            -- elsif sp_write = '1' then
            --     sp_increment <= 0;
            --     sp_subtract <= '0';
            --     sp_load_in <= '1';
            else
                sp_increment <= 0;
                sp_subtract <= '0';
                sp_load_in <= '0';
            end if;
        end process;
        
end Behavioral;