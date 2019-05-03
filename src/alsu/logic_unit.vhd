library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library orthrus;
use orthrus.Constants.all;

entity logic_unit is
    generic (N : natural);
    port (
        Sel : in std_logic_vector(1 downto 0);
        A : in std_logic_vector(N-1 downto 0);
        B : in std_logic_vector(N-1 downto 0);
        F : out std_logic_vector(N-1 downto 0)
    );
end logic_unit;

architecture dataflow of logic_unit is
    begin
        F <= (others => 'Z') when Sel="00" else --NOP
            not(A) when Sel = "01" else -- NOT A
            A and B when Sel = "10" else --AND
            A or B ;-- OR
end dataflow;