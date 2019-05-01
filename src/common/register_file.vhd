library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library orthrus;
use orthrus.Constants.all;

-- A two-port register file. Has an input, selection address, and an output from and to each port.
-- If both port 1 and port 2 try to write to the same address, port 2 is prioritized.
entity RegisterFile is
    generic (
        W       :   natural := 16; -- width of register
        L_BITS  :   natural := 3  -- number of bits required to address a register (i.e. log2(L) where L is the register length)
    );
    port (
        clk     :   in std_logic;
        reset   :   in std_logic;

        -- Port 1 signals
        read_1      :   in std_logic;
        write_1     :   in std_logic;
        sel_read_1  :   in std_logic_vector(L_BITS-1 downto 0);
        sel_write_1 :   in std_logic_vector(L_BITS-1 downto 0);
        data_in_1   :   in std_logic_vector(W-1 downto 0);
        data_out_1  :   out std_logic_vector(W-1 downto 0);

        -- Port 2 signals
        read_2      :   in std_logic;
        write_2     :   in std_logic;
        sel_read_2  :   in std_logic_vector(L_BITS-1 downto 0);
        sel_write_2 :   in std_logic_vector(L_BITS-1 downto 0);
        data_in_2   :   in std_logic_vector(W-1 downto 0);
        data_out_2  :   out std_logic_vector(W-1 downto 0)
    );
end RegisterFile;

architecture Behavioral of RegisterFile is
    type data_array is array(0 to 2**L_BITS-1) of std_logic_vector(W-1 downto 0);

    signal register_load  : std_logic_vector(2**L_BITS-1 downto 0);
    signal register_inputs : data_array;
    signal register_outputs : data_array;
    signal addr_write_1 : integer;
    signal addr_write_2 : integer;
    begin
        data_out_1 <= (others => '0') when read_1 = '0' else register_outputs(to_integer(unsigned(sel_read_1)));
        data_out_2 <= (others => '0') when read_2 = '0' else register_outputs(to_integer(unsigned(sel_read_2)));
        addr_write_1 <= to_integer(unsigned(sel_write_1));
        addr_write_2 <= to_integer(unsigned(sel_write_2));

        -- Computes the inputs to all the registers.
        comp_reg_input : process(write_1, addr_write_1, data_in_1, write_2, addr_write_2, data_in_2)
        begin
            for i in 0 to 2**L_BITS-1 loop
                if write_2 = '1' and i = addr_write_2 then -- Prioritize the second write first.
                    register_load(i) <= '1';
                    register_inputs(i) <= data_in_2;
                elsif write_1 = '1' and i = addr_write_1 then
                    register_load(i) <= '1';
                    register_inputs(i) <= data_in_1;
                else
                    register_load(i) <= '0';
                    register_inputs(i) <= data_in_2;
                end if;
            end loop;
        end process;
        
        regs: for i in 0 to 2**L_BITS-1 generate
            reg_inst  : entity orthrus.Reg
                generic map ( n => W )
                port map (
                    clk => clk,
                    load => register_load(i),
                    reset => reset,
                    d => register_inputs(i),
                    q => register_outputs(i),
                    rst_data => (others => '0')
                );
        end generate regs;
end Behavioral;