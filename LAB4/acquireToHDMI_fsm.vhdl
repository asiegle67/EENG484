--------------------------------------------------------------------
-- Name:	Aaron and Nathan
-- Date:	Feb 3, 2015
-- File:	acquireToHDMI_fsm.vhdl
-- HW:	Lab2
--	Crs:	ECE 383
--
-- Purp: The control unit for the audio O'scope
--
-- Documentation:	No help, though I used an example from my Digital
--						Design text book.
--
-- Academic Integrity Statement: I certify that, while others may have 
-- assisted me in brain storming, debugging and validating this program, 
-- the program itself is my own work. I understand that submitting code 
-- which is the work of other individuals is a violation of the honor   
-- code.  I also understand that if I knowingly give my original work to 
-- another individual is also a violation of the honor code. 
------------------------------------------------------------------------- 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.acquireToHDMI_package.all;					-- include your library here with added components ac97, ac97cmd


entity acquireToHDMI_fsm is
    PORT (  clk : in  STD_LOGIC;
            resetn : in  STD_LOGIC;
            sw: in STD_LOGIC_VECTOR(SW_WIDTH - 1 downto 0);
            cw: out STD_LOGIC_VECTOR (CW_WIDTH - 1 downto 0));
end acquireToHDMI_fsm;

architecture Behavioral of acquireToHDMI_fsm is

	signal state: state_type;	-- define the state_type in your package file	
    signal SHORT_DELAY_DONE_SW, LONG_DELAY_DONE_SW, SAMPLE_SW, FULL_SW, AN7606_BUSY_SW: STD_LOGIC; 
	signal FORCED_MODE_SW, SINGLE_SW, STORE_INTO_BRAM_SW, CH1_TRIGGER_SW: STD_LOGIC;

