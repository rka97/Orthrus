library ieee;
use ieee.std_logic_1164.all;
library orthrus;
use orthrus.Constants.all;

entity full_adder is
    port (
        A, B, Cin : in std_logic;
        Sum, Cout : out std_logic
    );
end full_adder;

architecture dataflow of full_adder is
begin
    Sum <= A xor B xor Cin;
    Cout <= (A and B) or (Cin and (A xor B));
end dataflow;