--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:43:09 05/15/2017
-- Design Name:   
-- Module Name:   /home/ES/burger/git/fpgamiddlewareproject/src/TestMiddleware.vhd
-- Project Name:  fpgamiddlewareproject
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: middleware
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
USE ieee.numeric_std.ALL;

library fpgamiddlewarelibs;
use fpgamiddlewarelibs.userlogicinterface.all;

ENTITY TestMiddleware IS
END TestMiddleware;
 
ARCHITECTURE behavior OF TestMiddleware IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT middleware
    PORT(
			reset : in std_logic;
         status_out : OUT  std_logic;
         config_sleep : OUT  std_logic;
         task_complete : OUT  std_logic;
         userlogic_reset : OUT  std_logic;
         userlogic_done : IN  std_logic;
         userlogic_sleep : OUT  std_logic;
         data_out_32 : OUT  uint32_t_interface;
         data_in_32 : IN  uint32_t_interface;
         data_in_32_done : OUT  std_logic;
         interface_leds : OUT  std_logic_vector(3 downto 0);
         clk : IN  std_logic;
         rx : IN  std_logic;
         tx : OUT  std_logic;
         sram_address : IN uint16_t;
         sram_data_out : OUT  uint8_t;
         sram_data_in : IN  uint8_t;
         sram_rd : IN  std_logic;
         sram_wr : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
	signal reset : std_logic;
   signal userlogic_done : std_logic := '0';
   signal data_in_32 : uint32_t_interface;
   signal clk : std_logic := '0';
   signal rx : std_logic := '0';
   signal sram_address : uint16_t := (others => '0');
   signal sram_data_in : uint8_t := (others => '0');
   signal sram_rd : std_logic := '0';
   signal sram_wr : std_logic := '0';

 	--Outputs
   signal status_out : std_logic;
   signal config_sleep : std_logic;
   signal task_complete : std_logic;
   signal userlogic_reset : std_logic;
   signal userlogic_sleep : std_logic;
   signal data_out_32 : uint32_t_interface;
   signal data_in_32_done : std_logic;
   signal interface_leds : std_logic_vector(3 downto 0);
   signal tx : std_logic;
   signal sram_data_out : uint8_t;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
	
	
-- procedures
	procedure write_uint8_t(constant data : in uint8_t; constant address : in uint16_t; signal address_out : out uint16_t; signal data_out : out uint8_t; signal wr : out std_logic) is
	begin
		address_out <= address;
		data_out <= data;
		wr <= '1';
		wait for clk_period;
		wr <= '0';
		wait for clk_period;
	end procedure;

	procedure write_uint24_t(constant data : in uint24_t; constant address : in uint16_t; signal address_out : out uint16_t; signal data_out : out uint8_t; signal wr : out std_logic) is
	begin
		write_uint8_t(data(7 downto 0), address, address_out, data_out, wr);
		write_uint8_t(data(15 downto 8), address + 1, address_out, data_out, wr);
		write_uint8_t(data(23 downto 16), address + 2, address_out, data_out, wr);
	end procedure;

	procedure write_uint32_t(constant data : in uint32_t; constant address : in uint16_t; signal address_out : out uint16_t; signal data_out : out uint8_t; signal wr : out std_logic) is
	begin
		write_uint8_t(data(7 downto 0), address, address_out, data_out, wr);
		write_uint24_t(data(31 downto 8), address + 1, address_out, data_out, wr);
	end procedure;
	
	
	signal busy : boolean := true;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: middleware PORT MAP (
			 reset => reset,
          status_out => status_out,
          config_sleep => config_sleep,
          task_complete => task_complete,
          userlogic_reset => userlogic_reset,
          userlogic_done => userlogic_done,
          userlogic_sleep => userlogic_sleep,
          data_out_32 => data_out_32,
          data_in_32 => data_in_32,
          data_in_32_done => data_in_32_done,
          interface_leds => interface_leds,
          clk => clk,
          rx => rx,
          tx => tx,
          sram_address => sram_address,
          sram_data_out => sram_data_out,
          sram_data_in => sram_data_in,
          sram_rd => sram_rd,
          sram_wr => sram_wr
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
		reset <= '1';
		wait for clk_period*10;
		reset <= '0';
		
      -- insert stimulus here \
		write_uint24_t(x"000000", x"0000", sram_address, sram_data_out, sram_wr);

		wait for clk_period * 12;
		busy <= false;
      wait;
   end process;

END;