begin

    SHORT_DELAY_DONE_SW <= sw(SHORT_DELAY_DONE_SW_BIT_INDEX);
    LONG_DELAY_DONE_SW <= sw(LONG_DELAY_DONE_SW_BIT_INDEX);
    SAMPLE_SW <= sw(SAMPLE_SW_BIT_INDEX);
    FULL_SW <= sw(FULL_SW_BIT_INDEX);
    STORE_INTO_BRAM_SW <= sw(STORE_INTO_BRAM_SW_BIT_INDEX);
    CH1_TRIGGER_SW <= sw(CH1_TRIGGER_SW_BIT_INDEX);
    AN7606_BUSY_SW <= sw(AN7606_BUSY_SW_BIT_INDEX);
    SINGLE_SW <= sw(SINGLE_FORCED_TRIGGER_SW_BIT_INDEX);
    FORCED_MODE_SW <= sw(FORCED_MODE_SW_BIT_INDEX);

    
	-------------------------------------------------------------------------------
	-------------------------------------------------------------------------------
	state_proces: process(clk)  
	begin
		if (rising_edge(clk)) then
			if (resetn = '0') then 
				state <= RESET_STATE;
			else 
				case state is				
					when RESET_STATE =>
                        state <= LONG_DELAY;
                    
                    when LONG_DELAY =>
                        if (LONG_DELAY_DONE_SW = '1') then 
                            state <= RESET_AD7606;
                    end if;    
                           
					when RESET_AD7606 =>
					   if (SHORT_DELAY_DONE_SW = '1') then
					       state <= WAIT_FORCED;
                    end if; 
                       
                    when WAIT_FORCED =>
                        if (FORCED_MODE_SW = '0') then
                            state <= CLEAR_STORE_FLAG;
                        elsif (SINGLE_SW '1') then
                            state <= SET_STORE_FLAG;
                    end if;
                    
                    when SET_STORE_FLAG =>
                        state <= BEGIN_CONVERSION;
                    
                    when CLEAR_STORE_FLAG =>
                        state <= BEGIN_CONVERSION;
                    
                    when BEGIN_CONVERSION =>
						state <= ASSERT_CONVST;
						
					when ASSERT_CONVST =>
						state <= BUSY_0;
						
					when BUSY_0 =>
                       if (AN7606_BUSY_SW = '1') then 
					       state <= BUSY_1; 
                       end if;
						
					when BUSY_1 =>
						if (AN7606_BUSY_SW = '0') then 
				            state <= READ_CH1_LOW; 
                        end if;

					when READ_CH1_LOW =>
						if (SHORT_DELAY_DONE_SW = '1') then
						    if (STORE_INTO_BRAM_SW = '1') then
						        state <= WRITE_CH1_BRAM;
						    else
						        state <= WRITE_CH1_TRIGGER;
						    end if;
						end if;
						
					when WRITE_CH1_TRIGGER =>
						state <= READ_CH1_HIGH;
						
					when WRITE_CH1_BRAM =>
						state <= READ_CH1_HIGH;
						
					when READ_CH1_HIGH =>
						state <= RESET_SHORT;
						
					when RESET_SHORT =>
						state <= READ_CH2_LOW;

					when READ_CH2_LOW =>
						if (SHORT_DELAY_DONE_SW = '1') then
						    if (STORE_INTO_BRAM_SW = '1') then
						        state <= WRITE_CH2_BRAM;
						    else
						        state <= WRITE_CH2_TRIGGER;
						    end if;
						end if;
						
					when WRITE_CH2_TRIGGER =>
						state <= READ_CH2_HIGH;
						
					when WRITE_CH2_BRAM =>
						state <= READ_CH2_HIGH;
						
					when READ_CH2_HIGH =>
						state <= WAIT_SAMPLE_END;

					when WAIT_SAMPLE_END =>
						if (SAMPLE_SW = '1') then
						    if (STORE_INTO_BRAM_SW = '1') then             -- filling the BRAM
						        if (FULL_SW = '1') then 
						            state <= BRAM_FULL;
						        else
						            state <= BEGIN_CONVERSION;
						        end if;
						    elsif (FORCED_MODE_SW = '1') then              -- user switched to forced while hunting
						        state <= WAIT_FORCED;
						    elsif (CH1_TRIGGER_SW = '1') then              -- trigger found, start storing
						        state <= SET_STORE_FLAG;
						    else                                           -- keep hunting
						        state <= BEGIN_CONVERSION;
						    end if;
						end if;
						
					when BRAM_FULL =>
						state <= WAIT_FORCED;
						 
           
				end case;
			end if;
		end if;
	end process;

	-------------------------------------------------------------------------------
    -- Dedicated Control Word spreadsheet
    -------------------------------------------------------------------------------
	output_process: process (state)
	begin
		case state is		           
            when RESET_STATE  =>  cw <= '0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'1'&'1'&'1'&'0'&"11"&"11"&"00"&"11"&"11";
            when LONG_DELAY  =>  cw <= '0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'1'&'1'&'1'&'0'&"00"&"00"&"00"&"10"&"11";
            when RESET_AD7606  =>  cw <= '0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'1'&'1'&'1'&'1'&"00"&"00"&"00"&"00"&"10";
            when WAIT_FORCED  =>  cw <= '0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'1'&'1'&'0'&"00"&"00"&"00"&"00"&"00";
            when SET_STORE_FLAG  =>  cw <= '0'&'1'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'1'&'1'&'0'&"00"&"00"&"00"&"00"&"00";
            when BEGIN_CONVERSION  =>  cw <= '0'&'0'&'0'&'0'&'1'&'1'&'0'&'0'&'0'&'1'&'1'&'0'&"00"&"11"&"00"&"00"&"00";
            when CLEAR_STORE_FLAG  =>  cw <= '1'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'1'&'1'&'0'&"00"&"00"&"00"&"00"&"00";
            when ASSERT_CONVST  =>  cw <= '0'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&'1'&'1'&'1'&'0'&"00"&"10"&"00"&"00"&"00";
            when BUSY_0  =>  cw <= '0'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&'1'&'1'&'1'&'0'&"00"&"10"&"00"&"00"&"00";
            when BUSY_1  =>  cw <= '0'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&'1'&'1'&'1'&'0'&"00"&"10"&"00"&"00"&"11";
            when READ_CH1_LOW  =>  cw <= '0'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&"00"&"10"&"00"&"00"&"10";
            when WRITE_CH1_TRIGGER  =>  cw <= '0'&'0'&'0'&'1'&'1'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&"00"&"10"&"00"&"00"&"00";
            when WRITE_CH1_BRAM  =>  cw <= '0'&'0'&'0'&'0'&'1'&'0'&'0'&'1'&'1'&'0'&'0'&'0'&"00"&"10"&"00"&"00"&"00";
            when READ_CH1_HIGH  =>  cw <= '0'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&'1'&'1'&'0'&'0'&"00"&"10"&"00"&"00"&"00";
            when RESET_SHORT  =>  cw <= '0'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&'1'&'1'&'0'&'0'&"00"&"10"&"00"&"00"&"11";
            when READ_CH2_LOW  =>  cw <= '0'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&"00"&"10"&"00"&"00"&"10";
            when WRITE_CH2_TRIGGER  =>  cw <= '0'&'0'&'1'&'0'&'1'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&"00"&"10"&"00"&"00"&"00";
            when WRITE_CH2_BRAM  =>  cw <= '0'&'0'&'0'&'0'&'1'&'0'&'1'&'0'&'1'&'0'&'0'&'0'&"10"&"10"&"00"&"00"&"00";
            when READ_CH2_HIGH  =>  cw <= '0'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&'1'&'1'&'1'&'0'&"00"&"10"&"00"&"00"&"00";
            when WAIT_SAMPLE_END  =>  cw <= '0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'1'&'1'&'0'&"00"&"10"&"00"&"00"&"00";
            when BRAM_FULL  =>  cw <= '0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'1'&'1'&'0'&"11"&"00"&"00"&"00"&"00";
		end case;
	end process;	                       

end Behavioral;



