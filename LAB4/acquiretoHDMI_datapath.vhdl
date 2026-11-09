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
-- highest rate = fewest counts --> fastest, 00 set as the highest rate
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
     -- send where the sample rate is (greater or less than the time) back to the sw
     -- uses OR logic from G and E for the FSM to see as soon as the sample gets there, G more for errors in case it misses it initially
     sw(SAMPLE_SW_BIT_INDEX) <= sampleTimerGreater or sampleTimerEqual;
     
-- FULL for BRAM
    storageForData : genericCounter
        GENERIC MAP (BRAM_ADDR_WIDTH)
        PORT MAP (clk => clk,
            c => cw(DATA_STORAGE_COUNTER_CW_BIT_INDEX+1 downto DATA_STORAGE_COUNTER_CW_BIT_INDEX),
            d => (others => '0'),
            q => wrAddr
            );     
            
     storageCompare : genericCompare
        GENERIC MAP (BRAM_ADDR_WIDTH)
        PORT MAP (clk => clk,
            y => SCREEN_WIDTH_SAMPLES,
            g => wrAddrGreater,
            l => open,
            e => wrAddrEqual
            );
            
    -- G and E used in case wr got passed set value and then FULL would never fire
     sw(FULL_SW_BIT_INDEX) <= wrAddrGreater or wrAddrEqual;

-- BRAM CODE
-- xxx

-- CH1 TRIGGER
    ch1Register : genericRegister
        GENERIC MAP (16)
        PORT MAP (clk => clk,
            resetn => resetn,
            load => cw(TRIG_CH1_WRITE_CW_BIT_INDEX),
            d => an7606data,
            q => ch1Data16bitSLV
            );

    ch1Register2 : genericRegister
        GENERIC MAP (16)
        PORT MAP (clk => clk,
            resetn => resetn,
            load => cw(TRIG_CH1_WRITE_CW_BIT_INDEX),
            d => ch1Data16bitSLV,
            q => secondch1Data16bitSLV
            );

    -- since compare is unsigned, then can't use genericCompare here for the signCompare blocks, instead write logic for compairng
    firstCh1GreaterThanTrigger <= '1' when
        (SIGNED(ch1Data16bitSLV) > trigVolt16Sgn) else
        '0';

    secondCh1LessThanTrigger <= '1' when
        (SIGNED(secondch1Data16bitSLV) > trigVolt16Sgn) else
        '0';
        
    sw(CH1_TRIGGER_SW_BIT_INDEX) <= firstCh1GreaterThanTrigger and secondCh1LessThanTrigger;


-- CH2 TRIGGER
    ch2Register : genericRegister
        GENERIC MAP (16)
        PORT MAP (clk => clk,
            resetn => resetn,
            load => cw(TRIG_CH2_WRITE_CW_BIT_INDEX),
            d => an7606data,
            q => ch2Data16bitSLV
            );

    ch2Register2 : genericRegister
        GENERIC MAP (16)
        PORT MAP (clk => clk,
            resetn => resetn,
            load => cw(TRIG_CH2_WRITE_CW_BIT_INDEX),
            d => ch2Data16bitSLV,
            q => secondch2Data16bitSLV
            );

    -- since compare is unsigned, then can't use genericCompare here for the signCompare blocks, instead write logic for compairng
    firstCh2GreaterThanTrigger <= '1' when
        (SIGNED(ch2Data16bitSLV) > trigVolt16Sgn) else
        '0';

    secondCh2LessThanTrigger <= '1' when
        (SIGNED(secondch2Data16bitSLV) > trigVolt16Sgn) else
        '0';
        
    sw(CH2_TRIGGER_SW_BIT_INDEX) <= firstCh2GreaterThanTrigger and secondCh2LessThanTrigger;    
    
-- SgnToPixel -- trigger voltage
-- not sure what claude has here and it doesn't make too much sense


-- LAB 2    
    
    
        hdmiOen <= '1';
    
    vsg: videoSignalGenerator
        PORT MAP (clk => videoClk,
            resetn => resetn,
            hs => hs,
            vs => vs,
            de => de,
            pixelHorz => pixelHorz,
            pixelVert => pixelVert 
        );
                 

    sf: scopeFace
        PORT MAP (clk => videoClk,
            resetn => resetn,
            pixelHorz => pixelHorz,
            pixelVert => pixelVert,
            triggerVolt => triggerVolt,
            triggerTime => triggerTime,
            red => red,
            green => green,
            blue => blue,
            ch1 => ch1Wave,
            ch1Enb => '1',
            ch2 => ch2Wave,
            ch2Enb => '1'
            );
                 
    hdmi_inst: hdmi_tx_0
        PORT MAP (pix_clk => videoClk,
            pix_clkx5      => videoClk5x,
            pix_clk_locked => clkLocked,
            rst => hdmiRst,
            red => red,
            green => green,
            blue => blue,
            hsync => hs,
            vsync => vs,
            vde => de,
            aux0_din => "0000",
            aux1_din => "0000",
            aux2_din => "0000",
            ade => '0',
            TMDS_CLK_P => tmdsClkP,
            TMDS_CLK_N => tmdsClkN,
            TMDS_DATA_P => tmdsDataP,
            TMDS_DATA_N => tmdsDataN);
            

    vc: clk_wiz_0
	PORT MAP( 
	    clk_out1 => videoClk,
	    clk_out2 => videoClk5x,
	    resetn => resetn,
	    locked => clkLocked,
	    clk_in1 => sysClk);



end behavior;
