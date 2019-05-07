library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library orthrus;
use orthrus.Constants.all;

entity shift_unit is
    generic (N : natural);
    port (
        Sel : in std_logic;
        A : in std_logic_vector(N-1 downto 0);
        Cin : in std_logic;
        Imm : in std_logic_vector(3 downto 0);
        F : out std_logic_vector(N-1 downto 0);
        Cout : out std_logic
    );
end shift_unit;

architecture behavioral of shift_unit is
    begin
        -- N-Imm_signal <= std_logic_vector(unsigned(N) - unsigned(Imm));
        process(Sel, A, Cin)
        begin
            if (Imm >= "0000") then 
                if (Sel = '0') then --shift left
                    Cout <= A(N-to_integer(unsigned(Imm)));
                    F <= A(N-to_integer(unsigned(Imm))-1 downto 0) & (to_integer(unsigned(Imm))-1 downto 0 => '0');
                else --(Sel = '1') then  --shift right
                    Cout <= A(to_integer(unsigned(Imm))-1);
                    F <= (to_integer(unsigned(Imm))-1 downto 0 => '0') & A(N-1 downto to_integer(unsigned(Imm)));
                end if;
            else
                Cout <= '0';           
            end if;
        end process;
end behavioral;