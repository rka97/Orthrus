library ieee, modelsim_lib;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use modelsim_lib.util.all;
library orthrus;
use orthrus.Constants.all;

entity MemoryStageTB is
end MemoryStageTB;

architecture TB of MemoryStageTB is

    --stage inputs 
    --Pipe1
    signal CW1 : std_logic_vector(32-1 downto 0);
    signal ar_S1:  std_logic_vector(16-1 downto 0);
    signal ar_T1: std_logic_vector(16-1 downto 0);

    --Pipe2
    signal CW2 :  std_logic_vector(32-1 downto 0);
    signal ar_S2: std_logic_vector(16-1 downto 0);
    signal ar_T2:  std_logic_vector(16-1 downto 0);
  
    -- shared between pipes
    signal new_PC: std_logic_vector(32-1 downto 0);
    signal SP: std_logic_vector(32-1 downto 0);

    --stage outputs
    signal PC_Write1: std_logic;
    signal PC_Write2:std_logic;
    signal M_Addr: std_logic_vector(16-1 downto 0);
    signal M_Data: std_logic_vector(32-1 downto 0);
    signal M_Rqst_r: std_logic;
    signal M_Rqst_w: std_logic;

    constant period : time := 1 ns;

    begin
    process is 
    begin
        --test memory operations!
        --push op
        CW1<=(32-1 downto 9=>'0')&"100000000";
        Cw2<=(others=>'0');
        ar_T1<=X"0004";
        SP<=X"00000007";
        wait for period;
        assert(M_Addr=X"0007" and M_Data=X"00000004" and M_Rqst_w='1') report "Problem in push op pipe 1!";
        wait for period;
        CW2<=(32-1 downto 9=>'0')&"100000000";
        Cw1<=(others=>'0');
        ar_T2<=X"0004";
        SP<=X"00000007";
        wait for period;
        assert( M_Addr=X"0007" and M_Data=X"00000004" and M_Rqst_w='1'and  M_Rqst_r='0') report "Problem in push op pipe 2!";
        wait for period;
        --trying both to write
        CW1<=(32-1 downto 9=>'0')&"100000000";
        CW1<=(32-1 downto 9=>'0')&"100000000";
        wait for period;
        assert( M_Rqst_w='0'and  M_Rqst_r='0') report "Dual access attempt not handeled";
        wait for period;
        --pop op
        CW1<=(32-1 downto 9=>'0')&"010000000";
        Cw2<=(others=>'0');
        ar_S1<=X"0009";
        wait for period;
        assert( M_Addr=X"0009" and M_Data=(31 downto 0=>'0') and M_Rqst_r='1'and  M_Rqst_w='0') report "Problem in pop op pipe 1!";
        wait for period;
        --both trying to read
        CW1<=(32-1 downto 9=>'0')&"010000000";
        CW2<=(32-1 downto 9=>'0')&"010000000";
        wait for period;
        assert( M_Rqst_r='0'and  M_Rqst_w='0') report "Problem in pop op both pipes!";
        wait for period;
        --read and write ops on same pipe
        CW1<=(32-1 downto 9=>'0')&"010000000";
        CW1<=(32-1 downto 9=>'0')&"100000000";
        wait for period;
        assert( M_Rqst_r='0' and  M_Rqst_w='0') report "Problem in read and write in diff pipes!";
        wait for period;    
        --ldmop
        CW1<=(32-1 downto 9=>'0')&"000000010";
        CW2<=(others=>'0');
        ar_S1<=X"0002";
        wait for period;
        assert( M_Addr=X"0002" and M_Rqst_r='1'and  M_Rqst_w='0') report "Problem in ldm op in pipe!";
        wait for period;
        --ldop
        CW1<=(32-1 downto 9=>'0')&"001000000";
        CW2<=(others=>'0');
        ar_S1<=X"0003";
        wait for period;
        assert( M_Addr=X"0003" and M_Rqst_r='1'and  M_Rqst_w='0') report "Problem in ld op in pipe1!";
        wait for period;
        --std op
        CW1<=(32-1 downto 9=>'0')&"000100000";
        Cw2<=(others=>'0');
        ar_T1<=X"0004";
        ar_S1<=X"0005";
        wait for period;
        assert( M_Addr=X"0004" and M_Data=X"00000005" and M_Rqst_w='1') report "Problem in std op pipe 1!";
        wait for period;
        --call op
        CW1<=(32-1 downto 9=>'0')&"000010000";
        Cw2<=(others=>'0');
        SP<=X"00000009";
        new_PC<=X"00000003";
        wait for period;
        assert( M_Addr=X"0009" and M_Data=X"00000003" and M_Rqst_w='1') report "Problem in call op pipe 1!";
        wait for period;
        --ret op
        CW1<=(32-1 downto 9=>'0')&"000001000";
        Cw2<=(others=>'0');
        SP<=X"00000004";
        wait for period;
        assert(M_Addr=X"0004" and M_Rqst_r='1'and PC_Write1='1') report "Problem in ret op pipe 1!";
        wait for period;
        --int op
        CW1<=(32-1 downto 9=>'0')&"000000100";
        Cw2<=(others=>'0');
        SP<=X"00000004";
        new_PC<=X"00000002";
        wait for period;
        assert( M_Addr=X"0004" and M_Data=X"00000002"and M_Rqst_w='1') report "Problem in int op pipe 1!";
        wait for period;
    end process;

        mem_stage: entity orthrus.MemoryStage
        generic map (N => 16,M=>16, buffer_unit=>32)
        port map (
            
        CW1 =>CW1,
        ar_S1=>ar_S1,
        ar_T1=>ar_T1,
        CW2 =>CW2 ,
        ar_S2=>ar_S2,
        ar_T2 =>ar_T2 ,
        new_PC=>new_PC,
        SP=>SP,
        PC_Write1=> PC_Write1,
        PC_Write2=> PC_Write2,
        M_Addr=>M_Addr,
        M_Data=>M_Data,
        M_Rqst_r=>M_Rqst_r,
        M_Rqst_w=>M_Rqst_w
        );

        
    




    end TB;