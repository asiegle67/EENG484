--------------------------------------------------------------------
-- Name:	Aaron and Nathan
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
 
-- Lab 3 delay counters
    signal shortDelayCounter: STD_LOGIC_VECTOR(SHORT_DELAY_50Mhz_CONST_WIDTH-1 downto 0);
    signal longDelayCounter: STD_LOGIC_VECTOR(LONG_DELAY_50Mhz_CONST_WIDTH-1 downto 0);
    signal shortDelayDone, longDelayDone: STD_LOGIC;
 
-- sample interval timer
    signal timerCounter: STD_LOGIC_VECTOR(SAMPLE_TIMER_WIDTH-1 downto 0);
    signal sampleRateCounts: STD_LOGIC_VECTOR(SAMPLE_TIMER_WIDTH-1 downto 0);
    signal sampleTimerGreater, sampleTimerEqual: STD_LOGIC;
 
-- BRAM write address counter + FULL
    signal wrAddr: STD_LOGIC_VECTOR(BRAM_ADDR_WIDTH-1 downto 0);
    signal wrAddrGreater, wrAddrEqual: STD_LOGIC;
 
-- BRAM read side
    signal rdAddr: STD_LOGIC_VECTOR(BRAM_ADDR_WIDTH-1 downto 0);
    signal ch1BramOut, ch2BramOut: STD_LOGIC_VECTOR(15 downto 0);
    signal ch1Product, ch2Product: SIGNED(31 downto 0);
    signal ch1PixelFull, ch2PixelFull: SIGNED(31 downto 0);
    signal ch1Pixel, ch2Pixel: STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0);
    signal insideScope, insideScopeDelayed: STD_LOGIC;
    signal storeIntoBramFlag: STD_LOGIC;
 
-- triggers  (names match acquireToHDMI_tbWaveSetup.tcl, "fist" typo included)
    signal fistCh1DataStdLogicVector, secondCh1DataStdLogicVector: STD_LOGIC_VECTOR(15 downto 0);
    signal firstCh1GreaterThanTrigger, secondCh1LessThanTrigger: STD_LOGIC;
    signal firstCh2DataStdLogicVector, secondCh2DataStdLogicVector: STD_LOGIC_VECTOR(15 downto 0);
    signal firstCh2GreaterThanTrigger, secondCh2LessThanTrigger: STD_LOGIC;
 
-- SgnToPixel for the trigger voltage marker
    signal trigVoltProduct, trigVoltPixelFull: SIGNED(31 downto 0);
    signal trigVscr: STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0);
 
-- Lab 2 video
    signal videoClk, videoClk5x, clkLocked: STD_LOGIC;
    signal hdmiRst: STD_LOGIC;
    signal hs, vs, de: STD_LOGIC;
    signal pixelHorz, pixelVert: STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0);
    signal red, green, blue: STD_LOGIC_VECTOR(7 downto 0);
    signal ch1Wave, ch2Wave: STD_LOGIC;


    
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
            c => cw(SHORT_DELAY_COUNTER_CW_BIT_INDEX + 1 downto SHORT_DELAY_COUNTER_CW_BIT_INDEX),
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
            resetn => resetn,
            c => cw(SAMPLING_COUNTER_CW_BIT_INDEX+1 downto SAMPLING_COUNTER_CW_BIT_INDEX),
            d => (others => '0'),
            q => timerCounter
            );
    
    sampleRateMux : genericMux4x1
        GENERIC MAP (SAMPLE_TIMER_WIDTH)
        PORT MAP (s => cw(SAMPLING_RATE_SELECT_CW_BIT_INDEX+1 downto SAMPLING_RATE_SELECT_CW_BIT_INDEX),
            y3 => LOWEST_RATE,
            y2 => LOW_RATE,
            y1 => HIGH_RATE,
            y0 => HIGHEST_RATE,
            f => sampleRateCounts
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
            resetn => resetn,
            c => cw(DATA_STORAGE_COUNTER_CW_BIT_INDEX+1 downto DATA_STORAGE_COUNTER_CW_BIT_INDEX),
            d => (others => '0'),
            q => wrAddr
            );     
            
     storageCompare : genericCompare
        GENERIC MAP (BRAM_ADDR_WIDTH)
        PORT MAP (x => wrAddr,
            y => SCREEN_WIDTH_SAMPLES,
            g => wrAddrGreater,
            l => open,
            e => wrAddrEqual
            );
            
    -- G and E used in case wr got passed set value and then FULL would never fire
     sw(FULL_SW_BIT_INDEX) <= wrAddrGreater or wrAddrEqual;

