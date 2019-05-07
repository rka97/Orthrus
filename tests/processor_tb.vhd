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
    constant period : time := 1 ns;

    begin
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
            reset <= '1';
            wait for period / 2;
            reset <= '0';
            wait for period;
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