-- Lab 4 integration: based on Nathan/Aaron Lab 2/3 and Chris Coulston Lab 4 starter.
-- Completion and verification assisted by ChatGPT; review and document assistance as required.
library ieee;
use ieee.std_logic_1164.all;
use work.acquireToHDMI_package.all;
entity acquireToHDMI_fsm is
    PORT (  clk : in  STD_LOGIC;
            resetn : in  STD_LOGIC;
            sw: in STD_LOGIC_VECTOR(SW_WIDTH - 1 downto 0);
            cw: out STD_LOGIC_VECTOR (CW_WIDTH - 1 downto 0));
end acquireToHDMI_fsm;
architecture Behavioral of acquireToHDMI_fsm is
  signal state: state_type;
begin
  state_process: process(clk) begin
    if rising_edge(clk) then
      if resetn='0' then state<=RESET_STATE;
      else
        case state is
          when RESET_STATE => state<=LONG_DELAY_STATE;
          when LONG_DELAY_STATE =>
            if sw(LONG_DELAY_DONE_SW_BIT_INDEX)='1' then state<=RESET_AD7606_STATE; end if;
          when RESET_AD7606_STATE =>
            if sw(SHORT_DELAY_DONE_SW_BIT_INDEX)='1' then
              if sw(FORCED_MODE_SW_BIT_INDEX)='1' then state<=WAIT_FORCED_STATE;
              else state<=CLEAR_STORE_FLAG_STATE; end if;
            end if;
          when WAIT_FORCED_STATE =>
            if sw(FORCED_MODE_SW_BIT_INDEX)='0' then state<=CLEAR_STORE_FLAG_STATE;
            elsif sw(SINGLE_FORCED_TRIGGER_SW_BIT_INDEX)='1' then state<=SET_STORE_FLAG_STATE; end if;
          when SET_STORE_FLAG_STATE | CLEAR_STORE_FLAG_STATE => state<=BEGIN_CONVERSION;
          when BEGIN_CONVERSION => state<=ASSERT_CONVST;
          when ASSERT_CONVST =>
            if sw(SHORT_DELAY_DONE_SW_BIT_INDEX)='1' then state<=WAIT_BUSY_0; end if;
          when WAIT_BUSY_0 =>
            if sw(BUSY_SW_BIT_INDEX)='1' then state<=WAIT_BUSY_1; end if;
          when WAIT_BUSY_1 =>
            if sw(BUSY_SW_BIT_INDEX)='0' then state<=READ_CH1_LOW; end if;
          when READ_CH1_LOW =>
            if sw(SHORT_DELAY_DONE_SW_BIT_INDEX)='1' then
              if sw(STORE_INTO_BRAM_SW_BIT_INDEX)='1' then state<=WRITE_CH1_BRAM;
              else state<=WRITE_CH1_TRIGGER; end if;
            end if;
          when WRITE_CH1_TRIGGER | WRITE_CH1_BRAM => state<=READ_CH1_HIGH;
          when READ_CH1_HIGH =>
            if sw(SHORT_DELAY_DONE_SW_BIT_INDEX)='1' then state<=RESET_SHORT; end if;
          when RESET_SHORT => state<=READ_CH2_LOW;
          when READ_CH2_LOW =>
            if sw(SHORT_DELAY_DONE_SW_BIT_INDEX)='1' then
              if sw(STORE_INTO_BRAM_SW_BIT_INDEX)='1' then state<=WRITE_CH2_BRAM;
              else state<=WRITE_CH2_TRIGGER; end if;
            end if;
          when WRITE_CH2_TRIGGER | WRITE_CH2_BRAM => state<=READ_CH2_HIGH;
          when READ_CH2_HIGH =>
            if sw(SHORT_DELAY_DONE_SW_BIT_INDEX)='1' then state<=WAIT_FOR_END_OF_SAMPLE_INTERVAL; end if;
          when WAIT_FOR_END_OF_SAMPLE_INTERVAL =>
            if sw(SAMPLE_INTERVAL_DONE_SW_BIT_INDEX)='1' then state<=BRAM_FULL; end if;
          when BRAM_FULL =>
            if sw(STORE_INTO_BRAM_SW_BIT_INDEX)='1' then
              if sw(MEM_FULL_SW_BIT_INDEX)='1' then
                if sw(FORCED_MODE_SW_BIT_INDEX)='1' then state<=WAIT_FORCED_STATE;
                else state<=CLEAR_STORE_FLAG_STATE; end if;
              else state<=BEGIN_CONVERSION; end if;
            elsif sw(FORCED_MODE_SW_BIT_INDEX)='1' then state<=WAIT_FORCED_STATE;
            elsif sw(CH1_TRIGGER_SW_BIT_INDEX)='1' then state<=SET_STORE_FLAG_STATE;
            else state<=BEGIN_CONVERSION; end if;
        end case;
      end if;
    end if;
  end process;

  -- Exactly the bit assignments in the instructor's controlWord.xlsx.
  -- Defaults are idle ADC pins, holding address, resetting short timer,
  -- incrementing sample timer. Override fields for each Moore state.
  output_process: process(state)
    variable c: std_logic_vector(CW_WIDTH-1 downto 0);
  begin
    c := (others=>'0');
    c(CONVST_CW_BIT_INDEX):='1'; c(RD_CW_BIT_INDEX):='1'; c(CS_CW_BIT_INDEX):='1';
    c(1 downto 0):=RESET_COUNT;
    c(7 downto 6):=INC_COUNT;
    if state>=BEGIN_CONVERSION and state<=READ_CH2_HIGH then
      c(CONVERSION_PLUS_READOUT_CW_BIT_INDEX):='1';
    end if;
    case state is
      when RESET_STATE =>
        c(9 downto 8):=RESET_COUNT; c(7 downto 6):=RESET_COUNT;
        c(3 downto 2):=RESET_COUNT; c(CLEAR_STORE_FLAG_CW_BIT_INDEX):='1';
      when LONG_DELAY_STATE =>
        c(3 downto 2):=INC_COUNT; c(7 downto 6):=RESET_COUNT;
      when RESET_AD7606_STATE =>
        c(RESET_AD7606_CW_BIT_INDEX):='1'; c(1 downto 0):=INC_COUNT;
        c(7 downto 6):=RESET_COUNT;
           when WAIT_FORCED_STATE =>
        c(1 downto 0) := HOLD_COUNT;
        c(7 downto 6) := RESET_COUNT;
        c(CLEAR_STORE_FLAG_CW_BIT_INDEX) := '1';
      when SET_STORE_FLAG_STATE =>
        c(1 downto 0) := HOLD_COUNT;
        c(SET_STORE_FLAG_CW_BIT_INDEX) := '1';
        c(9 downto 8) := RESET_COUNT;
      when CLEAR_STORE_FLAG_STATE =>
        c(CLEAR_STORE_FLAG_CW_BIT_INDEX):='1'; c(9 downto 8):=RESET_COUNT;
      when BEGIN_CONVERSION =>
        c(SAMPLE_TIMER_ROLLOVER_CW_BIT_INDEX):='1'; c(7 downto 6):=RESET_COUNT;
      when ASSERT_CONVST =>
        c(CONVST_CW_BIT_INDEX):='0'; c(1 downto 0):=INC_COUNT;
      when WAIT_BUSY_0 | WAIT_BUSY_1 => null;
      when READ_CH1_LOW | READ_CH2_LOW =>
        c(CS_CW_BIT_INDEX):='0'; c(RD_CW_BIT_INDEX):='0'; c(1 downto 0):=INC_COUNT;
      when WRITE_CH1_TRIGGER =>
        c(CS_CW_BIT_INDEX):='0'; c(RD_CW_BIT_INDEX):='0'; c(TRIG_CH1_WRITE_CW_BIT_INDEX):='1';
      when WRITE_CH1_BRAM =>
        c(CS_CW_BIT_INDEX):='0'; c(RD_CW_BIT_INDEX):='0'; c(DATA_STORAGE_CH1_WRITE_CW_BIT_INDEX):='1';
      when READ_CH1_HIGH | READ_CH2_HIGH =>
        c(CS_CW_BIT_INDEX):='0'; c(1 downto 0):=INC_COUNT;
      when RESET_SHORT => c(CS_CW_BIT_INDEX):='0';
      when WRITE_CH2_TRIGGER =>
        c(CS_CW_BIT_INDEX):='0'; c(RD_CW_BIT_INDEX):='0'; c(TRIG_CH2_WRITE_CW_BIT_INDEX):='1';
      when WRITE_CH2_BRAM =>
        c(CS_CW_BIT_INDEX):='0'; c(RD_CW_BIT_INDEX):='0'; c(DATA_STORAGE_CH2_WRITE_CW_BIT_INDEX):='1';
        c(9 downto 8):=INC_COUNT; -- advance only AFTER both channels use this address
      when WAIT_FOR_END_OF_SAMPLE_INTERVAL | BRAM_FULL => null;
    end case;
    cw<=c;
  end process;
end architecture;
