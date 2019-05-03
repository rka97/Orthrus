library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library orthrus;
use orthrus.Constants.all;

entity ExecuteStage is
    generic(
        N : natural := 16
    );
    port(
        Sel1        : in std_logic_vector(3 downto 0);
        A1          : in std_logic_vector(N-1 downto 0);
        B1          : in std_logic_vector(N-1 downto 0);
        Imm1        : in std_logic_vector(N-1 downto 0);
        F1          : out std_logic_vector(N-1 downto 0);
        SetC1       : in std_logic;
        ClrC1       : in std_logic;
        UpdateFlag1 : in std_logic;

        Sel2        : in std_logic_vector(3 downto 0);
        A2          : in std_logic_vector(N-1 downto 0);
        B2          : in std_logic_vector(N-1 downto 0);
        Imm2        : in std_logic_vector(N-1 downto 0);
        F2          : out std_logic_vector(N-1 downto 0);
        SetC2       : in std_logic;
        ClrC2       : in std_logic;
        UpdateFlag2 : in std_logic;

        clk         : in std_logic;
        reset       : in std_logic;
        Flags       : out std_logic_vector(N-1 downto 0)
    );
end ExecuteStage;

architecture structure of ExecuteStage is
    signal x1, x2 : std_logic_vector(N-1 downto 0) := (others => 'Z');
    signal y1, y2 : std_logic_vector(N-1 downto 0) := (others => 'Z');
    signal select1, select2 : std_logic_vector(3 downto 0) := (others => 'Z');
    signal Cin1, Cin2 : std_logic := 'Z';
    signal result1, result2 : std_logic_vector(N-1 downto 0) := (others => 'Z');
    signal Carryout1, Carryout2 : std_logic := 'Z';
    signal imm_value1, imm_value2 : std_logic_vector(N-1 downto 0) := (others => 'Z');
    
    signal flag_load : std_logic := 'Z';
    signal flag1,flag2 : std_logic_vector(2 downto 0) := (others => 'Z');
    signal flag_in,flag_out  : std_logic_vector(N-1 downto 0) := (others => '0');
    begin
        alsu_inst1 : entity orthrus.alsu
            generic map (N => N)
            port map (
                Sel => Sel1,
                A => A1,
                B => B1,
                Cin => Cin1,
                Imm => Imm1,
                F => F1,
                Cout => Carryout1,
                Zero => flag1(0),
                Negative => flag1(1)
            );
        flag1(2) <= '1' when SetC1 = '1' else
                    '0' when ClrC1 = '1' else
                    Carryout1;

        alsu_inst2 : entity orthrus.alsu
            generic map (N => N)
            port map (
                Sel => Sel2,
                A => A2,
                B => B2,
                Cin => Cin2,
                Imm => Imm2,
                F => F2,
                Cout => Carryout2,
                Zero => flag2(0),
                Negative => flag2(1)
            );
        
        flag2(2) <= '1' when SetC2 = '1' else
                    '0' when ClrC2 = '1' else
                    Carryout2;

        FlagReg_inst : entity orthrus.Reg
            generic map ( n => N )
            port map (
                clk => clk, d => flag_in, q => flag_out,
                rst_data => (others=>'0'), load => flag_load, reset => reset
            );

        flag_load <= UpdateFlag1 or UpdateFlag2;
        flag_in(2 downto 0) <=  flag2 when (UpdateFlag1 = '1' and UpdateFlag2 = '1') else
                                flag1 when UpdateFlag1 = '1' else
                                flag2 when UpdateFlag2 = '1';
        
        Flags <= flag_out;

    sync_state : process(clk)
    begin
        if falling_edge(clk) then
            Cin1 <= flag_out(2);
            Cin2 <= flag_out(2);
        end if;
    end process;
end structure;