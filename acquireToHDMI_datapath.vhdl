-- Lab 4 integration: based on Nathan/Aaron Lab 2/3 and Chris Coulston Lab 4 starter.
-- Completion and verification assisted by ChatGPT; review and document assistance as required.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.scopeToHdmi_package.all;
use work.acquireToHDMI_package.all;
use work.basicBuildingBlocks_package.all;
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
  signal longDelayCounter: std_logic_vector(23 downto 0);
  signal shortDelayCounter: std_logic_vector(7 downto 0);
  signal timerCounter, samplePeriod: std_logic_vector(31 downto 0);
  signal writeAddress, readAddress: std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal storeIntoBramFlag: std_logic;
  signal firstCh1DataStdLogicVector, secondCh1DataStdLogicVector: std_logic_vector(15 downto 0);
  signal firstCh2DataStdLogicVector, secondCh2DataStdLogicVector: std_logic_vector(15 downto 0);
  signal firstCh1GreaterThanTrigger, secondCh1LessThanTrigger: std_logic;
  signal firstCh2GreaterThanTrigger, secondCh2LessThanTrigger: std_logic;
  signal ch1Valid, ch2Valid: std_logic_vector(1 downto 0);
  signal ch1BramData, ch2BramData: std_logic_vector(15 downto 0);
  signal ch1Pixel, ch2Pixel, triggerVoltPixel: std_logic_vector(VIDEO_WIDTH_IN_BITS-1 downto 0);
  signal videoClk, videoClk5x, clkLocked, videoResetn, hdmiRst: std_logic;
  signal resetPipe: std_logic_vector(1 downto 0);
  signal lab2PixelHorz, lab2PixelVert: std_logic_vector(VIDEO_WIDTH_IN_BITS-1 downto 0);
  signal pixelHorz, pixelVert: std_logic_vector(VIDEO_WIDTH_IN_BITS-1 downto 0);
  type pixel_pipe_type is array (0 to BRAM_READ_LATENCY-1) of std_logic_vector(VIDEO_WIDTH_IN_BITS-1 downto 0);
  signal pixelHPipe, pixelVPipe: pixel_pipe_type;
  signal hs,vs,de,ch1Wave,ch2Wave: std_logic;
  signal hsPipe,vsPipe,dePipe: std_logic_vector(BRAM_READ_LATENCY downto 0);
  signal red,green,blue: std_logic_vector(7 downto 0);
  attribute ASYNC_REG: string;
  attribute ASYNC_REG of resetPipe: signal is "TRUE";
