library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.signalAcquire_Package.all;

entity signalAcquire_Fsm is
    PORT (
        clk    : in  STD_LOGIC;
        resetn : in  STD_LOGIC;
        sw     : in  STD_LOGIC_VECTOR(SW_WIDTH - 1 downto 0);
        cw     : out STD_LOGIC_VECTOR(CW_WIDTH - 1 downto 0)
    );
end signalAcquire_Fsm;

architecture Behavioral of signalAcquire_Fsm is

    signal state : state_type;

    signal SHORT_DELAY_DONE_SW : STD_LOGIC;
    signal LONG_DELAY_DONE_SW : STD_LOGIC;
    signal START_CONVERSION_SW : STD_LOGIC;
    signal BUSY_SW : STD_LOGIC;
    signal ALL_CHANNELS_HAVE_BEEN_READ_SW : STD_LOGIC;

begin

    SHORT_DELAY_DONE_SW <= sw(SHORT_DELAY_DONE_SW_BIT_INDEX);
    LONG_DELAY_DONE_SW <= sw(LONG_DELAY_DONE_SW_BIT_INDEX);
    START_CONVERSION_SW <= sw(START_CONV_SW_BIT_INDEX);
    BUSY_SW <= sw(BUSY_SW_BIT_INDEX);
    ALL_CHANNELS_HAVE_BEEN_READ_SW <= sw(ALL_CHANNELS_HAVE_BEEN_READ_SW_BIT_INDEX);

    -- State register and transitions
    state_process: process(clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                state <= RESET_STATE;
            else
                case state is

                    when RESET_STATE =>
                        state <= POWER_UP_DELAY;

                    when POWER_UP_DELAY =>
                        if LONG_DELAY_DONE_SW = '1' then
                            state <= RESET_AD7606_STATE;
                        end if;

                    when RESET_AD7606_STATE =>
                        if SHORT_DELAY_DONE_SW = '1' then
                            state <= WAIT_TRIGGER;
                        end if;

                    when WAIT_TRIGGER =>
                        if START_CONVERSION_SW = '1' then
                            state <= ASSERT_CONVST;
                        end if;

                    when ASSERT_CONVST =>
                        if SHORT_DELAY_DONE_SW = '1' then
                            state <= WAIT_BUSY_0;
                        end if;

                    when WAIT_BUSY_0 =>
                        if BUSY_SW = '1' then
                            state <= WAIT_BUSY_1;
                        end if;

                    when WAIT_BUSY_1 =>
                        if BUSY_SW = '0' then
                            state <= WAIT_VALID_DATA;
                        end if;

                    when WAIT_VALID_DATA =>
                        if SHORT_DELAY_DONE_SW = '1' then
                            state <= LATCH;
                        end if;

                    when LATCH =>
                        state <= PAUSE_BET_CHANNELS;

                    when PAUSE_BET_CHANNELS =>
                        if SHORT_DELAY_DONE_SW = '1' then
                            state <= CLEAR_SHORT_CNT;
                        end if;

                    when CLEAR_SHORT_CNT =>
                        if ALL_CHANNELS_HAVE_BEEN_READ_SW = '1' then
                            state <= WAIT_TRIGGER;
                        else
                            state <= WAIT_VALID_DATA;
                        end if;

                end case;
            end if;
        end if;
    end process;

    -- Counter commands:
    -- 00 = hold
    -- 01 = load
    -- 10 = increment
    -- 11 = reset
    output_process: process(state)
    begin

        -- Default outputs, overridden below for each state
        cw <= (others => '0');

        cw(CONVST_CW_BIT_INDEX) <= '1';
        cw(RD_CW_BIT_INDEX) <= '1';
        cw(CS_CW_BIT_INDEX) <= '1';
        cw(RESET_AD7606_CW_BIT_INDEX) <= '0';
        cw(REF_FILE_WRITE_CW_BIT_INDEX) <= '0';

        -- Hold channel address; reset delay counters by default
        cw(REG_COUNTER_CW_LSB_INDEX + 1 downto
           REG_COUNTER_CW_LSB_INDEX) <= "00";

        cw(LONG_DELAY_COUNTER_CW_LSB_INDEX + 1 downto
           LONG_DELAY_COUNTER_CW_LSB_INDEX) <= "11";

        cw(SHORT_DELAY_COUNTER_CW_LSB_INDEX + 1 downto
           SHORT_DELAY_COUNTER_CW_LSB_INDEX) <= "11";

        case state is

            when RESET_STATE =>
                cw(REG_COUNTER_CW_LSB_INDEX + 1 downto
                   REG_COUNTER_CW_LSB_INDEX) <= "11";

            when POWER_UP_DELAY =>
                cw(LONG_DELAY_COUNTER_CW_LSB_INDEX + 1 downto
                   LONG_DELAY_COUNTER_CW_LSB_INDEX) <= "10";

            when RESET_AD7606_STATE =>
                cw(RESET_AD7606_CW_BIT_INDEX) <= '1';

                cw(SHORT_DELAY_COUNTER_CW_LSB_INDEX + 1 downto
                   SHORT_DELAY_COUNTER_CW_LSB_INDEX) <= "10";

            when WAIT_TRIGGER =>
                cw(REG_COUNTER_CW_LSB_INDEX + 1 downto
                   REG_COUNTER_CW_LSB_INDEX) <= "11";

            when ASSERT_CONVST =>
                cw(CONVST_CW_BIT_INDEX) <= '0';

                cw(SHORT_DELAY_COUNTER_CW_LSB_INDEX + 1 downto
                   SHORT_DELAY_COUNTER_CW_LSB_INDEX) <= "10";

            when WAIT_BUSY_0 =>
                -- Default CONVST high starts conversion
                null;

            when WAIT_BUSY_1 =>
                -- Wait with RD and CS inactive
                null;

            when WAIT_VALID_DATA =>
                cw(CS_CW_BIT_INDEX) <= '0';
                cw(RD_CW_BIT_INDEX) <= '0';

                cw(SHORT_DELAY_COUNTER_CW_LSB_INDEX + 1 downto
                   SHORT_DELAY_COUNTER_CW_LSB_INDEX) <= "10";

            when LATCH =>
                -- Keep ADC data enabled while capturing it
                cw(CS_CW_BIT_INDEX) <= '0';
                cw(RD_CW_BIT_INDEX) <= '0';
                cw(REF_FILE_WRITE_CW_BIT_INDEX) <= '1';

                -- Default short-counter reset prepares the next delay
                -- Default channel-counter hold preserves the write address

            when PAUSE_BET_CHANNELS =>
                -- RD defaults high between channel reads
                cw(CS_CW_BIT_INDEX) <= '0';

                cw(SHORT_DELAY_COUNTER_CW_LSB_INDEX + 1 downto
                   SHORT_DELAY_COUNTER_CW_LSB_INDEX) <= "10";

            when CLEAR_SHORT_CNT =>
                cw(CS_CW_BIT_INDEX) <= '0';

                -- Advance once, after the sample has been stored
                cw(REG_COUNTER_CW_LSB_INDEX + 1 downto
                   REG_COUNTER_CW_LSB_INDEX) <= "10";

                -- Default short-counter reset prepares the next read

        end case;
    end process;

end Behavioral;
