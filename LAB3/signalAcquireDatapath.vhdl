--------------------------------------------------------------------
-- Name:	Chris Coulston
-- Date:	Feb 3, 2015
-- Modified:	Sept 2022
-- File:	lab2_datapath.vhdl
-- HW:	Lab 2
--	Crs:	ECE 383 and EENG 498
--
-- Purp: The datapath for the audio O'scope
--
-- Documentation:	No help, though I used an example from my Digital
--						Design text book.
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
use work.basicBuildingBlocks_package.all;
use work.signalAcquire_Package.all;

entity signalAcquire_Datapath is
    PORT ( clk : in  STD_LOGIC;
           resetn : in  STD_LOGIC;
		   cw : in STD_LOGIC_VECTOR(CW_WIDTH -1 downto 0);
		   sw : out STD_LOGIC_VECTOR(DATAPATH_SW_WIDTH - 1 downto 0);
		   an7606data: in STD_LOGIC_VECTOR(15 downto 0);
		   rfAddr: in STD_LOGIC_VECTOR(2 downto 0);
		   rfData: out STD_LOGIC_VECTOR(15 downto 0) );
end signalAcquire_Datapath;

architecture behavior of signalAcquire_Datapath is

    -- Needed to connect the short and long counter output to the respective compare
    signal longDelayCounter : STD_LOGIC_VECTOR(LONG_DELAY_50Mhz_CONST_WIDTH - 1 downto 0);
    signal shortDelayCounter : STD_LOGIC_VECTOR(SHORT_DELAY_50Mhz_CONST_WIDTH - 1 downto 0);
    -- connection between the channel counter and channelcompare+register file
    signal regCounter : STD_LOGIC_VECTOR(2 downto 0);

begin
    --LONG DELAY COUNTER    
    -- Output q to compare input
    longDelayCounter_inst: genericCounter
    GENERIC MAP (LONG_DELAY_50Mhz_CONST_WIDTH)
    PORT MAP (
        clk    => clk,
        resetn => resetn,
        c      => cw(3 downto 2),
        d      => (others => '0'),
        q      => longDelayCounter
    );
    -- LONG DELAY COMPARATOR
    -- SW[2]: high when compare reaches long delay
    longDelayCompare_inst: genericCompare
        GENERIC MAP (LONG_DELAY_50Mhz_CONST_WIDTH)
        PORT MAP (
            x => longDelayCounter,
            y => LONG_DELAY_50Mhz_COUNTS,
            g => open,
            l => open,
            e => sw(LONG_DELAY_DONE_SW_BIT_INDEX)
        );

    -- SHORT DELAY COUNTER
    -- Output q to short delay compare
    shortDelayCounter_inst: genericCounter
        GENERIC MAP (SHORT_DELAY_50Mhz_CONST_WIDTH)
        PORT MAP (
            clk    => clk,
            resetn => resetn,
            c      => cw(1 downto 0),
            d      => (others => '0'),
            q      => shortDelayCounter
        );
    -- SHORT DELAY COMPARATOR
    -- SW[1]: high when compare reaches short delay
    shortDelayCompare_inst: genericCompare
        GENERIC MAP (SHORT_DELAY_50Mhz_CONST_WIDTH)
        PORT MAP (
            x => shortDelayCounter,
            y => SHORT_DELAY_50Mhz_COUNTS,
            g => open,
            l => open,
            e => sw(SHORT_DELAY_DONE_SW_BIT_INDEX)
        );

    -- Channel # counter
    -- Outputs to compare and regfile
    channelCounter_inst: genericCounter
        GENERIC MAP (3)
        PORT MAP (
            clk    => clk,
            resetn => resetn,
            c      => cw(5 downto 4),
            d      => (others => '0'),
            q      => regCounter
        );
    
    -- Channel compare, sends SW when last channel has been read
    channelCompare_inst: genericCompare
        GENERIC MAP (3)
        PORT MAP (
            x => regCounter,
            y => "111",
            g => open,
            l => open,
            e => sw(ALL_CHANNELS_HAVE_BEEN_READ_SW_BIT_INDEX)
        );
    
    -- Write to the register of respective channel
    adSamples_inst: generic8RegisterFile
        GENERIC MAP (16)
        PORT MAP (
            clk    => clk,
            resetn => resetn,
            write  => cw(REF_FILE_WRITE_CW_BIT_INDEX),
            wrAddr => regCounter,
            rdAddr => rfAddr,
            D      => an7606data,
            Q      => rfData
        );
end behavior;

