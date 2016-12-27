----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:56:23 10/04/2016 
-- Design Name: 
-- Module Name:    CommunicationStateMachine - Behavioral 
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

entity CommunicationStateMachine is
	port(
		clk					: in std_logic;							-- clock
		reset					: in std_logic;							-- reset everything
		
		data_in				: in std_logic_vector(7 downto 0);	-- data from controller
		data_in_rdy			: in std_logic;							-- new data avail to receive
		data_out				: out std_logic_vector(7 downto 0);	-- data to be sent 
		data_out_rdy		: out std_logic := '0';					-- new data avail to send
		data_out_done		: in std_logic;							-- data send complete
		data_in_32			: in std_logic_vector(31 downto 0);	-- data to be written to the uart by the middleware
		data_in_32_rdy 	: in std_logic;							-- data from ram is ready
		data_in_32_done	: out std_logic := '0';					-- data is done being written to ram
		data_out_32			: out std_logic_vector(31 downto 0);-- data to be written to the ram by the middleware
		data_out_32_rdy	: out std_logic := '0';					-- data for ram is ready (must be high at least one rising edge clock)
		
--		spi_en		: out std_logic := '0';					-- activate sending to spi
--		spi_continue: out std_logic := '0';					-- keep spi alive to keep reading/writing
--		spi_busy 	: in std_logic;
		uart_en				: out std_logic := '0';					-- activate sending to uart
		icap_en				: out std_logic := '0';
		multiboot			: out std_logic_vector(23 downto 0);-- for outputting new address to icap
		fpga_sleep			: out std_logic := '0';					-- put configuration to sleep
		userlogic_en		: out std_logic := '0'; 				-- communicate directly with userlogic
		userlogic_done		: in std_logic;							-- userlogic operations done
		
		--debug
		ready					: out std_logic;
		current_state 		: out std_logic_vector(3 downto 0)
	);
end CommunicationStateMachine;

architecture Behavioral of CommunicationStateMachine is

-- communication protocol
constant WRITE_FLASH 					: std_logic_vector(7 downto 0) := x"00"; --! header;24bit address;32bit size;data
constant READ_FLASH_REQUEST			: std_logic_vector(7 downto 0) := x"01"; --! header;24bit address;32bit size
constant WRITE_RAM						: std_logic_vector(7 downto 0) := x"03"; --! header;32bit address;32bit size;data
constant READ_RAM_RESPONSE				: std_logic_vector(7 downto 0) := x"05"; --! header;data
constant SET_NEXT_CONFIG_ADDRESS		: std_logic_vector(7 downto 0) := x"06"; --! header;24bit address;
constant SLEEP_FPGA						: std_logic_vector(7 downto 0) := x"08"; --! header
constant WAKE_FPGA						: std_logic_vector(7 downto 0) := x"09"; --! header

-- receiving fsm
type receive_state is (
	idle, 									-- 0
	receiving_flash_request_address, -- 1
	receiving_flash_request_size,    -- 2
	receiving_ram_write_address,		-- 3
	receiving_ram_write_size,    		-- 4
	receiving_ram_write_data,    		-- 5
	sending_flash_request, 				-- 6
	send_flash_response, 				-- 7
	receiving_next_config, 				-- 8
	send_icap_multiboot					-- 9
	);
signal current_receive_state: receive_state := idle;
signal state_count 			: integer range 0 to 16; --! count how many times this state has happened
-- sending fsm
type sending_state is (
	idle,
	sending_header,
	sending_data
	);
signal current_sending_state: sending_state := idle;

signal byte_count				: integer range 0 to 10 := 4;

-- intermediate signals for receiving data
signal flash_address 		: std_logic_vector(23 downto 0);
signal flash_size				: std_logic_vector(23 downto 0);

signal flash_man				: std_logic_vector(7 downto 0);
signal flash_dev	 			: std_logic_vector(15 downto 0);

signal ram_address, ram_size : unsigned(31 downto 0);

signal uart_buffer			: std_logic_vector(31 downto 0);

shared variable data_available		: boolean := false;
signal next_byte				: std_logic := 'Z';
signal current_byte			: integer range 0 to 5;	-- decides which byte to send of 32bit data, 0 is header and 5 is done
shared variable header_done 			: boolean := false;
signal data_out_done_toggle: std_logic := '0';

begin
	
--	newdataProcess: process ( data_in_32_rdy )
--	begin
--		if rising_edge(data_in_32_rdy) then
--			uart_buffer <= data_in_32;
--			new_32_bit_data <= '1';
--		end if;
--	end process;
	
	
	-- time 32 bit data to 8 bit by toggling a done signal
	convert8bit32bitProcess: process  (current_sending_state, data_out_done)
	begin
		-- if not currently sending, reset values
		if (current_sending_state = sending_header) or (current_sending_state = sending_data) then
			if rising_edge(data_out_done) then
				data_out_done_toggle <= not data_out_done_toggle;

				if current_byte = 5 then 
					-- data_out_rdy <= '0';
				else 
					-- data_out_rdy <= '1';
					current_byte <= current_byte + 1;
				end if;
				
