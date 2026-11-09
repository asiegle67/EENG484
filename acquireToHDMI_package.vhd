-- Lab 4 integration: based on Nathan/Aaron Lab 2/3 and Chris Coulston Lab 4 starter.
-- Completion and verification assisted by ChatGPT; review and document assistance as required.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.scopeToHdmi_package.all;
package acquireToHDMI_package is
  constant clk_period: time := 20 ns;
  constant CW_WIDTH: natural := 22;
  constant CONTROL_CW_WIDTH: natural := CW_WIDTH;
  constant SW_WIDTH: natural := 10;
  constant DATAPATH_SW_WIDTH: natural := 7;
  type state_type is (RESET_STATE, LONG_DELAY_STATE, RESET_AD7606_STATE, WAIT_FORCED_STATE, SET_STORE_FLAG_STATE, CLEAR_STORE_FLAG_STATE, BEGIN_CONVERSION, ASSERT_CONVST, WAIT_BUSY_0, WAIT_BUSY_1, READ_CH1_LOW, WRITE_CH1_TRIGGER, WRITE_CH1_BRAM, READ_CH1_HIGH, RESET_SHORT, READ_CH2_LOW, WRITE_CH2_TRIGGER, WRITE_CH2_BRAM, READ_CH2_HIGH, WAIT_FOR_END_OF_SAMPLE_INTERVAL, BRAM_FULL);
  constant CLEAR_STORE_FLAG_CW_BIT_INDEX: natural := 21;
  constant SET_STORE_FLAG_CW_BIT_INDEX: natural := 20;
  constant TRIG_CH2_WRITE_CW_BIT_INDEX: natural := 19;
  constant TRIG_CH1_WRITE_CW_BIT_INDEX: natural := 18;
  constant CONVERSION_PLUS_READOUT_CW_BIT_INDEX: natural := 17;
  constant SAMPLE_TIMER_ROLLOVER_CW_BIT_INDEX: natural := 16;
  constant DATA_STORAGE_CH2_WRITE_CW_BIT_INDEX: natural := 15;
  constant DATA_STORAGE_CH1_WRITE_CW_BIT_INDEX: natural := 14;
  constant CONVST_CW_BIT_INDEX: natural := 13;
  constant RD_CW_BIT_INDEX: natural := 12;
  constant CS_CW_BIT_INDEX: natural := 11;
  constant RESET_AD7606_CW_BIT_INDEX: natural := 10;
  constant DATA_STORAGE_COUNTER_CW_LSB_INDEX: natural := 8;
  constant SAMPLING_COUNTER_CW_LSB_INDEX: natural := 6;
  constant SAMPLING_RATE_SELECT_CW_LSB_INDEX: natural := 4;
  constant LONG_DELAY_COUNTER_CW_LSB_INDEX: natural := 2;
  constant SHORT_DELAY_COUNTER_CW_LSB_INDEX: natural := 0;
  constant MEM_FULL_SW_BIT_INDEX: natural := 0;
  constant SHORT_DELAY_DONE_SW_BIT_INDEX: natural := 1;
  constant LONG_DELAY_DONE_SW_BIT_INDEX: natural := 2;
  constant SAMPLE_INTERVAL_DONE_SW_BIT_INDEX: natural := 3;
  constant CH1_TRIGGER_SW_BIT_INDEX: natural := 4;
  constant CH2_TRIGGER_SW_BIT_INDEX: natural := 5;
  constant STORE_INTO_BRAM_SW_BIT_INDEX: natural := 6;
  constant BUSY_SW_BIT_INDEX: natural := 7;
  constant SINGLE_FORCED_TRIGGER_SW_BIT_INDEX: natural := 8;
  constant FORCED_MODE_SW_BIT_INDEX: natural := 9;
  constant HOLD_COUNT: std_logic_vector(1 downto 0) := "00";
  constant LOAD_COUNT: std_logic_vector(1 downto 0) := "01";
  constant INC_COUNT: std_logic_vector(1 downto 0) := "10";
  constant RESET_COUNT: std_logic_vector(1 downto 0) := "11";
  constant LONG_DELAY_50Mhz_CONST_WIDTH: natural := 24;
  constant LONG_DELAY_50Mhz_COUNTS: std_logic_vector(23 downto 0) := x"00FFFF";
  constant SHORT_DELAY_50Mhz_CONST_WIDTH: natural := 8;
  constant SHORT_DELAY_50Mhz_COUNTS: std_logic_vector(7 downto 0) := x"10";
  constant HIGHEST_RATE: std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(300,32));
  constant HIGH_RATE: std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(600,32));
  -- Correct the swapped LOW/LOWEST labels in the website's starter package.
  constant LOW_RATE: std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(1200,32));
  constant LOWEST_RATE: std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(2400,32));
  constant BRAM_ADDR_WIDTH: positive := 10;
  constant CAPTURE_SAMPLES: positive := WIDTH_N; -- 700, NOT the whole 1280-pixel monitor
  constant BRAM_READ_LATENCY: positive := 2; -- primitive output register enabled
  function sampleToPixel(sample: signed(15 downto 0)) return std_logic_vector;
component acquireToHDMI is
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
end component;
component acquireToHDMI_datapath is
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
end component;
component acquireToHDMI_fsm is
    PORT (  clk : in  STD_LOGIC;
            resetn : in  STD_LOGIC;
            sw: in STD_LOGIC_VECTOR(SW_WIDTH - 1 downto 0);
            cw: out STD_LOGIC_VECTOR (CW_WIDTH - 1 downto 0));
end component;
component an7606 is
    PORT ( clk : in  STD_LOGIC;
           an7606data: out STD_LOGIC_VECTOR(15 downto 0);
           an7606convst, an7606cs, an7606rd, an7606reset: in STD_LOGIC;
           an7606od: in STD_LOGIC_VECTOR(2 downto 0);
           an7606busy : out STD_LOGIC);
END component;
component blk_mem_gen_0 is
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    clkb : IN STD_LOGIC;
    enb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END component;
end package;
package body acquireToHDMI_package is
  function sampleToPixel(sample: signed(15 downto 0)) return std_logic_vector is
    variable y: integer;
  begin
    if is_x(std_logic_vector(sample)) then
      return std_logic_vector(to_unsigned(V_CENTER, VIDEO_WIDTH_IN_BITS));
    end if;
    -- ADC full scale +/-5 V maps to the 700-pixel grid height; positive goes UP.
    y := V_CENTER - (to_integer(sample) * HEIGHT_N) / 65536;
    return std_logic_vector(to_unsigned(y, VIDEO_WIDTH_IN_BITS));
  end function;
end package body;
