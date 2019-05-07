library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library orthrus;


entity WriteBackStage is
    generic (
        N   : natural := 16; -- number of bits in word
        M   : natural := 16  -- number of bits in memory address
    );
    port (
        clk                 :   in std_logic;
        reset               :   in std_logic;

        -- memory signals
        mem_data            : in std_logic_vector(N-1 downto 0);

        -- control signals
        control_word_1      : in std_logic_vector(31 downto 0);
        control_word_2      : in std_logic_vector(31 downto 0);
        -- the IRs and new_pc
        alu_res_1           : in std_logic_vector(N-1 downto 0);
        alu_res_2           : in std_logic_vector(N-1 downto 0);

        to_sp_write_1       : out std_logic;
        to_sp_1             : out std_logic_vector(N-1 downto 0);

        to_sp_write_2       : out std_logic;
        to_sp_2             : out std_logic_vector(N-1 downto 0);

        to_out_port_1       : out std_logic_vector(N-1 downto 0);
        to_out_port_2       : out std_logic_vector(N-1 downto 0);

        to_rf_write_data_1  : out std_logic_vector(N-1 downto 0);
        to_rf_write_1       : out std_logic;
        to_rf_write_sel_1   : out std_logic_vector(2 downto 0);

        to_rf_write_data_2  : out std_logic_vector(N-1 downto 0);
        to_rf_write_2       : out std_logic;
        to_rf_write_sel_2   : out std_logic_vector(2 downto 0)
    );
end WriteBackStage;

architecture Structural of WriteBackStage is

    --signal clk_ : std_logic;
  --  mem_data_ : std_logic_vector(N-1 downto 0);
    --control_word_1_ : std_logic_vector(31 downto 0);
    --control_word_2_: std_logic_vector(31 downto 0);
    --alu_res_1_ : std_logic_vector(N-1 downto 0);
    --alu_res_2_ : std_logic_vector(N-1 downto 0);




    signal to_out_port_1_1     : std_logic_vector(N-1 downto 0);
    signal to_out_port_2_2       : std_logic_vector(N-1 downto 0);
    signal to_rf_write_data_1_1  : std_logic_vector(N-1 downto 0);
    signal to_rf_write_1_1       : std_logic;
    signal to_rf_write_sel_1_1  : std_logic_vector(2 downto 0);
    signal to_rf_write_data_2_2  :  std_logic_vector(N-1 downto 0);
    signal to_rf_write_2_2       :  std_logic;
    signal to_rf_write_sel_2_2   :  std_logic_vector(2 downto 0);
    signal to_sp_write_1_1       : std_logic;
    signal to_sp_1_1             : std_logic_vector(N-1 downto 0);

    signal to_sp_write_2_2       : std_logic;
    signal to_sp_2_2             : std_logic_vector(N-1 downto 0);



    begin
        to_out_port_1 <=  to_out_port_1_1;      
        to_out_port_2 <= to_out_port_2_2;    
        to_rf_write_data_1 <= to_rf_write_data_1_1; 
        to_rf_write_1 <= to_rf_write_1_1;
        to_rf_write_sel_1 <=to_rf_write_sel_1_1 ;
        to_rf_write_data_2 <= to_rf_write_data_2_2 ;
        to_rf_write_2 <= to_rf_write_2_2 ;
        to_rf_write_sel_2 <= to_rf_write_sel_2_2 ; 
        to_sp_write_1 <= to_sp_write_1_1  ;   
        to_sp_1 <= to_sp_1_1;             
        to_sp_write_2 <= to_sp_write_2_2 ;    
        to_sp_2 <= to_sp_2_2;          
    
    
    wb_unit_1 : entity orthrus.WriteBackUnit 
    generic map( N => N, M =>M)
    port map(
    clk => clk,
    mem_data => mem_data,
    control_word => control_word_1,
    alu_res => alu_res_1,
    to_sp_write => to_sp_write_1_1,
    to_sp => to_sp_1_1,
    to_out_port => to_out_port_1_1,
    to_rf_write_data => to_rf_write_data_1_1,
    to_rf_write => to_rf_write_1_1,
    to_rf_write_sel => to_rf_write_sel_1_1
    );

    wb_unit_2: entity orthrus.WriteBackUnit 
    generic map( N => N, M =>M)
    port map(
    clk => clk,
    mem_data => mem_data,
    control_word => control_word_2,
    alu_res => alu_res_2,
    to_sp_write => to_sp_write_2_2,
    to_sp => to_sp_2_2,
    to_out_port => to_out_port_2_2,
    to_rf_write_data => to_rf_write_data_2_2,
    to_rf_write => to_rf_write_2_2,
    to_rf_write_sel => to_rf_write_sel_2_2
    );


    end Structural;
        
    
            





