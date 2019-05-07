library ieee;
use ieee.std_logic_1164.all;
library orthrus;
use orthrus.Constants.all;

entity alsu_tb is
end alsu_tb;

architecture tb of alsu_tb is
    signal Sel : std_logic_vector(3 downto 0) := (others => 'Z');
    signal A : std_logic_vector(15 downto 0) := (others => 'Z');
    signal B : std_logic_vector(15 downto 0) := (others => 'Z');
    signal Cin : std_logic := 'Z';
    signal Imm : std_logic_vector(3 downto 0):= "0001";
    signal F : std_logic_vector(15 downto 0) := (others => 'Z');
    signal Cout, Zero, Negative : std_logic := 'Z';

    begin
        alsu_inst : entity orthrus.alsu
            generic map (N => 16)
            port map (
                Sel => Sel,
                A => A,
                B => B,
                Cin => Cin,
                Imm => Imm,
                F => F,
                Cout => Cout,
                Zero => Zero,
                Negative => Negative
            );

        process is
        begin
            -- total: 3+4+4=11 ns
            -- su
            A <= x"0002";
            Cin <= '0';
            Imm <= "0001";
            Sel <= "1000";--SHL
            wait for 1 ns;
            assert(F = X"0004") report "1st SHL failed!";
            assert(Cout = '0') report "Cout is wrong 1st SHL failed!";
            Sel <= "1001"; --SHR
            wait for 1 ns;
            assert(F = X"0001") report "2st SHR failed!";
            A <= x"9000";
            Cin <= '0';
            Imm <= "0011";
            Sel <= "1000";--SHL
            wait for 1 ns;
            assert(F = X"8000") report "3rd SHL failed!";
            assert(Cout = '0') report "Cout is wrong erd SHL failed!";
            -- -- au
            A <= x"0000";
            Cin <= '0';
            Sel <= "0100";
            wait for 1 ns;
            assert(F = X"0001") report "inc 0000  failed!";
            B <= x"0002";
            Sel <= "0110";
            wait for 1 ns;
            assert(F = X"0002") report "add 0+2 failed!";
            A <= x"ffff";
            Cin <= '0';
            Sel <= "0100";
            wait for 1 ns;
            assert(F = X"0000") report "inc ffff  failed!";
            assert(Cout = '1') report "cOUT IS WRONG IN inc ffff  failed!";
            A <= x"0002";
            Cin <= '0';
            Sel <= "0101";
            wait for 1 ns;
            assert(F = X"0001") report "dec 2 failed!";
            A <= x"0004";
            Cin <= '0';
            Sel <= "0111";
            wait for 1 ns;
            assert(F = X"0002") report "4-2 failed!";
            -- -- lu
            -- A <= x"0000";
            -- Cin <= '0';
            -- Sel <= "0000";
            -- wait for 1 ns;
            -- assert(F = (others <= 'Z')) report "NOP failed!";
            A <= x"0000";
            Cin <= '0';
            Sel <= "0001";
            wait for 1 ns;
            assert(F = X"ffff") report "not failed!";
            A <= x"0100";
            B <= x"1110";
            Cin <= '0';
            Sel <= "0010";
            wait for 1 ns;
            assert(F = X"0100") report "AND failed!";
            A <= x"0100";
            B <= x"1010";
            Cin <= '0';
            Sel <= "0011";
            wait for 1 ns;
            assert(F = X"1110") report "OR failed!";
            
        end process;
end tb;