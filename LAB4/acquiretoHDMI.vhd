--//////////Top Level for signal Acquisition /////////////////////////////--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.acquireToHDMI_package.all;					-- include your library here with added components ac97, ac97cmd
use work.scopeToHdmi_package.all;
use work.basicBuildingBlocks_package.all;					-- include your library here with added components ac97, ac97cmd


entity acquireToHDMI is
    PORT ( clk : in  STD_LOGIC;
           resetn : in  STD_LOGIC;
		   btn: in	STD_LOGIC_VECTOR(2 downto 0);
		   triggerCh1, triggerCh2: out STD_LOGIC;		   
		   conversionPlusReadoutTime: out STD_LOGIC;
		   sampleTimerRollover: out STD_LOGIC;
		   
		   an7606data: in STD_LOGIC_VECTOR(15 downto 0);
		   an7606convst, an7606cs, an7606rd, an7606reset: out STD_LOGIC;
		   an7606od: out STD_LOGIC_VECTOR(2 downto 0);
		   an7606busy : in STD_LOGIC;
		   
		   tmdsDataP : out  STD_LOGIC_VECTOR (2 downto 0);
           tmdsDataN : out  STD_LOGIC_VECTOR (2 downto 0);
           tmdsClkP : out STD_LOGIC;
           tmdsClkN : out STD_LOGIC;
           hdmiOen:    out STD_LOGIC		   
		   );		   
end acquireToHDMI;

architecture behavior of acquireToHDMI is
    
    signal cw: STD_LOGIC_VECTOR(CW_WIDTH -1 downto 0);
    signal sw: STD_LOGIC_VECTOR(SW_WIDTH -1 downto 0);
    signal forcedMode: STD_LOGIC;
    signal btnMeta, btnSync, btnPrevious, buttonActivity: STD_LOGIC_VECTOR(2 downto 0);
    signal busyMeta, busySync: STD_LOGIC;
        	
begin

    conversionPlusReadoutTime <= cw(CONVERSION_PLUS_READOUT_CW_BIT_INDEX);
    sampleTimerRollover <= cw(SAMPLE_TIMER_ROLLOVER_CW_BIT_INDEX);
    
    an7606convst <= cw(CONVST_CW_BIT_INDEX);
    an7606rd <= cw(RD_CW_BIT_INDEX);
    an7606cs <= cw(CS_CW_BIT_INDEX);
    an7606reset <= cw(RESET_AD7606_CW_BIT_INDEX);
    an7606od <= "000"; 

    ------------------------------------------------------------------------------
    -- Button Process
    ------------------------------------------------------------------------------
    button_process: process(clk)
    begin
        if (rising_edge(clk)) then
            if (resetn = '0') then
                btnMeta <= (others => '1');
                btnSync <= (others => '1');
                btnPrevious <= (others => '1');
            else
                btnMeta <= btn;
                btnSync <= btnMeta;
                btnPrevious <= btnSync;
            end if;
        end if;
    end process;
 
    buttonActivity <= btnSync and not btnPrevious;
 
    -- KEY3 toggles between FORCED (1) and TRIGGER (0); starts in FORCED
    mode_process: process(clk)
    begin
        if (rising_edge(clk)) then
            if (resetn = '0') then
                forcedMode <= '1';
            elsif (buttonActivity(MODE_BUTTON_INDEX) = '1') then
                forcedMode <= not forcedMode;
            end if;
        end if;
    end process;
    
    sw(SINGLE_FORCED_TRIGGER_SW_BIT_INDEX) <= buttonActivity(SINGLE_BUTTON_INDEX);
    sw(FORCED_MODE_SW_BIT_INDEX) <= forcedMode;

    triggerCh1 <= sw(CH1_TRIGGER_SW_BIT_INDEX);
    triggerCh2 <= sw(CH2_TRIGGER_SW_BIT_INDEX);
    ------------------------------------------------------------------------------
    -- Busy sync
    ------------------------------------------------------------------------------
    busy_process: process(clk)
    begin
        if (rising_edge(clk)) then
            if (resetn = '0') then
                busyMeta <= '0';
                busySync <= '0';
            else
                busyMeta <= an7606busy;
                busySync <= busyMeta;
            end if;
        end if;
    end process;
 
    sw(AN7606_BUSY_SW_BIT_INDEX) <= busySync;

 	datapath_inst: acquireToHDMI_datapath 
 	PORT MAP (
            clk => clk,
            resetn => resetn,
            cw => cw,
            sw => sw(DATAPATH_SW_WIDTH - 1 downto 0),
            an7606data => an7606data,
            triggerVolt16bitSigned => TRIGGER_VOLT_16BIT_SIGNED,
            triggerTimePixel => TRIGGER_TIME_PIXEL,
            ch1Data16bitSLV => open,
            ch2Data16bitSLV => open,
            tmdsDataP => tmdsDataP,
            tmdsDataN => tmdsDataN,
            tmdsClkP => tmdsClkP,
            tmdsClkN => tmdsClkN,
            hdmiOen => hdmiOen
            );

                
	control_inst: acquireToHDMI_fsm 
	   PORT MAP ( 
            clk => clk,
            resetn => resetn,
            sw => sw,
            cw => cw);

end behavior;
