----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:18:31 07/08/2015 
-- Design Name: 
-- Module Name:    SimulateLayer - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library fpgamiddlewarelibs;
use fpgamiddlewarelibs.userlogicinterface.all;

library neuralnetwork;
use neuralnetwork.Common.all;

entity TestHiddenLayers is
end TestHiddenLayers;

architecture Behavioral of TestHiddenLayers is	
	component HiddenLayers
	port (
		clk				:	in std_logic;

		n_feedback		:	in std_logic;
		current_layer	: 	in uint8_t;

		connections_in	:	in fixed_point_vector;
		connections_out	:	out fixed_point_vector;

		errors_in		:	in fixed_point_vector;
		errors_out		:	out fixed_point_vector
	);
	end component;
	
	component Distributor is
	port
	(
		clk				:	in std_logic;
		reset				: 	in std_logic;
		learn				:	in std_logic;
		calculate      :  in std_logic;
		n_feedback_bus	:	out std_logic_vector(l downto 0) := (others => 'Z'); -- l layers + summation (at l)
		
		n_feedback		: 	out std_logic;
		current_layer	:	out uint8_t;

		data_rdy       :  out std_logic;
		mode_out       :  out std_logic_vector(2 downto 0)
	);
	end component;


	signal clk : std_logic := '0';
	constant period : time := 100 ns;

	signal conn_in, conn_out : fixed_point_vector := (others => (others => '0'));
	signal err_in, err_out : fixed_point_vector := (others => (others => '0'));
	signal n_feedback : std_logic := 'Z';
	signal current_layer : uint8_t := (others => '0');

	signal errors_in		:	fixed_point_vector;
	signal connections_out	: 	fixed_point_vector;
	signal busy 	: boolean := true;
	
	signal reset, learn, calculate, data_rdy : std_logic := '0';
	signal n_feedback_bus : std_logic_vector(l downto 0);
begin
	
	process
	begin
		if busy then
			wait for period/2;
			clk <= not clk;
		else 
			wait;
		end if;
	end process;


	distr: Distributor port map
	(
		clk, reset, learn, calculate, n_feedback_bus, n_feedback, current_layer, data_rdy, open
	);
	
	uut : HiddenLayers port map (clk, n_feedback, current_layer, conn_in, conn_out, err_in, err_out);
	process begin
		reset <= '1';
		wait for period *2;
		reset <= '0';
		
		-- n_feedback <= 'Z';
		
		conn_in(0) <= real_to_fixed_point(1.0);
		conn_in(2) <= real_to_fixed_point(1.0);
		
		calculate <= '1';
		-- n_feedback <= '0';
		err_in(0) <= real_to_fixed_point(1.0);
		err_in(2) <= real_to_fixed_point(1.0);

		wait until data_rdy = '1';
		calculate <= '0';
		wait for period;
		-- wait for period * (l + 2);
		-- n_feedback <= '1';
		learn <= '1';
		calculate <= '1';
		-- wait for period * (l + 2);
		wait until data_rdy = '1';
		wait for period;
		
		
		-- n_feedback <= '0';
		--wait for period*4;
		-- n_feedback <= 'Z';
		wait for period*1;
		busy <= false;
		wait;
	end process;
end Behavioral;

