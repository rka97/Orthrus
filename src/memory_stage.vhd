library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library orthrus;
--dont forget to forward signal to mem that decided whether it is inputing one word or two 
entity MemoryStage is
    generic (
        N   : natural := 16; -- number of bits in word.
        M   : natural := 16;  -- number of bits in memory address.
        buffer_unit   : natural := 32 -- size of buffer element
    );

    port (
        --Pipe1
        CW1 : in std_logic_vector(buffer_unit-1 downto 0);
        ar_S1: in std_logic_vector(N-1 downto 0);
        ar_T1: in std_logic_vector(N-1 downto 0);
        push_addr_1 : in std_logic_vector(M-1 downto 0);

        --Pipe2
        CW2 : in std_logic_vector(buffer_unit-1 downto 0);
        ar_S2: in std_logic_vector(N-1 downto 0);
        ar_T2: in std_logic_vector(N-1 downto 0);
        push_addr_2 : in std_logic_vector(M-1 downto 0);

        -- shared between pipes
        new_PC: in std_logic_vector(M-1 downto 0);

        -- Stage out
        PC_Write1: out std_logic; --for hazard detection unit
        PC_Write2: out std_logic;
        M_Addr: out std_logic_vector(M-1 downto 0);-- to mem
        M_Data: out std_logic_vector(buffer_unit-1 downto 0); --data to WRITE to mem
        M_Rqst_r: out std_logic; --to mem
        M_Rqst_w: out std_logic; --to mem
        M_write_double : out std_logic -- to mem
    );


end MemoryStage;



architecture bhv of MemoryStage is
    --Memory unit 1 out signals
    signal M_Rqst1_r: std_logic;
    signal M_Rqst1_w: std_logic;
    signal M_Addr1: std_logic_vector(M-1 downto 0);
    signal M_Data1: std_logic_vector(buffer_unit-1 downto 0);
    signal M_write_double_1 : std_logic;
    --Memory unit 2 out signals
    signal M_Rqst2_r: std_logic;
    signal M_Rqst2_w: std_logic;
    signal M_Addr2: std_logic_vector(M-1 downto 0);
    signal M_Data2: std_logic_vector(buffer_unit-1 downto 0);
    signal M_write_double_2 : std_logic;


    begin
        mem_unit1: entity orthrus.MemoryUnit
        generic map (N => N,M=>M, buffer_unit=>buffer_unit)
        port map (
            CW=>CW1,
            new_PC=>new_PC,
            push_addr=>push_addr_1,
            ar_S=>ar_S1,
            ar_T=>ar_T1,
            PC_Write=>PC_Write1,
            M_Rqst_r=>M_Rqst1_r,
            M_Rqst_w=>M_Rqst1_w,
            M_Addr=>M_Addr1,
            M_Data=>M_Data1,
            M_write_double => M_write_double_1
        );

        mem_unit2: entity orthrus.MemoryUnit
        generic map (N => N,M=>M, buffer_unit=>buffer_unit)
        port map (
            CW=>CW2,
            new_PC=>new_PC,
            push_addr=>push_addr_2,
            ar_S=>ar_S2,
            ar_T=>ar_T2,
            PC_Write=>PC_Write2,
            M_Rqst_r=>M_Rqst2_r,
            M_Rqst_w=>M_Rqst2_w,
            M_Addr=>M_Addr2,
            M_Data=>M_Data2,
            M_write_double => M_write_double_2
        );

        --Memory Manager
        M_Rqst_r<= '1' when ((M_Rqst1_r='1' and M_Rqst2_r='0') or (M_Rqst1_r='0' and M_Rqst2_r='1')) and M_Rqst1_w= '0' and M_Rqst2_w='0'
        else    '0';
        M_Rqst_w<= '1' when ((M_Rqst1_w='1' and M_Rqst2_w='0') or (M_Rqst1_w='0' and M_Rqst2_w='1'))and M_Rqst1_r='0' and M_Rqst2_r='0'
        else    '0';
        M_Data<=M_Data1 when (M_Rqst1_w='1' and M_Rqst2_w='0')
        else M_Data2 when (M_Rqst1_w='0' and M_Rqst2_w='1')
        else (others=>'0');
        M_Addr<= M_Addr1 when (M_Rqst1_r='1' or M_Rqst1_w='1') else 
                 M_Addr2 when (M_Rqst2_r='1' or M_Rqst2_w='1') else 
                 (others=>'0');
        M_write_double <= M_write_double_1 or M_write_double_2;

    end bhv;    