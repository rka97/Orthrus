library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library orthrus;
use orthrus.Constants.all;

entity DecodeUnit is
    generic (
        N : natural := 16; -- number of bits in word
        L_BITS : natural := 3 -- log2(Number of registers)
    );
    port (
        IR              :   in std_logic_vector(2*N-1 downto 0);
        ALUOp           :   out std_logic_vector(3 downto 0);
        rt_read         :   out std_logic;
        RTAddr          :   out std_logic_vector(L_BITS-1 downto 0);
        rs_read         :   out std_logic;
        RSAddr          :   out std_logic_vector(L_BITS-1 downto 0);
        WBReg           :   out std_logic;
        Out_Op          :   out std_logic;
        Push_Op         :   out std_logic;
        Pop_Op          :   out std_logic;
        Load_Op         :   out std_logic;
        STD_Op          :   out std_logic;
        Call_Op         :   out std_logic;
        RET_Op          :   out std_logic;
        RestoreFlags    :   out std_logic;
        ITR_Op          :   out std_logic;
        In_Op           :   out std_logic;
        LDM_Op          :   out std_logic;
        UpdateFlags     :   out std_logic;
        SETC_Op         :   out std_logic;
        CLRC_Op         :   out std_logic;
        ShiftAmt        :   out std_logic_vector(3 downto 0);
        mem_load        :   out std_logic;
        RTI_Op          :   out std_logic;
        push_double     :   out std_logic
    );
end DecodeUnit;

