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
        A1    : in std_logic_vector(N-1 downto 0);
        B1    : in std_logic_vector(N-1 downto 0);
        F1    : out std_logic_vector(N-1 downto 0);
        Cw_1  : in std_logic_vector(2*N-1 downto 0);

        A2    : in std_logic_vector(N-1 downto 0);
        B2    : in std_logic_vector(N-1 downto 0);
        F2    : out std_logic_vector(N-1 downto 0);
        Cw_2  : in std_logic_vector(2*N-1 downto 0);

        clk   : in std_logic;
        reset : in std_logic;
        Flags : out std_logic_vector(N-1 downto 0)
    );
end ExecuteStage;

architecture structure of ExecuteStage is
    signal x1, x2 : std_logic_vector(N-1 downto 0) := (others => 'Z');
    signal y1, y2 : std_logic_vector(N-1 downto 0) := (others => 'Z');

    signal Cin1, Cin2 : std_logic := 'Z';
    signal result1, result2 : std_logic_vector(N-1 downto 0) := (others => 'Z');
    signal Carryout1, Carryout2 : std_logic := 'Z';
    
    signal flag_load : std_logic := 'Z';
    signal flag1,flag2 : std_logic_vector(2 downto 0) := (others => 'Z');
    signal flag_in,flag_out  : std_logic_vector(N-1 downto 0) := (others => '0');

    signal ret_flag_load : std_logic := 'Z';
    signal ret_flag_in, ret_flag_out : std_logic_vector(N-1 downto 0) := (others => '0');
    
    begin
        alsu_inst1 : entity orthrus.alsu
            generic map (N => N)
            port map (
                Sel => Cw_1(31 downto 28),
                A => A1,
                B => B1,
                Cin => Cin1,
                Imm => Cw_1(6 downto 3),
                F => F1,
                Cout => Carryout1,
                Zero => flag1(0),
                Negative => flag1(1)
            );
        flag1(2) <= '1' when Cw_1(8) = '1' else
                    '0' when Cw_1(7) = '1' else
                    Carryout1;

        alsu_inst2 : entity orthrus.alsu
            generic map (N => N)
            port map (
                Sel => Cw_2(31 downto 28),
                A => A2,
                B => B2,
                Cin => Cin2,
                Imm => Cw_2(6 downto 3),
                F => F2,
                Cout => Carryout2,
                Zero => flag2(0),
                Negative => flag2(1)
            );
        
        flag2(2) <= '1' when Cw_2(8) = '1' else
                    '0' when Cw_2(7) = '1' else
                    Carryout2;

        FlagReg_inst : entity orthrus.Reg
            generic map ( n => N )
            port map (
                clk => clk, d => flag_in, q => flag_out,
                rst_data => (others=>'0'), load => flag_load, reset => reset
            );

        flag_load <= Cw_1(9) or Cw_2(9);
        flag_in(2 downto 0) <=  ret_flag_out when Cw_2(13) = '1' else
                                flag2 when Cw_2(9) = '1' else
                                ret_flag_out when Cw_1(13) = '1' else
                                flag1 when Cw_1(9) = '1';
        

        Flags <= flag_in; --try it with flag_in

        TempFlagReg_inst : entity orthrus.Reg
            generic map ( n => N )
            port map (
                clk => clk, d => ret_flag_in, q => ret_flag_out,
                rst_data => (others=>'0'), load => ret_flag_load, reset => reset
            );
        ret_flag_load <= Cw_2(12) or Cw_1(12);
        ret_flag_in <= flag_out; --not sure that it should be from flag_out not flag_in

    sync_state : process(clk)
    begin
        if falling_edge(clk) then
            Cin1 <= flag_out(2);
            Cin2 <= flag_out(2);
        end if;
    end process;
end structure;