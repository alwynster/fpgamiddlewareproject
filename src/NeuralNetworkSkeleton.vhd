----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:00:45 12/20/2016 
-- Design Name: 
-- Module Name:    vector_dotproduct - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library fpgamiddlewarelibs;
use fpgamiddlewarelibs.UserLogicInterface.all;

library neuralnetwork;
use neuralnetwork.all;
use neuralnetwork.common.all;


entity NeuralNetworkSkeleton is
	port (
		-- control interface
		clock				: in std_logic;
		reset				: in std_logic; -- controls functionality (sleep)
		busy				: out std_logic; -- done with entire calculation
				
		-- indicate new data or request
		rd					: in std_logic;	-- request a variable
		wr 				: in std_logic; 	-- request changing a variable
		
		-- data interface
		data_in			: in uint8_t; -- std_logic_vector(31 downto 0);
		address_in		: in uint16_t;
		data_out			: out uint8_t -- std_logic_vector(31 downto 0)
	);
end NeuralNetworkSkeleton;

architecture Behavioral of NeuralNetworkSkeleton is

	signal learn			:  std_logic;
	signal data_rdy			:  std_logic;
	signal calculate		:  std_logic;
	
	signal connections_in	:  uintw_t;
	signal wanted			:  uintw_t;
	signal connections_out	:  uintw_t;
	signal run_counter		:  uintw_t;
	
begin

nn: entity neuralnetwork.NeuralNetwork(Behavioral)
	port map (clock, reset, learn, data_rdy, busy, calculate, connections_in, wanted, connections_out); -- done wired to busy
				
	-- process data receive 
	process (clock, rd, wr, reset)
	begin
		
		if reset = '1' then
			data_out <= (others => '0');
			calculate <= '0';
			run_counter <= (others => '0');
			-- done <= '0';
		else
		-- beginning/end
			if rising_edge(clock) then
				-- process address of written value
				
				calculate <= '0'; -- set to not calculate (can be overwritten below)
				
				if wr = '0' or rd = '0' then
					-- variable being set
					-- reverse from big to little endian
					if wr = '0' then
						case to_integer(address_in) is
						
						when 0 =>
							connections_in(w-1 downto 0) <= data_in(w-1 downto 0);
						when 1 =>
							wanted(w-1 downto 0) <= data_in(w-1 downto 0);
						when 2 => 
							learn <= data_in(0);
						-- when 107 =>
							calculate  <= '1'; -- trigger calculate high for one clock cycle
						when others =>
						end case;
					elsif rd = '0' then
						calculate <= '0';
						case to_integer(address_in) is
						-- inputA
						-- row 1
						when 0 =>
							data_out(w-1 downto 0) <= connections_in(w-1 downto 0);
						when 1 =>
							data_out(w-1 downto 0) <= wanted(w-1 downto 0);
						when 2 => 
							data_out <= (others => '0');
							data_out(0) <= learn;
						when 3 =>
							data_out(w-1 downto 0) <= connections_out(w-1 downto 0);
	
						when 255 => 
							data_out(w-1 downto 0) <= run_counter(w-1 downto 0);
						when others =>
							data_out <= to_unsigned(255, 8) - address_in(7 downto 0) + address_in(15 downto 8);
						end case;
					else
						calculate <= '0';
					end if;
				end if;
			end if;
		end if;
		-- intermediate_result_out <= intermediate_result;
	end process;
