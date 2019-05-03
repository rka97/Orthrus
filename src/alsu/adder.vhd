library ieee;
use ieee.std_logic_1164.all;
library orthrus;
use orthrus.Constants.all;

entity adder is
    generic (N : natural);
    port (
        A : in std_logic_vector(N-1 downto 0);
        B : in std_logic_vector(N-1 downto 0);
        Cin : in std_logic;
        Sum : out std_logic_vector(N-1 downto 0);
        Cout : out std_logic
    );
end adder;

architecture structural of adder is
    signal temp_cin : std_logic_vector(N downto 0) := (others => '0');

    begin
        temp_cin(0) <= Cin;
        fa_inst: for i in 0 to N-1 generate
            full_adder_inst: entity orthrus.full_adder
            port map (
                A => A(i),
                B => B(i),
                Cin => temp_cin(i),
                Sum => Sum(i),
                Cout => temp_cin(i+1)
            );
        end generate;
        Cout <= temp_cin(N);
end structural;