architecture Behavioral of DecodeUnit is
    signal IR_Op : std_logic_vector(4 downto 0);
    signal IR_short : std_logic_vector(15 downto 0); 
    begin
        IR_Op <= IR(31 downto 27);
        IR_short <= IR(31 downto 16);
        ALUOp <= ALUOP_NOT when IR_Op = INST_NOT else
                 ALUOP_INC when IR_Op = INST_INC else
                 ALUOP_DEC when IR_Op = INST_DEC else
                 ALUOP_PASSB when IR_Op = INST_OUT or IR_Op = INST_PUSH or IR_Op = INST_IN or
                                  IR_Op = INST_POP or IR_Op = INST_LDM else
                 ALUOP_PASSA when IR_Op = INST_MOV or IR_Op = INST_STD or IR_Op = INST_LDD else
                 ALUOP_SUB when IR_Op = INST_SUB else
                 ALUOP_ADD when IR_Op = INST_ADD else
                 ALUOP_AND when IR_Op = INST_AND else
                 ALUOP_OR when IR_Op = INST_OR else
                 ALUOP_SHL when IR_Op = INST_SHL else
                 ALUOP_SHR when IR_Op = INST_SHR else
                 ALUOP_NOP; -- TODO: CALL/RET special stuff.


        SETC_Op <= '1' when IR_Op = INST_SETC else '0';
        CLRC_Op <= '1' when IR_Op = INST_CLRC else '0';
        Out_Op <= '1' when IR_Op = INST_OUT else '0';
        Push_Op <= '1' when IR_Op = INST_PUSH else '0';
        Load_Op <= '1' when IR_Op = INST_LDD else '0';
        STD_Op <= '1' when IR_Op = INST_STD else '0';
        Call_Op <= '1' when IR_Op = INST_CALL else '0';
        RET_Op <= '1' when IR_Op = INST_RET else '0';
        ITR_Op <= '1' when IR_Op = INST_ITR else '0';
        In_Op <= '1' when IR_Op = INST_IN else '0';
        LDM_Op <= '1' when IR_Op = INST_LDM else '0';
        Pop_Op <= '1' when IR_Op = INST_POP else '0';
        RTI_Op <= '1' when IR_Op = INST_RTI else '0';
        RestoreFlags <= '1' when IR_Op = INST_RET else '0';
        push_double <= '1' when IR_Op = INST_CALL or IR_Op = INST_ITR else '0';
        mem_load <= '1' when IR_Op = INST_POP or IR_Op = INST_LDD else '0';
        
        -- Combinational process that computes RTAddr, RSAddr, WBReg, RestoreFlags, and UpdateFlags.
        comp_control : process(IR_Op, IR, IR_short)
        begin
            ShiftAmt <= (others => '0');
            if IR_Op = INST_NOT or IR_Op = INST_INC or IR_Op = INST_DEC then
                -- ALUOp <= ALUOP_INC;
                RSAddr <= IR_short(10 downto 8); -- (others => '0');
                rs_read <= '1';
                RTAddr <= IR_short(10 downto 8);
                rt_read <= '0';
                WBReg <= '1';
                UpdateFlags <= '1';
            elsif IR_Op = INST_OUT or IR_Op = INST_PUSH then
                -- ALUOp <= ALUOP_PASSB;
                RSAddr <= (others => '0');
                rs_read <= '0';
                RTAddr <= IR_short(10 downto 8);
                rt_read <= '1';
                WBReg <= '0';
                UpdateFlags <= '0';
            elsif IR_Op = INST_STD then
                -- ALUOp <= ALUOP_PASSA;
                RSAddr <= IR_short(10 downto 8);
                rs_read <= '1';
                RTAddr <= IR_short(7 downto 5);
                rt_read <= '1';
                WBReg <= '0';
                UpdateFlags <= '0';
            elsif IR_Op = INST_IN or IR_Op = INST_POP or IR_Op = INST_LDM then
                -- ALUOp <= ALUOP_PASSB;
                RSAddr <= (others => '0');
                rs_read <= '0';
                RTAddr <= IR_short(10 downto 8);
                rt_read <= '0';
                WBReg <= '1';
                UpdateFlags <= '0';
            elsif IR_Op = INST_LDD then
                -- ALUOp <= ALUOP_PASSA
                RSAddr <= IR_short(10 downto 8);
                rs_read <= '1';
                RTAddr <= IR_short(7 downto 5);
                rt_read <= '0';
                WBReg <= '1';
                UpdateFlags <= '0';
            elsif IR_Op = INST_MOV then
                -- ALUOp <= ALUOP_PASSA;
                RSAddr <= IR_short(10 downto 8);
                rs_read <= '1';
                RTAddr <= IR_short(7 downto 5);
                rt_read <= '0';
                WBReg <= '1';
                UpdateFlags <= '0';
            elsif IR_Op = INST_SUB or IR_Op = INST_ADD or IR_Op = INST_AND or IR_Op = INST_OR then
                -- ALUOp <= ALUOP_SUB;
                RSAddr <= IR_short(10 downto 8);
                rs_read <= '1';
                RTAddr <= IR_short(7 downto 5);
                rt_read <= '1';
                WBReg <= '1';
                UpdateFlags <= '1';
            elsif IR_Op = INST_SHL or IR_Op = INST_SHR then
                -- ALUOp <= ALUOP_SHL;
                RSAddr <= IR_short(10 downto 8); --(others => '0');
                rs_read <= '1';
                RTAddr <= IR_short(10 downto 8);
                rt_read <= '0';
                WBReg <= '1';
                UpdateFlags <= '1';
                ShiftAmt <= IR_short(4 downto 1);
            elsif IR_Op = INST_JZ or IR_Op = INST_JN or IR_Op = INST_JC or IR_Op = INST_JMP or IR_Op = INST_CALL THEN
                -- ALUOp <= ALUOP_NOP;
                RSAddr <= (others => '0');
                rs_read <= '0';
                RTAddr <= IR_short(10 downto 8);
                rt_read <= '1';
                WBReg <= '0';
                UpdateFlags <= '0';
            elsif IR_Op = INST_SETC or IR_Op = INST_CLRC then
                -- ALUOp <= ALUOP_NOP
                RTAddr <= (others => '0');
                rt_read <= '0';
                RSAddr <= (others => '0');
                rs_read <= '0';
                WBReg <= '0';
                UpdateFlags <= '1';
            else
                -- ALUOp <= ALUOP_NOP;
                RTAddr <= (others => '0');
                rt_read <= '0';
                RSAddr <= (others => '0');
                rs_read <= '0';
                WBReg <= '0';
                UpdateFlags <= '0';
            end if;
        end process;
end Behavioral;