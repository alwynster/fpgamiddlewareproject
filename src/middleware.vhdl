library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use ieee.numeric_std.all;


library work;
use work.all;

library fpgamiddlewarelibs;

--!
--! @brief      Main class for connecting all the components involved in the
--!             middleware
--!
entity middleware is
	port (
		status_out		: out std_ulogic; 	--! Output to indicate activity

		config_sleep	: out std_logic := '0'; 	--! Configuration control to cause sleep for energy saving
		task_complete	: in std_logic;		--! Feedback from configuration about task completion
		
		spi_switch	: in std_logic;
		flash_cs		: out std_logic;
		flash_sck	: out std_logic;
		flash_mosi	: out std_logic;
		flash_miso	: in std_logic;

		ext_cs		: out std_logic;
		ext_sck		: out std_logic;
		ext_mosi		: out std_logic;
		ext_miso		: in std_logic;

		state_leds	: out std_logic_vector(3 downto 0);
		
		spi_en		: out std_logic;
		uart_en		: out std_logic;
	
		clk 			: in std_ulogic;	--! Clock 32 MHz
		rx				: in std_logic;
		tx 			: out std_logic;
		button		: in std_logic	
	);
end middleware;


architecture Behavioral of middleware is

signal clk_icap 				: std_logic := '0';
signal icap_en					: std_logic := '0';
signal multiboot_address	: std_logic_vector(23 downto 0);

signal incoming_data	 		: std_logic_vector(7 downto 0);
signal outgoing_data			: std_logic_vector(7 downto 0);
signal incoming_data_rdy	: std_logic;
signal outgoing_data_rdy	: std_logic := '0';
signal outgoing_data_done 	: std_logic := '0';

-- uart variables
signal uart_en_s					: std_logic := '0';
signal uart_data_in				: std_logic_vector(7 downto 0);
signal uart_data_in_rdy			: std_logic := '0';
signal uart_data_out				: std_logic_vector(7 downto 0);
signal uart_data_out_rdy		: std_logic := '0';
signal uart_data_in_done		: std_logic;

-- spi variables
signal spi_en_s		 	: std_logic := '0'; -- general enable to allow sending data
signal spi_data_in_rdy	: std_logic := '0'; -- stretched strobe to send a byte 
signal spi_strobe	: std_logic := '0'; -- a byte is available, toggle to show activity
signal spi_data_in 		: std_logic_vector(7 downto 0);
signal spi_data_out 		: std_logic_vector(7 downto 0);
signal spi_data_out_rdy : std_logic := '0';
signal spi_data_in_done	: std_logic;
signal spi_cs				: std_logic;
signal spi_sck				: std_logic;
signal spi_mosi			: std_logic;
signal spi_miso			: std_logic; 
 
begin
	--! Communication interface initialisation
	uart : entity fpgamiddlewarelibs.uartInterface(arch)
		generic map ( 278 )
		port map (
			rx_data => uart_data_out, --! 8-bit data received
			rx_rdy => uart_data_out_rdy,	--! received data ready
			tx_data => uart_data_in,	--! 8-bit data to be sent	
			tx_rdy => uart_data_in_rdy,
			tx_done => uart_data_in_done,
			--! physical interfaces
			i_uart_rx => rx,
			o_uart_tx => tx,
			clk => clk
		);
	uart_data_in_rdy <= outgoing_data_rdy and uart_en_s;
	uart_data_in <= outgoing_data;
	uart_en <= uart_en_s;

	-- outgoing_data <= multiboot_address(23 downto 16);
	
	--! ICAP interface initialisation
	process(clk)
	begin
		if clk'event and clk = '1' then
			clk_icap <= not clk_icap;
		end if;
	end process;
	
	status_out <= '1';

	fsm : entity work.CommunicationStateMachine(Behavioral)
		port map (
			clk => clk,
			reset => '0',
			
			data_in => incoming_data,
			data_in_rdy => incoming_data_rdy,
			data_out => outgoing_data,
			data_out_rdy => outgoing_data_rdy,
			data_out_done => outgoing_data_done,
			
			spi_en => spi_en_s,
			uart_en => uart_en_s,
			icap_en => icap_en,
			multiboot => multiboot_address,
			fpga_sleep => config_sleep,
			
			--debug
			ready => open,
			current_state => state_leds
		);
	incoming_data <= spi_data_out when spi_en_s = '1' else uart_data_out;
	incoming_data_rdy <= spi_data_out_rdy when spi_en_s = '1' else uart_data_out_rdy;
	outgoing_data_done <= spi_data_in_done when spi_en_s = '1' else uart_data_in_done;

	ic : entity fpgamiddlewarelibs.icapInterface(Behavioral)
		generic map (goldenboot_address => (others => '0')) 
		port map (clk => clk, enable => icap_en, status_running => open, multiboot_address => multiboot_address);

	--! SPI communication interface
	spi: entity fpgamiddlewarelibs.spiInterface(arch)
		generic map (
			prescaler => 4000000
		)
		port map(
		enable => spi_en_s,
		data_in => spi_data_in, -- data to be sent 
		data_out => spi_data_out, -- data received
		data_i_rdy => spi_data_in_rdy,
		data_i_req => spi_data_in_done,
		data_o_rdy => spi_data_out_rdy,
		clk => clk,

		--! SPI physical interfaces 
		spi_cs => spi_cs,
		spi_clk => spi_sck,
		spi_mosi => spi_mosi,
		spi_miso => spi_miso
	);
	
	spi_data_in <= outgoing_data;
	spi_data_in_rdy <= outgoing_data_rdy and spi_en_s;
	spi_en <= spi_en_s;

	-- both spi outputs synced
	ext_sck <= spi_sck;
	flash_sck <= spi_sck;
	ext_mosi <= spi_mosi;
	flash_mosi <= spi_mosi;
	-- select spi based on switch
	ext_cs <= spi_cs 				when spi_switch = '1' else '1'; -- active low
	flash_cs <= spi_cs 			when spi_switch = '0' else '1';
	spi_miso <= ext_miso 		when spi_switch = '1' else flash_miso;
	
end Behavioral;
