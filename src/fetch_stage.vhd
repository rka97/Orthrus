library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library orthrus;
use orthrus.Constants.all;

entity FetchStage is
    generic (
        N   : natural := 16; -- number of bits in word
        M   : natural := 16  -- number of bits in memory address
    );
    port (
        clk                 :   in std_logic;
        reset               :   in std_logic;

        -- memory signals
        read_mem            :   out std_logic;
        mem_data_in         :   in std_logic_vector(2*N-1 downto 0);
        mem_address_out     :   out std_logic_vector(M-1 downto 0);

        -- control signals
        stall               :   in std_logic;
        interrupt           :   in std_logic;
        branch              :   in std_logic;
        branch_address      :   in std_logic_vector(M-1 downto 0);
        wpc1_write          :   in std_logic;
        wpc2_write          :   in std_logic;

        -- the IRs and new_pc
        IR1                 :   out std_logic_vector(2*N-1 downto 0);
        IR2                 :   out std_logic_vector(2*N-1 downto 0);
        new_pc              :   out std_logic_vector(M-1 downto 0)
    );
end FetchStage;

architecture Behavioral of FetchStage is
    signal pc_data_in       : std_logic_vector(M-1 downto 0);
    signal pc_data_out      : std_logic_vector(M-1 downto 0);
    signal pc_load          : std_logic;
    signal increment        : integer range 0 to 2;
    signal incremented_pc   : std_logic_vector(M-1 downto 0);
    signal instr1_op        : std_logic_vector(4 downto 0);
    signal instr2_op        : std_logic_vector(4 downto 0);
    signal instr1           : std_logic_vector(N-1 downto 0);
    signal instr2           : std_logic_vector(N-1 downto 0);  
    constant NOP_FULL       : std_logic_vector(2*N-1 downto 0) := INST_NOP & (2*N-6 downto 0 => '0');
    
    function UsesMemory(
    instr_op : in std_logic_vector)
    return std_logic is
    begin
        if (instr_op = INST_PUSH or instr_op = INST_POP or instr_op = INST_LDD or instr_op = INST_STD or instr_op = INST_RET or instr_op = INST_RTI) then
            return '1';
        else
            return '0';
        end if;
    end UsesMemory;
begin
    PC_inst : entity orthrus.Reg
        generic map ( n => M )
        port map (
            clk => clk, d => pc_data_in, q => pc_data_out,
            rst_data => RESET_ADDR, load => pc_load, reset => reset
        );
    
    mem_address_out <= pc_data_out when reset = '0' and stall = '0' else (others => '0');
    read_mem <= '1' when reset = '0' and stall = '0' else '0';

    instr1_op <= mem_data_in(N-1 downto N-5);
    instr2_op <= mem_data_in(2*N-1 downto 2*N-5);

    instr1 <= mem_data_in(N-1 downto 0); -- first instruction
    instr2 <= mem_data_in(2*N-1 downto N); -- second instruction

    incremented_pc <= std_logic_vector(unsigned(pc_data_out) + to_unsigned(increment, M));
    new_pc <= pc_data_in;

    -- Combinational process that computes the new IRs and memory increment given the process.
    pre_decode : process(reset, interrupt, instr1_op, instr2_op, instr1, instr2)
    begin
        if reset = '1' or stall = '1' then
            IR1 <= NOP_FULL;
            IR2 <= NOP_FULL;
            increment <= 0;
        elsif interrupt = '1' then
            IR1 <= INST_ITR & (N-6 downto 0 => '0');
            IR2 <= NOP_FULL;
            increment <= 0;
        else
            if instr1_op = INST_LDM then -- If INST1 is immediate
                IR1 <= instr1 & instr2;
                IR2 <= NOP_FULL;
                increment <= 2;
            elsif instr2_op = INST_LDM then -- IF INST2 is immediate
                IR1 <= instr1 & (N-1 downto 0 => '0');
                IR2 <= NOP_FULL;
                increment <= 1;
            elsif instr1_op = INST_CALL then -- If INST1 is a CALL
                IR1 <= instr1 & (N-1 downto 0 => '0');
                IR2 <= NOP_FULL;
                increment <= 1;
            elsif (UsesMemory(instr1_op) = '1' and UsesMemory(instr2_op) = '1') then
                -- if both instructions use memory
                IR1 <= instr1 & (N-1 downto 0 => '0');
                IR2 <= NOP_FULL;
                increment <= 1;
            elsif instr1_op = INST_OUT and instr2_op = INST_OUT then
                -- If both instructions use the OUT port
                IR1 <= instr1 & (N-1 downto 0 => '0');
                IR2 <= NOP_FULL;
                increment <= 1;
            else
                IR1 <= instr1 & (N-1 downto 0 => '0');
                IR2 <= instr2 & (N-1 downto 0 => '0');
                increment <= 2;
            end if;
        end if;
    end process;

    -- TODO: Implement TakeMem (or look into what it did?).
    -- Combinational process that computes the New PC given the old PC and some control signals.
    comp_npc : process(incremented_pc, mem_data_in, stall, branch, branch_address, wpc1_write, wpc2_write)
    begin
        if stall = '1' or reset ='1' then -- On a stall or reset, do nothing.
            pc_load <= '0';
            pc_data_in <= (others => '0');
        elsif branch = '1' then -- Alter the PC to the branch address.
            pc_load <= '1';
            pc_data_in <= branch_address;
        elsif wpc1_write = '1' or wpc2_write = '1' then -- Take the PC address from the memory directly.
            pc_load <= '1';
            pc_data_in <= mem_data_in(2*N-1 downto M);
        else -- Take the incremented PC normally.
            pc_load <= '1';
            pc_data_in <= incremented_pc;
        end if;
    end process;



end Behavioral;