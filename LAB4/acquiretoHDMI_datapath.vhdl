--------------------------------------------------------------------
-- Name:	Chris Coulston
-- Date:	Feb 3, 2015
-- Modified:	Sept 2022
-- File:	acquireToHDMI_Datapath.vhdl
-- HW:		Lab 3
-- Crs:		ECE 383 and EENG 484
--
-- Purp: The complete datapath for the audio O'scope
--
-- Documentation:	No help
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
use IEEE.NUMERIC_STD.ALL;

use work.acquireToHDMI_Package.all;			
use work.basicBuildingBlocks_package.all;		
use work.scopeToHdmi_package.all;

entity acquireToHDMI_datapath is
    PORT ( clk : in  STD_LOGIC;
           resetn : in  STD_LOGIC;
		   cw : in STD_LOGIC_VECTOR(CW_WIDTH -1 downto 0);
		   sw : out STD_LOGIC_VECTOR(DATAPATH_SW_WIDTH - 1 downto 0);
		   an7606data: in STD_LOGIC_VECTOR(15 downto 0);

           triggerVolt16bitSigned: in SIGNED(15 downto 0);
		   triggerTimePixel: in STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0);
		   ch1Data16bitSLV, ch2Data16bitSLV: out STD_LOGIC_VECTOR(15 downto 0);
		   
		   tmdsDataP : out  STD_LOGIC_VECTOR (2 downto 0);
           tmdsDataN : out  STD_LOGIC_VECTOR (2 downto 0);
           tmdsClkP : out STD_LOGIC;
           tmdsClkN : out STD_LOGIC;
           hdmiOen:    out STD_LOGIC
		   );
end acquireToHDMI_datapath;

architecture behavior of acquireToHDMI_datapath is

-- SR Latch
    signal storeIntoBramFlag: STD_LOGIC;
      

    
begin

    -- Simple SR Latch to assist FSM
    process(clk)
    begin
        if(rising_edge(clk)) then
            if(resetn ='0') then
                storeIntoBramFlag <= '0';
            elsif (cw(SET_STORE_FLAG_CW_BIT_INDEX) = '1') then
                storeIntoBramFlag <= '1';
            elsif (cw(CLEAR_STORE_FLAG_CW_BIT_INDEX) = '1') then
                storeIntoBramFlag <= '0';
            end if;
        end if;
    end process;

    sw(STORE_INTO_BRAM_SW_BIT_INDEX) <= storeIntoBramFlag;
    
-- LAB 3 CODE
    shortDelay : genericCounter
        GENERIC MAP (SHORT_DELAY_50Mhz_CONST_WIDTH)
        PORT MAP (clk => clk, 
            resetn => resetn, 
            c => cw(SHORT_DELAY_COUNTER_CW_BIT_INDEX+1 downto SHORT_DELAY_COUNTER_CW_BIT_INDEX), 
            d=> (others => '0'), 
            q => shortDelayCounter
            );
    
    shortCompare : genericCompare
        GENERIC MAP (SHORT_DELAY_50Mhz_CONST_WIDTH)
        PORT MAP (x => shortDelayCounter,
            y => SHORT_DELAY_50Mhz_COUNTS,
            g => open,
            l => open,
            e => shortDelayDone
            );
    -- when short delay is finished, send back to sw    
    sw(SHORT_DELAY_DONE_SW_BIT_INDEX) <= shortDelayDone;
    
    longDelay : genericCounter
        GENERIC MAP (LONG_DELAY_50Mhz_CONST_WIDTH)
        PORT MAP (clk => clk, 
            resetn => resetn, 
            c => cw(LONG_DELAY_COUNTER_CW_BIT_INDEX+1 downto LONG_DELAY_COUNTER_CW_BIT_INDEX), 
            d=> (others => '0'), 
            q => longDelayCounter
            );
    
    longCompare : genericCompare
        GENERIC MAP (LONG_DELAY_50Mhz_CONST_WIDTH)
        PORT MAP (x => longDelayCounter,
            y => LONG_DELAY_50Mhz_COUNTS,
            g => open,
            l => open,
            e => longDelayDone
            );
    -- when long delay is finished, send back to sw    
    sw(LONG_DELAY_DONE_SW_BIT_INDEX) <= longDelayDone;
    
-- sample interval timer 
-- 00 highest, 01 = high, 10 = low, 11 = lowest   (Aaron ???)
    sampleCounter : genericCounter
        GENERIC MAP (SAMPLE_TIMER_WIDTH)
        PORT MAP (clk => clk,
            c => cw(SAMPLING_COUNTER_CW_BIT_INDEX+1 downto SAMPLING_COUNTER_CW_BIT_INDEX),
            d => (others => '0'),
            q => timerCounter
            );
    
    sampleRateMux : genericMux4x1
        GENERIC MAP (SAMPLE_TIMER_WIDTH)
        PORT MAP (s => cw(SAMPLING_COUNTER_CW_BIT_INDEX+1 downto SAMPLING_COUNTER_CW_BIT_INDEX),
            y3 => LOWEST_RATE,
            y2 => LOW_RATE,
            y1 => HIGH_RATE,
            y0 => HIGHEST_RATE,
            f => sampleTimerCounts,
            );
    
    sampleCompare : genericCompare
        GENERIC MAP (SAMPLE_TIMER_WIDTH)
        PORT MAP (x => timerCounter,
            y => sampleRateCounts,
            g => sampleTimerGreater,
            l => open,
            e => sampleTimerEqual
            );
     
     sw(SAMPLE_SW_BIT_INDEX) <= sampleTimerGreater or sampleTimerEqual;
     
     
            
    
    
    
    
    
    
    vc: clk_wiz_0
        PORT MAP (
            clk_in1 => clk,
            clk_out1 => videoClk,
            resetn => resetn,
            clk_out2 => videoClk5x);



end behavior;