-- BRAM CODE
    rdAddr <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(pixelHorz) - TO_UNSIGNED(SCOPE_LEFT_EDGE_PIXEL, VIDEO_WIDTH_IN_BITS), BRAM_ADDR_WIDTH));
 
    -- only draw traces inside the scope face (outside it rdAddr would wrap around)
    insideScope <= '1' when (UNSIGNED(pixelHorz) >= SCOPE_LEFT_EDGE_PIXEL) and (UNSIGNED(pixelHorz) <  SCOPE_LEFT_EDGE_PIXEL + SCOPE_WIDTH_PIXELS) else '0';
 
    -- the BRAM output shows up one videoClk after the address, so delay insideScope
    -- by one clock too so it lines up with the data coming out of the BRAM
    process(videoClk)
    begin
        if (rising_edge(videoClk)) then
            insideScopeDelayed <= insideScope;
        end if;
    end process;
 
    -- port A writes samples (50 MHz side), port B is read by the video side
    dataStorage_ch1 : blk_mem_gen_0
        PORT MAP (clka => clk,
            ena => '1',
            wea => cw(DATA_STORAGE_CH1_WRITE_CW_BIT_INDEX downto DATA_STORAGE_CH1_WRITE_CW_BIT_INDEX),
            addra => wrAddr,
            dina => an7606data,
            clkb => videoClk,
            enb => '1',
            addrb => rdAddr,
            doutb => ch1BramOut
            );
 
    dataStorage_ch2 : blk_mem_gen_0
        PORT MAP (clka => clk,
            ena => '1',
            wea => cw(DATA_STORAGE_CH2_WRITE_CW_BIT_INDEX downto DATA_STORAGE_CH2_WRITE_CW_BIT_INDEX),
            addra => wrAddr,
            dina => an7606data,
            clkb => videoClk,
            enb => '1',
            addrb => rdAddr,
            doutb => ch2BramOut
            );
 
    -- 2sToPixel:  pixel = -700 * sample / 2^16 + 360
    ch1Product   <= SIGNED(ch1BramOut) * TO_SIGNED(-SCOPE_VERT_SPAN_PIXELS, 16);
    ch1PixelFull <= SHIFT_RIGHT(ch1Product, 16) + TO_SIGNED(SCOPE_VERT_CENTER_PIXEL, 32);
    ch1Pixel     <= STD_LOGIC_VECTOR(ch1PixelFull(VIDEO_WIDTH_IN_BITS-1 downto 0));
 
    ch2Product   <= SIGNED(ch2BramOut) * TO_SIGNED(-SCOPE_VERT_SPAN_PIXELS, 16);
    ch2PixelFull <= SHIFT_RIGHT(ch2Product, 16) + TO_SIGNED(SCOPE_VERT_CENTER_PIXEL, 32);
    ch2Pixel     <= STD_LOGIC_VECTOR(ch2PixelFull(VIDEO_WIDTH_IN_BITS-1 downto 0));
 
    -- compare with the row being drawn: if this row is the sample's row, light the trace
    ch1Wave <= '1' when (ch1Pixel = pixelVert) and (insideScopeDelayed = '1') else '0';
    ch2Wave <= '1' when (ch2Pixel = pixelVert) and (insideScopeDelayed = '1') else '0';


-- CH1 TRIGGER
    ch1Register : genericRegister
        GENERIC MAP (16)
        PORT MAP (clk => clk,
            resetn => resetn,
            load => cw(TRIG_CH1_WRITE_CW_BIT_INDEX),
            d => an7606data,
            q => fistCh1DataStdLogicVector
            );

    ch1Register2 : genericRegister
        GENERIC MAP (16)
        PORT MAP (clk => clk,
            resetn => resetn,
            load => cw(TRIG_CH1_WRITE_CW_BIT_INDEX),
            d => fistCh1DataStdLogicVector,
            q => secondCh1DataStdLogicVector
            );

    -- since compare is unsigned, then can't use genericCompare here for the signCompare blocks, instead write logic for compairng
    firstCh1GreaterThanTrigger <= '1' when
        (SIGNED(fistCh1DataStdLogicVector) > triggerVolt16bitSigned) else
        '0';

    secondCh1LessThanTrigger <= '1' when
        (SIGNED(secondCh1DataStdLogicVector) < triggerVolt16bitSigned) else
        '0';
        
    sw(CH1_TRIGGER_SW_BIT_INDEX) <= firstCh1GreaterThanTrigger and secondCh1LessThanTrigger;
    ch1Data16bitSLV <= fistCh1DataStdLogicVector;

-- CH2 TRIGGER
    ch2Register : genericRegister
        GENERIC MAP (16)
        PORT MAP (clk => clk,
            resetn => resetn,
            load => cw(TRIG_CH2_WRITE_CW_BIT_INDEX),
            d => an7606data,
            q => firstCh2DataStdLogicVector
            );

    ch2Register2 : genericRegister
        GENERIC MAP (16)
        PORT MAP (clk => clk,
            resetn => resetn,
            load => cw(TRIG_CH2_WRITE_CW_BIT_INDEX),
            d => firstCh2DataStdLogicVector,
            q => secondCh2DataStdLogicVector
            );

    -- since compare is unsigned, then can't use genericCompare here for the signCompare blocks, instead write logic for compairng
    firstCh2GreaterThanTrigger <= '1' when
        (SIGNED(firstCh2DataStdLogicVector) > triggerVolt16bitSigned) else
        '0';

    secondCh2LessThanTrigger <= '1' when
        (SIGNED(secondCh2DataStdLogicVector) < triggerVolt16bitSigned) else
        '0';
        
    sw(CH2_TRIGGER_SW_BIT_INDEX) <= firstCh2GreaterThanTrigger and secondCh2LessThanTrigger;
    ch2Data16bitSLV <= firstCh2DataStdLogicVector;
    
-- SgnToPixel -- trigger voltage
    trigVoltProduct <= triggerVolt16bitSigned * TO_SIGNED(-SCOPE_VERT_SPAN_PIXELS, 16);
    trigVoltPixelFull <= SHIFT_RIGHT(trigVoltProduct, 16) + TO_SIGNED(SCOPE_VERT_CENTER_PIXEL, 32);
    trigVscr <= STD_LOGIC_VECTOR(trigVoltPixelFull(VIDEO_WIDTH_IN_BITS-1 downto 0));

-- LAB 2    
        hdmiOen <= '1';
        hdmiRst <= not resetn;
    
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
            triggerVolt => trigVscr,
            triggerTime => triggerTimePixel,
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
	    clk_in1 => clk);



end behavior;
