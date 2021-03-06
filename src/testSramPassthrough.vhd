--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:54:19 04/25/2017
-- Design Name:   
-- Module Name:   /home/ES/burger/git/sramSlave/testSramPassthrough.vhd
-- Project Name:  sramSlave
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: sramPassthrough
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY testSramPassthrough IS
END testSramPassthrough;
 
ARCHITECTURE behavior OF testSramPassthrough IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT sramPassthrough
    PORT(
         clk : IN  std_logic;
         ARD_RESET : OUT  std_logic;
         mcu_ad : INOUT  std_logic_vector(7 downto 0);
         mcu_ale : IN  std_logic;
         mcu_a : IN  std_logic_vector(15 downto 8);
         mcu_rd : IN  std_logic;
         mcu_wr : IN  std_logic;
         leds : OUT  std_logic_vector(3 downto 0);
         rx : IN  std_logic;
         tx : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal mcu_ale : std_logic := '0';
   signal mcu_a : std_logic_vector(15 downto 8) := (others => '0');
   signal mcu_rd : std_logic := '1';
   signal mcu_wr : std_logic := '1';
   signal rx : std_logic := '0';

	--BiDirs
   signal mcu_ad : std_logic_vector(7 downto 0);

 	--Outputs
   signal ARD_RESET : std_logic;
   signal leds : std_logic_vector(3 downto 0);
   signal tx : std_logic;

   -- Clock period definitions
   constant clk_period : time := 31.25 ns;
	constant mcu_clk : time := 62.5 ns;
 
	signal busy : boolean := true;
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: sramPassthrough PORT MAP (
          clk => clk,
          ARD_RESET => ARD_RESET,
          mcu_ad => mcu_ad,
          mcu_ale => mcu_ale,
          mcu_a => mcu_a,
          mcu_rd => mcu_rd,
          mcu_wr => mcu_wr,
          leds => leds,
          rx => rx,
          tx => tx
        );

   -- Clock process definitions
   clk_process :process
   begin
		if busy then
			clk <= '0';
			wait for clk_period/2;
			clk <= '1';
			wait for clk_period/2;
		else 
			wait;
		end if;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for mcu_clk / 2;
		mcu_ale <= '1';
		wait for mcu_clk / 2;
		mcu_a <= x"AB";
		mcu_ad <= x"CD";
		wait for mcu_clk / 2;
		mcu_ale <= '0';
		wait for mcu_clk / 2;
		mcu_rd <= '0';
		mcu_ad <= (others => 'Z');
		wait for mcu_clk;
		mcu_rd <= '1';

		wait for mcu_clk * 4;
		mcu_wr <= '0';
		mcu_ad <= x"EF";
		wait for mcu_clk;
		mcu_wr <= '1';
		
      -- wait for clk_period*10;
		-- wait until tx_done = '1';
		wait for clk_period*100;

      -- insert stimulus here 
		
		busy <= false;
      wait;
   end process;

END;
