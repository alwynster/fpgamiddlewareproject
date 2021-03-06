-- TestBench Template 

  LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;

	library fpgamiddlewarelibs;
	use fpgamiddlewarelibs.UserLogicInterface.all;
  
  ENTITY TestVectorDotproduct IS
  END TestVectorDotproduct;
  
  

  ARCHITECTURE behavior OF TestVectorDotproduct IS 

		-- control interface
		signal clock			: std_logic := '0';
		signal reset 			: std_logic := '1';
		signal calculate		: std_logic; -- indicates the beginning and end
		signal ready 			: std_logic; -- indicates the device is ready to begin
		signal done				: std_logic; 

		signal vectorA,vectorB,result : unsigned(31 downto 0);
		
		-- data control interface
		signal data_out_rdy	:  std_logic;
		signal data_out_done : std_logic;
		signal data_in_rdy	: std_logic;
		
		constant clock_period : time := 100 ns;
		constant dimensions	: unsigned := to_unsigned(2, 32);
		signal sim_busy 		: boolean := true;
	BEGIN

		-- Component Instantiation
		uut: entity work.VectorDotproduct(Behavioral)
			port map (clock, reset, calculate, vectorA, vectorB, result);
		-- vdp: entity work.VectorDotproduct(Behavioral)
		--	port map (clock, enable, ready, done, data_out_rdy, data_out_done, data_in_rdy, data_in, data_out);
      
		clock_process : process
		begin
			if sim_busy then
				wait for clock_period;
				clock <= not clock;
			else
				wait;
			end if;
		end process;

		--  Test Bench Statements
		tb : PROCESS
		BEGIN
			reset <= '1';
			wait for 200 ns; -- wait until global set/reset completes
			
			reset <= '0';
			
			-- first num
			vectorA <= to_unsigned(10, 32);
			vectorB <= to_unsigned(5, 32);
			wait for clock_period;
			calculate <= '1';
			wait for clock_period;
			calculate <= '0';
			
			-- second num
			vectorA <= to_unsigned(6, 32);
			vectorB <= to_unsigned(10, 32);
			wait for clock_period;
			calculate <= '1';
			wait for clock_period;
			calculate <= '0';
			
			-- result
			wait for clock_period * 4;

			sim_busy <= false;

			wait; -- will wait forever
		END PROCESS tb;
		--  End Test Bench 

	END;