--	-- process data receive 
--	process (clock, enable, data_in.ready, current_receive_state)
--		variable column2 	: integer range 0 to numcols2 - 1 := 0;
--		variable row2		: integer range 0 to numrows2 - 1 := 0;
--		variable column1 	: integer range 0 to numcols1 - 1 := 0;
--		variable row1		: integer range 0 to numrows1 - 1 := 0;
--	
--		-- variable intermediate_result : MatrixMultiplicationPackage.outputMatrix := (others => (others => (others => '0')));
--		variable inputA : inputMatrix1 := (others => (others => (others => '0')));
--		variable inputB : inputMatrix2 := (others => (others => (others => '0')));
--		
--		variable first : boolean := false;
--		variable sendSize : boolean := false;
--	begin
--		if enable = '1' then
--			-- beginning/end
--			-- if run = '1' then
--				if rising_edge(clock) then
--					if current_receive_state = idle then
--						-- initiate all required variables
--						current_receive_state <= receiveA; -- begin operation
--						ready <= '1';
--						data_out.ready <= '0';
--						data_out.data <= (others => '0');
--						-- intermediate_result := (others => (others => (others => '0')));
--						done <= '0';
--						column2 := 0;
--						row2 := 0;
--						
--						column1 := 0;
--						row1 := 0;
--						
--					elsif current_receive_state = receiveDone then
--						data_out.ready <= '0';
--						if data_out_done = '1' then
--							current_receive_state <= idle;
--						end if;
--					-- perform the required calculations
--					elsif current_receive_state = calculating then
--						mm_enable <= '1';
--						
--						if mm_done = '1' then
--							intermediate_result_s <= output_s;
--							current_receive_state <= sendResult;
--							sendSize := true;
--							done <= '1';
--							row1 := 0;
--							column2 := 0;
--						end if;
--					-- respond to incoming data
--					elsif data_in.ready = '1' then
--						case current_receive_state is
--							when receiveA =>
--								ready <= '0';
--								done <= '0';
--							
--								inputA(row1)(column1) := data_in.data(15 downto 0);
--								
--								-- check if next row
--								if column1 < numcols1 - 1 then
--									column1 := column1 + 1;
--								else
--									column1 := 0;
--									
--									if row1 < numrows1 - 1 then
--										row1 := row1 + 1;
--									else
--										current_receive_state <= receiveB;
--										row1 := 0;
--										column1 := 0;
--									end if;
--								end if;								
--							when receiveB =>
--								inputB(row2)(column2) := data_in.data(15 downto 0);
--								
--								if column2 < numcols2 - 1 then
--									column2 := column2 + 1;
--								-- check if next row
--								else
--									column2 := 0;
--									if row2 < numrows2 - 1 then
--										row2 := row2 + 1;
--									else
--										current_receive_state <= calculating;
--										row2 := 0;
--										column2 := 0;
--										row1 := 0;
--									end if;
--								end if;												
--							when others => 
--								current_receive_state <= idle;
--						end case;
--					elsif current_receive_state = sendResult then
--						if sendSize then
--							sendSize := false;
--							data_out.data <= OUTPUT_SIZE;
--							data_out.ready <= '1';
--							-- first := true; -- ensure first datapoint is sent
--							
--						elsif data_out_done = '1' or first then
--							first := false;
--							
--							data_out.data <= intermediate_result_s(row1)(column2);
--							data_out.ready <= '1';
--							
--							-- find next datapoint
--							if column2 < numcols2 - 1 then
--								column2 := column2 + 1;
--							else
--									column2 := 0;
--									if row1 < numrows1 - 1 then
--										row1 := row1 + 1;
--									else
--										current_receive_state <= idle;
--										data_out.ready <= '0';
--										row1 := 0;
--										column2 := 0;
--									end if;
--							end if;
----						else
----							data_out_rdy <= '0';
--						end if;
--					end if;
--				-- end if;
--			end if;
--		else
--			data_out.ready <= '0';
--			data_out.data <= (others => '0');
--			done <= '0';
--			ready <= '0';
--			current_receive_state <= idle;
--			
--			mm_enable <= '0';
--		end if;
--		-- intermediate_result_s <= intermediate_result;
--		inputA_s <= inputA;
--		inputB_s <= inputB;
--	end process;
	
	-- ready <= '1' when enable = '1' and current_receive_state = receiveN else '0';
	-- calculate <= '1' when current_receive_state = calculating else '0';
end Behavioral;