--				case current_sending_state is
--				when sending_header =>
--					header_done := true;
--					-- bytecount := 0;
--					current_byte <= 0;
--				when sending_data =>
--					-- bytecount := bytecount + 1;
--					current_byte <= current_byte + 1;
--				when others => 
--				end case;
--				data_available := true;
			end if;
		else
			data_out_done_toggle <= '0';
			current_byte <= 0;
--			data_available := false;
--			header_done := false;
		end if;
	end process;		
	
	sendingProcess: process (reset, clk, data_in_32_rdy, data_out_done, userlogic_done)
		-- variable bytecount : integer range 0 to 4 := 4;
		-- variable data_available: boolean := false;
		variable userlogic_return : boolean := false;
	begin
		if reset = '0' then
			-- add return header to next incoming data
			if rising_edge(clk) then
				-- advance bytecount when readys
				case current_sending_state is
				when idle =>
					data_out_rdy <= '0';
					uart_en <= '0';
					data_in_32_done <= '0';
					if data_in_32_rdy = '1' then
						uart_buffer <= data_in_32;
						if userlogic_done = '1' then
							current_sending_state <= sending_header;
						else
							current_sending_state <= sending_data;
						end if;
					end if;
				when sending_header =>
					data_out_rdy <= '1';
					-- if data_ then
					data_out <= READ_RAM_RESPONSE;
					data_available := false;
					current_sending_state <= sending_data;
					uart_en <= '1';
					-- current_byte <= 1;					
					
--					end if;

				when sending_data =>
					data_out_rdy <= '1';
					uart_en <= '1';
					
					if data_out_done = '1' then
						case current_byte is
							when 1 =>
								data_out <= uart_buffer(31 downto 24);
							when 2 =>
								data_out <= uart_buffer(23 downto 16);
							when 3 =>
								data_out <= uart_buffer(15 downto 8);
							when 4 =>
								data_out <= uart_buffer(7 downto 0);
							when others =>
								data_in_32_done <= '1';
								-- data_out_rdy <= '0';
								current_sending_state <= idle;
						end case;
						-- current_byte <= current_byte + 1;
					end if;
				when others =>
					
				end case;
							
			end if;
		end if;
	end process;
	
	--! React to availability of new byte incoming
	receiveProcess: process (clk, data_in_rdy, reset, current_receive_state)
		-- variable ram_address, ram_size, ram_data : unsigned(31 downto 0);
		variable data_in_unsigned : unsigned(7 downto 0);
		variable ram_data_s : unsigned(31 downto 0);
		variable data_count : unsigned(31 downto 0);
	begin
		if reset = '1' then 
			current_receive_state <= idle;
			byte_count <= 0;
			state_count <= 0;
		elsif rising_edge(clk) then
			data_in_unsigned := unsigned(data_in);
			
			--! Respond based on what state the middleware is in 
			case current_receive_state is
				--! different states 
				when idle =>

					if data_in_rdy = '1' then
						byte_count <= byte_count + 1;

						--! see if new command is being received
						case data_in is
							when WRITE_RAM =>
								current_receive_state <= receiving_ram_write_address;
							when READ_FLASH_REQUEST =>
								current_receive_state <= receiving_flash_request_address;
							when SET_NEXT_CONFIG_ADDRESS =>
								current_receive_state <= receiving_next_config;
							when SLEEP_FPGA =>
								fpga_sleep <= '1';
							when WAKE_FPGA => 
								fpga_sleep <= '0';
							when others => 
						end case;
						state_count <= 0;
					end if;
				
					data_out_32_rdy <= '0';
					userlogic_en <= '0';
				
				-- ram write command
				when receiving_ram_write_address =>
					if data_in_rdy = '1' then

						state_count <= state_count + 1; --! only incremented at end of process
					
						case state_count is
							when 0 =>
								ram_address(31 downto 24) <= data_in_unsigned;
							when 1 =>
								ram_address(23 downto 16) <= data_in_unsigned;
							when 2 =>
								ram_address(15 downto 8) <= data_in_unsigned;
							when 3 =>
								ram_address(7 downto 0) <= data_in_unsigned;
								current_receive_state <= receiving_ram_write_size;
								state_count <= 0;
							when others =>
						end case;
					end if;
				when receiving_ram_write_size =>
					if data_in_rdy = '1' then

						state_count <= state_count + 1; --! only incremented at end of process
					
						case state_count is
							when 0 =>
								ram_size(31 downto 24) <= data_in_unsigned;
							when 1 =>
								ram_size(23 downto 16) <= data_in_unsigned;
							when 2 =>
								ram_size(15 downto 8) <= data_in_unsigned;
							when 3 =>
								ram_size(7 downto 0) <= data_in_unsigned;
								current_receive_state <= receiving_ram_write_data;
								state_count <= 0;
								data_count := (others => '0');
							when others =>
						end case;
					end if;
					
				when receiving_ram_write_data =>
					if data_in_rdy = '1' then

						data_count := data_count + 1;
						state_count <= state_count + 1; --! only incremented at end of process
						
						case state_count is
							when 0 =>
								ram_data_s(31 downto 24) := data_in_unsigned;
							when 1 =>
								ram_data_s(23 downto 16) := data_in_unsigned;
							when 2 =>
								ram_data_s(15 downto 8) := data_in_unsigned;
							when 3 =>
								ram_data_s(7 downto 0) := data_in_unsigned;
								
								if data_count = ram_size then
									current_receive_state <= idle;
								else
									userlogic_en <= '1';
								end if;
								
								state_count <= 0;
								
								-- present ram_data as ready
								data_out_32 <= std_logic_vector(ram_data_s);
								data_out_32_rdy <= '1';
							when others =>
						end case;
					else 
						data_out_32_rdy <= '0';
					end if;
					
				
