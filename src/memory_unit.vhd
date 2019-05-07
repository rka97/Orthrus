library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library orthrus;
-- use orthrus.Constants.all;

entity MemoryUnit is
    generic (
        N   : natural := 16; -- number of bits in word.
        M   : natural := 16;  -- number of bits in memory address.
        buffer_unit   : natural := 32 -- size of buffer element
    );

    port (
        CW : in std_logic_vector(buffer_unit-1 downto 0);
        new_PC: in std_logic_vector(M-1 downto 0);
        push_addr : in std_logic_vector(M-1 downto 0);
        ar_S: in std_logic_vector(N-1 downto 0);
        ar_T: in std_logic_vector(N-1 downto 0);


        PC_Write: out std_logic;
        M_Rqst_r: out std_logic;
        M_Rqst_w: out std_logic;
        M_Addr: out std_logic_vector(M-1 downto 0);
        M_Data: out std_logic_vector(buffer_unit-1 downto 0);
        M_write_double : out std_logic
    );


end MemoryUnit;


architecture bhv of MemoryUnit is
    signal PUSHop: std_logic;
    signal POPop: std_logic;
    signal LOADop: std_logic;
    signal STDop: std_logic;
    signal CALLop: std_logic;
    signal RETop : std_logic;
    signal INTop: std_logic;

    begin
        -- Specify needed signals
        (PUSHop,
        POPop,
        LOADop,
        STDop,
        CALLop,
        RETop)<= CW(19 downto 14);
        INTop <= CW(12); --NOTE? shouldnt be this the old pc

        --Set M_Rqst
        M_Rqst_r<= '1' when (POPop ='1' or LOADop ='1' or RETop ='1')
        else '0';

        M_Rqst_w<= '1' when (PUSHop ='1' or  STDop ='1'or CALLop='1' or   INTop ='1' )
        else '0';

        --Set M_Addr
        -- TODO: pad the memory addresses
        M_Addr<= push_addr when (PUSHop='1' or INTop='1' or CALLop='1') 
        else  ar_S when (POPop='1' or LOADop='1')
        else  ar_T when (STDop='1' or RETop='1')
        else (others=>'0');

        --Set M_Data
        M_Data<= (buffer_unit-1 downto N =>'0') & ar_T when PUSHop='1' 
        else    (buffer_unit-1 downto N =>'0') & ar_S when STDop='1'
        else    new_PC when (CALLop='1' or INTop='1')
        else (others=>'0');


        --Set PC_Write
        PC_Write<= '1' when RETop='1'
        else '0';

        M_write_double <= '1' when (CALLop='1' or INTop='1') else '0';
        
end bhv;




