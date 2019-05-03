library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library orthrus;
use orthrus.Constants.all;

entity arithmetic_unit is
    generic (N : natural);
    port (
        Sel : in std_logic_vector(1 downto 0);
        A : in std_logic_vector(N-1 downto 0);
        B : in std_logic_vector(N-1 downto 0);
        Cin : in std_logic;
        F : out std_logic_vector(N-1 downto 0);
        Cout : out std_logic
    );
end arithmetic_unit;

architecture behavioral of arithmetic_unit is

    signal temp_B : std_logic_vector(N-1 downto 0):= (others => 'Z');
    signal temp_C : std_logic := 'Z';
    signal temp_Sum : std_logic_vector(N-1 downto 0):= (others => 'Z');
    signal temp_F : std_logic_vector(N-1 downto 0):= (others => 'Z');
    begin
        adder_inst : entity orthrus.adder
            generic map (N => N)
            port map (
                A => A,
                B => temp_B,
                Cin => Cin,
                Sum => temp_Sum,
                Cout => temp_C
            );

        process(A, B, Cin, Sel)
        begin
            if (Sel = "00") then --inc A
                temp_B <= (N-1 downto 1 => '0')&'1';
            elsif (Sel = "01") then -- dec A
                temp_B <= (others => '1');
            elsif (Sel = "10") then --add
                temp_B <= B;
            elsif (Sel = "11") then --sub
                temp_B <= not B;
            end if;
        end process;

        F <= std_logic_vector(unsigned(temp_Sum)+1) when Sel = "11" else
        temp_Sum;
        Cout <= temp_C;
        
end behavioral;