--				-- read data from flash
--				when receiving_flash_request_address =>
--					if data_in_rdy = '1' then
--
--						state_count <= state_count + 1; --! only incremented at end of process
--					
--						case state_count is
--							when 0 =>
--								flash_address(23 downto 16) <= data_in;
--							when 1 =>
--								flash_address(15 downto 8) <= data_in;
--							when 2 =>
--								flash_address(7 downto 0) <= data_in;
--								current_receive_state <= receiving_flash_request_size;
--								state_count <= 0;
--							when others =>
--						end case;
--					end if;
--				when receiving_flash_request_size =>
--					if data_in_rdy = '1' then
--						state_count <= state_count + 1; --! only incremented at end of process
--
--						case state_count is
--							when 0 =>
--								flash_size(23 downto 16) <= data_in;
--							when 1 =>
--								flash_size(15 downto 8) <= data_in;
--							when 2 =>
--								flash_size(7 downto 0) <= data_in;
--								current_receive_state <= sending_flash_request;
--								state_count <= 0;
--							when others =>
--						end case;
--					end if;
--					
--				when sending_flash_request =>
--					case state_count is
--
--						when 0 => -- send 9f
--							-- assert cs low and connect spi data registers
--							spi_en <= '1';
--							
--							-- provide data
--							data_out <= x"9F";
--							data_out_rdy <= '1';
--							
--							state_count <= state_count + 1;
--						when 1 => 
--							-- wait for data to be start sending
--							data_out_rdy <= '0';
--							spi_en <= '0';
--							spi_continue <= '1'; -- make spi interface continue to receive
--							-- TODO: data_out_busy
--							if spi_busy = '1' then -- currently connected to spi di_req_o
--								state_count <= state_count + 1; --! only incremented at end of process
--							end if;
--						when 2 => 
--							-- wait for data to be done sending
--							if spi_busy = '0' then -- currently connected to spi di_req_o
--								state_count <= state_count + 1; --! only incremented at end of process
--							end if;
--						when 3 => -- receive first
--							spi_continue <= '0';
--							-- now wait for incoming data 1
--							if data_in_rdy = '1' then
--								flash_man <= data_in;
--								state_count <= state_count + 1;
--								spi_continue <= '0';
--							end if;
--						when 4 =>
--							-- wait for previous to end
--							if data_in_rdy = '0' then
--								state_count <= state_count + 1;
--							end if;
--						when 5 =>
--							-- now wait for incoming data 2
--							if data_in_rdy = '1' then
--								flash_dev(15 downto 8) <= data_in;
--								state_count <= state_count + 1;
--							end if;
--						when 6 =>
--							-- wait for previous to end
--							if data_in_rdy = '0' then
--								state_count <= state_count + 1;
--							end if;
--						when 7 =>
--							-- now wait for incoming data 3
--							if data_in_rdy = '1' then
--								flash_dev(7 downto 0) <= data_in;
--								current_receive_state <= send_flash_response;
--								state_count <= 0;
--								spi_en <= '0';
--							end if;
--						when others =>
--					end case;
--					
--				when send_flash_response =>
--					case state_count is
--						-- send first byte
--						when 0 =>
--							uart_en <= '1';
--							data_out <= flash_man;
--							data_out_rdy <= '1';
--							state_count <= state_count + 1;
--						when 1 =>
--							data_out_rdy <= '0';
--							if data_out_done = '1' then
--								current_receive_state <= Idle;
--								uart_en <= '0';
--							end if;
--						when others =>
--					end case;
				-- receive next multiboot address
				when receiving_next_config =>
					if data_in_rdy = '1' then
						--! receive a byte of config
						case state_count is
							when 0 =>
								multiboot(23 downto 16) <= data_in;
							when 1 =>
								multiboot(15 downto 8) <= data_in;
							when 2 =>
								multiboot(7 downto 0) <= data_in;
								current_receive_state <= send_icap_multiboot;
							when others =>
						end case;
						state_count <= state_count + 1;
					end if;
				when send_icap_multiboot =>
					-- set icap for one clock cycle
					current_receive_state <= idle;
				when others =>
					current_receive_state <= idle;
			end case;
		end if;
		current_state <= std_logic_vector(to_unsigned(receive_state'pos(current_receive_state), 4));

	end process;

icap_en <= '1' when current_receive_state = send_icap_multiboot else '0';
ready <= '1' when current_receive_state = idle else '0';
end Behavioral;

