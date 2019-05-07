library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library orthrus;

entity Ram is
	port (
		clk 					: in std_logic; -- the clock
		read_in					: in std_logic;
		write_in 				: in std_logic;
		write_double_in			: in std_logic;
		address_in              : in std_logic_vector(15 downto 0); -- 256 addresses.
		data_in                 : in std_logic_vector(31 downto 0);
		data_out                : out std_logic_vector(31 downto 0));
end entity Ram;

architecture Behavioral of Ram is
	type ram_type is array (0 to 65536-1) of std_logic_vector(15 downto 0);
	signal ram : ram_type := (
		--R0=0,...,R5=5
		0 => X"0000",
		1 => X"0000",
		2 => X"0002",
		3 => X"0003",
		4 => X"001A",
		5 => X"02A4",
		6 => X"0548",
		7 => X"1235",
		8 => X"0001",
		9 => X"0002",
		10 => X"0003",
		11 => X"0004",
		12 => X"0005",
		13 => X"0006",
		14 => X"0007",
		15 => X"0008", 
		16 => X"0009",
		others => X"BBBB"
	);
	begin
		-- Inputs data into the RAM on the falling edge of the clock.
		process(clk, write_in, write_double_in) is
			begin
				if falling_edge(clk) then  
					if write_in = '1' then
						if write_double_in = '0' then
							ram(to_integer(unsigned(address_in))) <= data_in(15 downto 0);
						else
							ram(to_integer(unsigned(address_in))) <= data_in(15 downto 0);
							ram(to_integer(unsigned(address_in) + 1)) <= data_in(31 downto 16);
						end if;
					end if;
				end if;
		end process;

		-- Outputs data asynchronously when the output is applied.
		data_out <= ram(to_integer(unsigned(address_in) + 1)) & ram(to_integer(unsigned(address_in))) when (read_in = '1') else (31 downto 0 => '0');
end Behavioral;