begin
  assert CAPTURE_SAMPLES < 2**BRAM_ADDR_WIDTH
    report "Capture width requires a wider address and BRAM IP" severity failure;
  longDelayCounter_inst: genericCounter generic map(24)
    port map(clk,resetn,cw(3 downto 2),(others=>'0'),longDelayCounter);
  shortDelayCounter_inst: genericCounter generic map(8)
    port map(clk,resetn,cw(1 downto 0),(others=>'0'),shortDelayCounter);
  sampleCounter_inst: genericCounter generic map(32)
    port map(clk,resetn,cw(7 downto 6),(others=>'0'),timerCounter);
  writeCounter_inst: genericCounter generic map(BRAM_ADDR_WIDTH)
    port map(clk,resetn,cw(9 downto 8),(others=>'0'),writeAddress);
  with cw(5 downto 4) select samplePeriod <=
    HIGHEST_RATE when "00", HIGH_RATE when "01", LOW_RATE when "10", LOWEST_RATE when others;
  sw(LONG_DELAY_DONE_SW_BIT_INDEX) <= '1' when longDelayCounter=LONG_DELAY_50Mhz_COUNTS else '0';
  sw(SHORT_DELAY_DONE_SW_BIT_INDEX) <= '1' when shortDelayCounter=SHORT_DELAY_50Mhz_COUNTS else '0';
  -- >= prevents a missed equality from hanging acquisition if conversion takes too long.
  sw(SAMPLE_INTERVAL_DONE_SW_BIT_INDEX) <= '1' when unsigned(timerCounter)>=unsigned(samplePeriod) else '0';
  sw(MEM_FULL_SW_BIT_INDEX) <= '1' when unsigned(writeAddress)>=CAPTURE_SAMPLES else '0';
  sw(STORE_INTO_BRAM_SW_BIT_INDEX)<=storeIntoBramFlag;
  process(clk) begin
    if rising_edge(clk) then
      if resetn='0' then storeIntoBramFlag<='0';
      elsif cw(SET_STORE_FLAG_CW_BIT_INDEX)='1' then storeIntoBramFlag<='1';
      elsif cw(CLEAR_STORE_FLAG_CW_BIT_INDEX)='1' then storeIntoBramFlag<='0'; end if;
    end if;
  end process;

  -- Two successive signed samples per channel: newest > trigger AND previous < trigger.
  process(clk) begin
    if rising_edge(clk) then
      if resetn='0' or cw(CLEAR_STORE_FLAG_CW_BIT_INDEX)='1' then
        firstCh1DataStdLogicVector<=(others=>'0'); secondCh1DataStdLogicVector<=(others=>'0');
        firstCh2DataStdLogicVector<=(others=>'0'); secondCh2DataStdLogicVector<=(others=>'0');
        ch1Valid<="00"; ch2Valid<="00";
      else
        if cw(TRIG_CH1_WRITE_CW_BIT_INDEX)='1' then
          secondCh1DataStdLogicVector<=firstCh1DataStdLogicVector;
          firstCh1DataStdLogicVector<=an7606data; ch1Valid<=ch1Valid(0)&'1';
        end if;
        if cw(TRIG_CH2_WRITE_CW_BIT_INDEX)='1' then
          secondCh2DataStdLogicVector<=firstCh2DataStdLogicVector;
          firstCh2DataStdLogicVector<=an7606data; ch2Valid<=ch2Valid(0)&'1';
        end if;
      end if;
    end if;
  end process;
  firstCh1GreaterThanTrigger<='1' when signed(firstCh1DataStdLogicVector)>triggerVolt16bitSigned else '0';
  secondCh1LessThanTrigger<='1' when signed(secondCh1DataStdLogicVector)<triggerVolt16bitSigned else '0';
  firstCh2GreaterThanTrigger<='1' when signed(firstCh2DataStdLogicVector)>triggerVolt16bitSigned else '0';
  secondCh2LessThanTrigger<='1' when signed(secondCh2DataStdLogicVector)<triggerVolt16bitSigned else '0';
  sw(CH1_TRIGGER_SW_BIT_INDEX)<=firstCh1GreaterThanTrigger and secondCh1LessThanTrigger and ch1Valid(1);
  sw(CH2_TRIGGER_SW_BIT_INDEX)<=firstCh2GreaterThanTrigger and secondCh2LessThanTrigger and ch2Valid(1);
  ch1Data16bitSLV<=firstCh1DataStdLogicVector; ch2Data16bitSLV<=firstCh2DataStdLogicVector;

  -- Port A: 50 MHz ADC writes. Port B: video-clock reads, two-cycle latency.
  readAddress <= std_logic_vector(resize(unsigned(pixelHorz)-unsigned(L_EDGE),BRAM_ADDR_WIDTH))
    when unsigned(pixelHorz)>=unsigned(L_EDGE) and unsigned(pixelHorz)<unsigned(R_EDGE)
    else (others=>'0');
  dataStorage_ch1: blk_mem_gen_0 port map(
    clka=>clk,ena=>'1',wea=>cw(DATA_STORAGE_CH1_WRITE_CW_BIT_INDEX downto DATA_STORAGE_CH1_WRITE_CW_BIT_INDEX),
    addra=>writeAddress,dina=>an7606data,clkb=>videoClk,enb=>'1',addrb=>readAddress,doutb=>ch1BramData);
  dataStorage_ch2: blk_mem_gen_0 port map(
    clka=>clk,ena=>'1',wea=>cw(DATA_STORAGE_CH2_WRITE_CW_BIT_INDEX downto DATA_STORAGE_CH2_WRITE_CW_BIT_INDEX),
    addra=>writeAddress,dina=>an7606data,clkb=>videoClk,enb=>'1',addrb=>readAddress,doutb=>ch2BramData);
  ch1Pixel<=sampleToPixel(signed(ch1BramData)); ch2Pixel<=sampleToPixel(signed(ch2BramData));
  triggerVoltPixel<=sampleToPixel(triggerVolt16bitSigned);
  ch1Wave<='1' when not is_x(ch1BramData) and pixelVPipe(BRAM_READ_LATENCY-1)=ch1Pixel else '0';
  ch2Wave<='1' when not is_x(ch2BramData) and pixelVPipe(BRAM_READ_LATENCY-1)=ch2Pixel else '0';

  vc: clk_wiz_0 port map(clk_out1=>videoClk,clk_out2=>videoClk5x,resetn=>resetn,locked=>clkLocked,clk_in1=>clk);
  -- Asynchronous assertion and synchronous release in the pixel-clock domain.
  process(videoClk,resetn,clkLocked) begin
    if resetn='0' or clkLocked='0' then resetPipe<="00";
    elsif rising_edge(videoClk) then resetPipe<=resetPipe(0)&'1'; end if;
  end process;
  videoResetn<=resetPipe(1); hdmiRst<=not videoResetn; hdmiOen<='1';
  vsg: videoSignalGenerator port map(videoClk,videoResetn,hs,vs,de,lab2PixelHorz,lab2PixelVert);

  -- Lab 2 emits (1,1) at the first active pixel. Use zero-based positions
  -- for Lab 4 BRAM addressing and drawing, and ignore blanking coordinates.
  pixelHorz <= std_logic_vector(unsigned(lab2PixelHorz) - 1)
    when de = '1' else (others => '0');
  pixelVert <= std_logic_vector(unsigned(lab2PixelVert) - 1)
    when de = '1' else (others => '0');
  process(videoClk) begin
    if rising_edge(videoClk) then
      if videoResetn='0' then
        pixelHPipe<=(others=>(others=>'0')); pixelVPipe<=(others=>(others=>'0'));
        hsPipe<=(others=>'1'); vsPipe<=(others=>'1'); dePipe<=(others=>'0');
      else
        pixelHPipe(0)<=pixelHorz; pixelVPipe(0)<=pixelVert;
        for i in 1 to BRAM_READ_LATENCY-1 loop
          pixelHPipe(i)<=pixelHPipe(i-1); pixelVPipe(i)<=pixelVPipe(i-1);
        end loop;
        hsPipe<=hsPipe(BRAM_READ_LATENCY-1 downto 0)&hs;
        vsPipe<=vsPipe(BRAM_READ_LATENCY-1 downto 0)&vs;
        dePipe<=dePipe(BRAM_READ_LATENCY-1 downto 0)&de;
      end if;
    end if;
  end process;
  sf: scopeFace port map(clk=>videoClk,resetn=>videoResetn,
    pixelHorz=>pixelHPipe(BRAM_READ_LATENCY-1),pixelVert=>pixelVPipe(BRAM_READ_LATENCY-1),
    triggerVolt=>triggerVoltPixel,triggerTime=>triggerTimePixel,
    red=>red,green=>green,blue=>blue,ch1=>ch1Wave,ch1Enb=>'1',ch2=>ch2Wave,ch2Enb=>'1');
  hdmi_inst: hdmi_tx_0 port map(pix_clk=>videoClk,pix_clkx5=>videoClk5x,pix_clk_locked=>clkLocked,rst=>hdmiRst,
    red=>red,green=>green,blue=>blue,hsync=>hsPipe(BRAM_READ_LATENCY),vsync=>vsPipe(BRAM_READ_LATENCY),
    vde=>dePipe(BRAM_READ_LATENCY),aux0_din=>"0000",aux1_din=>"0000",aux2_din=>"0000",ade=>'0',
    TMDS_CLK_P=>tmdsClkP,TMDS_CLK_N=>tmdsClkN,TMDS_DATA_P=>tmdsDataP,TMDS_DATA_N=>tmdsDataN);
end architecture;
