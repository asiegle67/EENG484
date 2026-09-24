----------------------------------------------------------------------------------
-- Nathan & Aaron
-- EENG484 
-- September 23, 2026
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use work.scopeToHdmi_package.all;

entity scopeToHdmi is
    PORT ( sysClk : in  STD_LOGIC;
         resetn : in  STD_LOGIC;
         btn: in	STD_LOGIC_VECTOR(2 downto 0);
         tmdsDataP : out  STD_LOGIC_VECTOR (2 downto 0);
         tmdsDataN : out  STD_LOGIC_VECTOR (2 downto 0);
         tmdsClkP : out STD_LOGIC;
         tmdsClkN : out STD_LOGIC;
         hdmiOen:    out STD_LOGIC);
end scopeToHdmi;


architecture structure of scopeToHdmi is
    -- Video timing signals sent from videoSignalGenerator to the HDMI transmitter
    signal hs, vs, de : STD_LOGIC;
    -- Button state signals used to detect a press/release event
    signal prevButton, currButton, activeButton : STD_LOGIC_VECTOR(2 downto 0);
    signal red, green, blue: STD_LOGIC_VECTOR(7 downto 0);
    signal triggerTime, triggerVolt: STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS - 1 downto 0);
    signal pixelHorz, pixelVert: STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS - 1 downto 0);
    signal ch1Wave, ch2Wave: STD_LOGIC;
    signal videoClk, videoClk5x, clkLocked: STD_LOGIC;
    -- Internal HDMI reset
    signal hdmiRst : STD_LOGIC;
    
begin
    -- HDMI TX reset is the negation of resetn
    hdmiRst <= not resetn;
    --HDMI enable
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

-- Logic to see if a button has changed state
-- Can use the activeButton to change the position of the triggers
--BTN is 3bit, encoding: [432]
--0 pressed, 1 released
   process(sysClk)
    begin
        if rising_edge(sysClk) then
            if resetn = '0' then
                prevButton <= (others => '1');
                currButton <= (others => '1');
            else
                prevButton <= currButton;
                currButton <= btn;
            end if;
        end if;
    end process;
    -- This changes when a button state changes
    activeButton <= currButton xor prevButton;
    
--Trigger buttons logic
--PL_KEY3 is voltage trigger, PL_KEY4 is time trigger
-- Release each to decrease by 10, hold PL_KEY2 and press to increase by 10
process(sysClk)
begin
    if rising_edge(sysClk) then
        if resetn = '0' then
        -- start the triangles in default pos. on centers
        triggerVolt <= STD_LOGIC_VECTOR(to_unsigned(V_CENTER, VIDEO_WIDTH_IN_BITS));
        triggerTime <= STD_LOGIC_VECTOR(to_unsigned(H_CENTER, VIDEO_WIDTH_IN_BITS));
            --Voltage trigger
            -- PL_KEY3 changed state and was released
            elsif (activeButton(1) = '1') and (currButton(1) = '1') then
                -- Hold PL_KEY2 to increase, otherwise decrease
                if currButton(0) = '0' then
                    triggerVolt <= triggerVolt + 10;
                else
                    triggerVolt <= triggerVolt - 10;
                end if;
            -- PL_KEY4 changed state and was released
            elsif (activeButton(2) = '1') and (currButton(2) = '1') then
                -- Hold PL_KEY2 to increase; otherwise decrease
                if currButton(0) = '0' then
                    triggerTime <= triggerTime + 10;
                else
                    triggerTime <= triggerTime - 10;
                end if;
            end if;
        end if;
    end process;

    ch1Wave <= '1' when  (pixelHorz = pixelVert) else '0';
    ch2Wave <= '1' when  (pixelVert = triggerVolt) else '0';

end structure;
