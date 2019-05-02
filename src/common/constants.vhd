library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library orthrus;

package Constants is
    constant INST_NOP       :   std_logic_vector(4 downto 0) := "00000";
    constant INST_SETC      :   std_logic_vector(4 downto 0) := "00001";
    constant INST_CLRC      :   std_logic_vector(4 downto 0) := "00010";
    constant INST_NOT       :   std_logic_vector(4 downto 0) := "00011";
    constant INST_INC       :   std_logic_vector(4 downto 0) := "00100";
    constant INST_DEC       :   std_logic_vector(4 downto 0) := "00101";
    constant INST_OUT       :   std_logic_vector(4 downto 0) := "00110";
    constant INST_IN        :   std_logic_vector(4 downto 0) := "00111";
    constant INST_MOV       :   std_logic_vector(4 downto 0) := "01000";
    constant INST_ADD       :   std_logic_vector(4 downto 0) := "01001";
    constant INST_SUB       :   std_logic_vector(4 downto 0) := "01010";
    constant INST_AND       :   std_logic_vector(4 downto 0) := "01011";
    constant INST_OR        :   std_logic_vector(4 downto 0) := "01100";
    constant INST_SHL       :   std_logic_vector(4 downto 0) := "01101";
    constant INST_SHR       :   std_logic_vector(4 downto 0) := "01110";
    constant INST_PUSH      :   std_logic_vector(4 downto 0) := "01111";
    constant INST_POP       :   std_logic_vector(4 downto 0) := "10000";
    constant INST_LDM       :   std_logic_vector(4 downto 0) := "10001";
    constant INST_LDD       :   std_logic_vector(4 downto 0) := "10010";
    constant INST_STD       :   std_logic_vector(4 downto 0) := "10011";
    constant INST_JZ        :   std_logic_vector(4 downto 0) := "10100";
    constant INST_JN        :   std_logic_vector(4 downto 0) := "10101";
    constant INST_JC        :   std_logic_vector(4 downto 0) := "10110";
    constant INST_JMP       :   std_logic_vector(4 downto 0) := "10111";
    constant INST_CALL      :   std_logic_vector(4 downto 0) := "11000";
    constant INST_RET       :   std_logic_vector(4 downto 0) := "11001";
    constant INST_RTI       :   std_logic_vector(4 downto 0) := "11010";
    constant INST_ITR       :   std_logic_vector(4 downto 0) := "11011";
    constant RESET_ADDR     :   std_logic_vector(15 downto 0) := X"000A";
    -- TODO: implement the reset routine and change the reset address.
    constant CLK_PERIOD     :   time := 1 ns;
    constant ALUOP_NOT      :   std_logic_vector(3 downto 0) := "0000";
    constant ALUOP_INC      :   std_logic_vector(3 downto 0) := "0001";
    constant ALUOP_DEC      :   std_logic_vector(3 downto 0) := "0010";
    constant ALUOP_ADD      :   std_logic_vector(3 downto 0) := "0011";
    constant ALUOP_SUB      :   std_logic_vector(3 downto 0) := "0100";
    constant ALUOP_AND      :   std_logic_vector(3 downto 0) := "0101";
    constant ALUOP_OR       :   std_logic_vector(3 downto 0) := "0110";
    constant ALUOP_SHL      :   std_logic_vector(3 downto 0) := "0111";
    constant ALUOP_SHR      :   std_logic_vector(3 downto 0) := "1000";
    
end package;