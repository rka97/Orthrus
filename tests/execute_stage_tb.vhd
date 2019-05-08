library ieee;
use ieee.std_logic_1164.all;
library orthrus;
use orthrus.Constants.all;

entity ExecuteStageTB is
end ExecuteStageTB;

architecture TB of ExecuteStageTB is
    signal x1, x2 : std_logic_vector(15 downto 0) := (others => 'Z');
    signal y1, y2 : std_logic_vector(15 downto 0) := (others => 'Z');
    signal control_word_1, control_word_2 : std_logic_vector(2*N-1 downto 0);
    signal result1_in, result2_in : std_logic_vector(15 downto 0) := (others => 'Z');
    signal result1_out, result2_out : std_logic_vector(15 downto 0) := (others => 'Z');
    
    signal res1_load, res2_load : std_logic := '1';
    signal clk, reset : std_logic := 'Z';
    signal Flags : std_logic_vector(15 downto 0) := (others => 'Z');

    constant period : time := 1 ns;

    begin
        execute_stage_inst : entity orthrus.ExecuteStage
            generic map (N => 16)
            port map (
                A1 => x1,
                B1 => y1,
                Cw_1 => control_word_1,
                F1 => result1_in,
            
                A2 => x2,
                B2 => y2,
                Cw_2 => control_word_2,
                F2 => result2_in,
            
                clk => clk,
                reset => reset,
                Flags => Flags
            );

        Result1Reg_inst : entity orthrus.Reg
            generic map ( n => 16 )
            port map (
                clk => clk, d => result1_in, q => result1_out,
                rst_data => (others=>'0'), load => res1_load, reset => reset
            );

        Result2Reg_inst : entity orthrus.Reg
            generic map ( n => 16 )
            port map (
                clk => clk, d => result2_in, q => result2_out,
                rst_data => (others=>'0'), load => res2_load, reset => reset
            );

        process is
        begin
            reset <= '1';
            wait for 1 ns;
            reset <= '0';
            wait for 1 ns;
            control_word_1(6 downto 3) <= "0001"; --shift amount
            control_word_2(6 downto 3) <= "0001";
            -- total: 3+4+4=11 ns
            -- su
            x1 <= x"0002";
            control_word_1(31 downto 28) <= "1000";--SHL selection
            control_word_1(9) <= '1';
            
            control_word_2(9) <= '0';-- update_flag
            
            x2 <= x"0002";
            control_word_2(31 downto 28) <= "1001"; --SHR
            wait for 1 ns;
            assert(result1_out = X"0004") report "1st ALU, SHL failed!";
            assert(Flags(2) = '0') report "Cout#1 in 1st SHL failed!";
            assert(result2_out = X"0001") report "2nd ALU in SHR failed!";

            control_word_1(31 downto 28) <= "1001"; --SHR
            x2 <= x"0000";
            control_word_2(31 downto 28) <= "0100";
            wait for 1 ns;
            assert(result1_out = X"0001") report "1st ALU, SHR failed!";
            assert(result2_out = X"0001") report "2nd ALU, inc 0000  failed!";

            x1 <= x"9000";
            control_word_1(6 downto 3) <= "0011";
            control_word_1(31 downto 28) <= "1000";--SHL
            wait for 1 ns;
            assert(result1_out = X"8000") report "1st ALu, 2nd SHL failed!";
            assert(Flags(2) = '0') report "1st ALu, Cout in 2nd SHL failed!";
            -- -- au
            x1 <= x"0000";
            control_word_1(31 downto 28) <= "0100";
            wait for 1 ns;
            assert(result1_out = X"0001") report "1st ALu, inc 0000  failed!";

            y1 <= x"0002";
            control_word_1(31 downto 28) <= "0110";
            x2 <= x"0021";
            y2 <= x"4700";
            control_word_2(31 downto 28) <= "0010";
            control_word_1(9) <= '0';
            control_word_2(9) <= '1';
            wait for 1 ns;
            assert(result1_out = X"0002") report "1st ALu, add 0+2 failed!";
            assert(Flags(0) = '1') report "Zero Flag 2nd ALU in AND  failed!";
            x1 <= x"ffff";
            control_word_1(31 downto 28) <= "0100";
            control_word_1(9) <= '1';
            control_word_2(9) <= '0';
            wait for 1 ns;
            assert(result1_out = X"0000") report "1st ALu, inc ffff  failed!";
            assert(Flags(2) = '1') report "COUT1 IN inc ffff  failed!";
            control_word_1(7) <= '1';
            wait for 1 ns;
            assert(Flags(2) = '0') report "clear carry flag1 failed!";
            x1 <= x"0002";
            control_word_1(31 downto 28) <= "0101";
            x2 <= x"0021";
            y2 <= x"4700";
            control_word_2(31 downto 28) <= "0010";
            control_word_1(9) <= '1';
            control_word_2(9) <= '1';
            wait for 1 ns;
            assert(result1_out = X"0001") report "1st ALu, dec 2 failed!";
            assert(Flags(0) = '1') report "Priority Zero Flag 2nd ALU in AND  failed!";
            x1 <= x"0004";
            control_word_1(31 downto 28) <= "0111";
            wait for 1 ns;
            assert(result1_out = X"0002") report "4-2 failed!";
            -- -- lu
            -- x1 <= x"0000";
        
            -- control_word_1(31 downto 28) <= "0000";
            -- wait for 1 ns;
            -- assert(result1 = (others <= 'Z')) report "NOP failed!";
            x1 <= x"0000";
            control_word_1(31 downto 28) <= "0001";
            wait for 1 ns;
            assert(result1_out = X"ffff") report "not failed!";
            x1 <= x"0100";
            y1 <= x"1110";
            control_word_1(31 downto 28) <= "0010";
            wait for 1 ns;
            assert(result1_out = X"0100") report "AND failed!";
            x1 <= x"0100";
            y1 <= x"1010";
            control_word_1(31 downto 28) <= "0011";
            wait for 1 ns;
            assert(result1_out = X"1110") report "OR failed!";

            y1 <= x"0000";
            control_word_1(31 downto 28) <= "1010";
            wait for 1 ns;
            assert(result1_out = X"0000") report "pass B= zero failed!";
        
            x1 <= x"0100";
            y1 <= x"0002";
            control_word_1(31 downto 28) <= "0010";
            control_word_1(9) <= '1';
            control_word_2(9) <= '0';
            assert(result1_out = X"0000") report "And failed!";
            assert(Flags(0) = '1') report "Zero Flag  in AND  failed!";

            x1 <= x"0100";
            y1 <= x"1010";
            control_word_1(9) <= '1';
            control_word_2(9) <= '0';
            control_word_1(31 downto 28) <= "0011";
            wait for 1 ns;
            assert(result1_out = X"1110") report "OR failed!";
            assert(Flags(0) = '0') report "Zero Flag  in AND  failed!";

            x1 <= x"0100";
            y1 <= x"0100";
            control_word_1(9) <= '0';
            control_word_1(31 downto 28) <= "0111";
            wait for 1 ns;
            assert(result1_out = X"0000") report "SUB failed!";
            assert(Flags(0) = '0') report "Zero Flag  in SUB  failed!";

        end process;

        process is
            begin
                clk <= '0';
                wait for period / 2;
                clk <= '1';
                wait for period / 2;
            end process;
end TB;