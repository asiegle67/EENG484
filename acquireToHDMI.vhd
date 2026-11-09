-- Lab 4 integration: based on Nathan/Aaron Lab 2/3 and Chris Coulston Lab 4 starter.
-- Completion and verification assisted by ChatGPT; review and document assistance as required.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.scopeToHdmi_package.all;
use work.acquireToHDMI_package.all;
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
  signal cw: std_logic_vector(CW_WIDTH-1 downto 0);
  signal sw: std_logic_vector(SW_WIDTH-1 downto 0);
  signal forcedMode: std_logic;
  signal btnMeta,btnSync,btnPrevious,buttonActivity: std_logic_vector(2 downto 0);
  signal buttonReady: std_logic_vector(2 downto 0);
  signal busyMeta,busySync: std_logic;
  attribute ASYNC_REG: string;
  attribute ASYNC_REG of btnMeta,btnSync,busyMeta,busySync: signal is "TRUE";
begin
  conversionPlusReadoutTime<=cw(CONVERSION_PLUS_READOUT_CW_BIT_INDEX);
  sampleTimerRollover<=cw(SAMPLE_TIMER_ROLLOVER_CW_BIT_INDEX);
  an7606convst<=cw(CONVST_CW_BIT_INDEX); an7606cs<=cw(CS_CW_BIT_INDEX);
  an7606rd<=cw(RD_CW_BIT_INDEX); an7606reset<=cw(RESET_AD7606_CW_BIT_INDEX); an7606od<="000";
  triggerCh1<=sw(CH1_TRIGGER_SW_BIT_INDEX); triggerCh2<=sw(CH2_TRIGGER_SW_BIT_INDEX);
  process(clk) begin
    if rising_edge(clk) then
      if resetn='0' then
        busyMeta<='0'; busySync<='0';
        -- Matches the course TB's initial 000. Startup masking avoids a phantom
        -- release with the physical active-low buttons (which normally idle at 111).
        btnMeta<="000"; btnSync<="000"; btnPrevious<="000"; buttonReady<="000";
        forcedMode<='1';
      else
        busyMeta<=an7606busy; busySync<=busyMeta;
        btnMeta<=btn; btnSync<=btnMeta; btnPrevious<=btnSync;
        buttonReady<=buttonReady(1 downto 0)&'1';
        if buttonActivity(1)='1' then forcedMode<=not forcedMode; end if;
      end if;
    end if;
  end process;
  -- Rising-edge/release detection, as in your Lab 3. PL KEY4 = bit 0 here.
  buttonActivity <= btnSync and not btnPrevious when buttonReady(2)='1' else "000";
  sw(BUSY_SW_BIT_INDEX)<=busySync;
  sw(SINGLE_FORCED_TRIGGER_SW_BIT_INDEX)<=buttonActivity(0);
  sw(FORCED_MODE_SW_BIT_INDEX)<=forcedMode;
  datapath_inst: acquireToHDMI_datapath port map(clk=>clk,resetn=>resetn,cw=>cw,
    sw=>sw(DATAPATH_SW_WIDTH-1 downto 0),an7606data=>an7606data,
    triggerVolt16bitSigned=>to_signed(0,16),triggerTimePixel=>L_EDGE,
    ch1Data16bitSLV=>open,ch2Data16bitSLV=>open,tmdsDataP=>tmdsDataP,tmdsDataN=>tmdsDataN,
    tmdsClkP=>tmdsClkP,tmdsClkN=>tmdsClkN,hdmiOen=>hdmiOen);
  control_inst: acquireToHDMI_fsm port map(clk=>clk,resetn=>resetn,sw=>sw,cw=>cw);
end architecture;
