library ieee;
use ieee.std_logic_1164.all;
library orthrus;
use orthrus.Constants.all;

entity alsu is
    generic (N : natural);
    port (
        Sel         : in std_logic_vector(3 downto 0);
        A           : in std_logic_vector(N-1 downto 0);
        B           : in std_logic_vector(N-1 downto 0);
        Cin         : in std_logic;
        Imm         : in std_logic_vector(3 downto 0);
        F           : out std_logic_vector(N-1 downto 0);
        Cout        : out std_logic;
        Zero        : out std_logic;
        Negative    : out std_logic
    );
end alsu;

architecture structural of alsu is
    signal au_F, lu_F, su_F, temp_F : std_logic_vector(N-1 downto 0) := (others => 'Z');
    signal au_Cout, su_Cout : std_logic := 'Z';

    begin
        au_inst : entity orthrus.arithmetic_unit
        generic map (N => N)
        port map (
            Sel => Sel(1 downto 0),
            A => A,
            B => B,
            Cin => Cin,
            F => au_F,
            Cout => au_Cout
        );

        lu_inst : entity orthrus.logic_unit
        generic map (N => N)
        port map (
            Sel => Sel(1 downto 0),
            A => A,
            B => B,
            F => lu_F
        );

        su_inst : entity orthrus.shift_unit
        generic map (N => N)
        port map (
            Sel => Sel(0),
            A => A,
            Cin => Cin,
            Imm => Imm,
            F => su_F,
            Cout => su_Cout
        );

        Zero <= '1' when (temp_F = (N-1 downto 0 => '0')) else '0';
        Negative <= temp_F(N-1);
        Cout <= au_Cout when Sel(3 downto 2) = "01" else
                su_Cout when Sel(3 downto 1) = "100";

        temp_F <=   lu_F when Sel(3 downto 2) = "00" else
                    au_F when Sel(3 downto 2) = "01" else
                    su_F when Sel(3 downto 1) = "100";
                   
        F <=    B when Sel(3 downto 0) = "1010"else
                A when Sel(3 downto 0) = "1011" else
                temp_F;

end structural;