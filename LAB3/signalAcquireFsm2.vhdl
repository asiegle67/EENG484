--------------------------------------------------------------------
-- Name:	Aaron and Nathan
-- Date:	Feb 3, 2015 
-- Modified:	Fall 2022
-- File:	lab2_fsm.vhdl
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
use work.signalAcquire_Package.all;		-- include your library here with added components ac97, ac97cmd

entity signalAcquire_Fsm is
    PORT (  clk : in  STD_LOGIC;
            resetn : in  STD_LOGIC;
            sw: in STD_LOGIC_VECTOR(SW_WIDTH - 1 downto 0);
            cw: out STD_LOGIC_VECTOR (CW_WIDTH - 1 downto 0));
end signalAcquire_Fsm;

architecture Behavioral of signalAcquire_Fsm is

	signal state: state_type;
	
	signal SHORT_DELAY_DONE_SW, LONG_DELAY_DONE_SW, START_CONVERSION_SW, BUSY_SW, ALL_CHANNELS_HAVE_BEEN_READ_SW : STD_LOGIC;

begin

    -- defining intuitive names for the status word bits to make interperting the
    -- logic in the state_process much easier and thus, you'll make fewer errors.
    SHORT_DELAY_DONE_SW <= sw(SHORT_DELAY_DONE_SW_BIT_INDEX);
    LONG_DELAY_DONE_SW <= sw(LONG_DELAY_DONE_SW_BIT_INDEX);
    START_CONVERSION_SW <= sw(START_CONV_SW_BIT_INDEX);
    BUSY_SW <= sw(BUSY_SW_BIT_INDEX);
    ALL_CHANNELS_HAVE_BEEN_READ_SW <= sw(ALL_CHANNELS_HAVE_BEEN_READ_SW_BIT_INDEX);
    
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
                    state <= POWER_UP_DELAY;
                
                -- conditional if delay is done for power up    
                when POWER_UP_DELAY =>
                    if (LONG_DELAY_DONE_SW = '1') then 
                        state <= RESET_AD7606_STATE;
                    end if;
                
                -- move to trigger once short delay done
                when RESET_AD7606_STATE =>
                    if (SHORT_DELAY_DONE_SW = '1') then 
                        state <= WAIT_TRIGGER;
                    end if;
                
                -- wait for the button trigger, if SW triggered if pressed 
                when WAIT_TRIGGER =>
                    if (START_CONVERSION_SW = '1') then 
                        state <= ASSERT_CONVST;
                    end if;
                
                -- start conversion state, low for one short delay
                when ASSERT_CONVST =>
                    if (SHORT_DELAY_DONE_SW = '1') then 
                        state <= WAIT_BUSY_0;
                    end if;
                    
                -- high edge starting the conversion process
                when WAIT_BUSY_0 =>
                    if (BUSY_SW = '1') then 
                        state <= WAIT_BUSY_1;
                    end if;
                    
                -- once fully converted, busy_sw = 0 which gives permission to move forward
                when WAIT_BUSY_1 =>
                    if (BUSY_SW = '0') then 
                        state <= WAIT_VALID_DATA;
                    end if;
                
                -- wait short delay 
                when WAIT_VALID_DATA =>
                    if (SHORT_DELAY_DONE_SW = '1') then 
                        state <= LATCH;
                    end if;
                    
                -- latch instantly goings to pause
                when LATCH =>
                    state <= PAUSE_BET_CHANNELS;
                
                -- pause between channels --> short delay
                when PAUSE_BET_CHANNELS =>
                    if (SHORT_DELAY_DONE_SW = '1') then 
                        state <= CLEAR_SHORT_CNT;
                    end if;
                
                -- see if all data has been transfered, if so wait for next button press, if not repeat data transfer
                when CLEAR_SHORT_CNT =>
                    if (ALL_CHANNELS_HAVE_BEEN_READ_SW = '1') then 
                        state <= WAIT_TRIGGER;
                    else 
                        state <= WAIT_VALID_DATA;
                    end if;
                    
				end case;
			end if;
		end if;
	end process;

    -------------------------------------------------------------------------------
    -- LPT: List all the bits of your control word and define their purpose.
    -- cw       Purpose
    -- 10       start conversion (convst bit)  
    -- 9        read cw bit, reading the data value
    -- 8        chip selected     
    -- 7        reset ad7606
    -- 6        write the file
    -- 5:4      register counter 
    -- 3:2      long delay done
    -- 1:0      short delay
    -- 
    -- LPT: Add the truth table for any BBB which are used in the datapath
    --  counter control     Function
    --          00              hold
    --          01              load
    --          10              inc
    --          11              reset   
    --
    -- cw bits:
    -- B"CONVST_RD_CS_RESETAD7606_WRITE_REGISTER_LONG_SHORT
    -------------------------------------------------------------------------------
	output_process: process (state)
	begin
	    case state is
                when RESET_STATE =>    cw <= B"1_1_1_0_0_11_11_11";
                when POWER_UP_DELAY =>    cw <= B"1_1_1_0_0_11_10_11";
                when RESET_AD7606_STATE =>    cw <= B"1_1_1_1_0_11_00_10";
                when WAIT_TRIGGER =>    cw <= B"1_1_1_0_0_11_11_11";
                when ASSERT_CONVST =>    cw <= B"0_1_1_0_0_00_11_10";
                when WAIT_BUSY_0 =>    cw <= B"1_1_1_0_0_00_11_11";
                when WAIT_BUSY_1 =>    cw <= B"1_1_1_0_0_00_11_11";
                when WAIT_VALID_DATA =>    cw <= B"1_0_0_0_0_00_11_10";
                when LATCH =>    cw <= B"1_0_0_0_1_00_11_11";
                when PAUSE_BET_CHANNELS =>    cw <= B"1_1_0_0_0_00_11_10";
                when CLEAR_SHORT_CNT =>    cw <= B"1_1_0_0_0_10_11_11";
		end case;
	end process;

end Behavioral;



