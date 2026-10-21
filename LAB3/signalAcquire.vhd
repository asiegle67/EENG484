--------------------------------------------------------------------
-- Name:	Chris Coulston
-- Date:	Fall 2022
-- File:	signalAcquire.vhd
--
-- Purp: Tie the datapath and control unit together
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
use work.signalAcquire_Package.all;

entity signalAcquire is
    PORT ( clk : in  STD_LOGIC;
           resetn : in  STD_LOGIC;
		   btn: in	STD_LOGIC_VECTOR(2 downto 0);
		   an7606data: in STD_LOGIC_VECTOR(15 downto 0);
		   an7606convst, an7606cs, an7606rd, an7606reset: out STD_LOGIC;
		   an7606od: out STD_LOGIC_VECTOR(2 downto 0);
		   an7606busy : in STD_LOGIC;
		   reg0Magnitude: out STD_LOGIC_VECTOR(3 downto 0));		   
end signalAcquire;


architecture behavior of signalAcquire is
    -- Red blue and green wires in the schematic (
    signal cw : STD_LOGIC_VECTOR(CW_WIDTH - 1 downto 0);
    signal sw : STD_LOGIC_VECTOR(SW_WIDTH - 1 downto 0);
    signal reg0Data : STD_LOGIC_VECTOR(15 downto 0);	
    -- signals for register buffer
    signal busyMeta, busySync : STD_LOGIC;
    --button
    signal btnMeta, btnSync, btnPrevious : STD_LOGIC;
begin

    -- Instantiate FSM
    control_inst: signalAcquire_Fsm
        PORT MAP (
            clk => clk,
            resetn => resetn,
            sw => sw,
            cw => cw
        );
    
    -- Instantiate DP
    datapath_inst: signalAcquire_Datapath
        PORT MAP (
            clk        => clk,
            resetn     => resetn,
            cw         => cw,
            sw         => sw(DATAPATH_SW_WIDTH - 1 downto 0),
            an7606data => an7606data,
            rfAddr     => "000",
            rfData     => reg0Data
        );
        
    --Connect FSM CW bits to ADC outtput ports
    an7606convst <= cw(CONVST_CW_BIT_INDEX);
    an7606rd <= cw(RD_CW_BIT_INDEX);
    an7606cs <= cw(CS_CW_BIT_INDEX);
    an7606reset <= cw(RESET_AD7606_CW_BIT_INDEX);
    an7606od <= "000";
    
    -- Becaause the ADC is not clocked to the FPGA, we make a register buffer to avoid 
    -- inputs not on edges. 
    busySync_process: process(clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                busyMeta <= '0';
                busySync <= '0';
            else
                busyMeta <= an7606busy;
                busySync <= busyMeta;
            end if;
        end if;
    end process;
    
    -- Similar to the ADC input, we make sure the button isnt mis aligned with the clk
    -- start conv when we detect a change with the xor
    sw(BUSY_SW_BIT_INDEX) <= busySync;
    button_process: process(clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                btnMeta <= '1';
                btnSync <= '1';
                btnPrevious <= '1';
            else
                btnMeta <= btn(0);
                btnSync <= btnMeta;
                btnPrevious <= btnSync;
            end if;
        end if;
    end process;

    sw(START_CONV_SW_BIT_INDEX) <= btnSync xor btnPrevious;
    
    -- LED magnitude indications 
    reg0Magnitude(0) <= '1' when
        signed(reg0Data) > signed(FIRST_THRESHOLD_CONSTANT)
        else '0';
    reg0Magnitude(1) <= '1' when
        signed(reg0Data) > signed(SECOND_THRESHOLD_CONSTANT)
        else '0';
    reg0Magnitude(2) <= '1' when
        signed(reg0Data) > signed(THIRD_THRESHOLD_CONSTANT)
        else '0';
    reg0Magnitude(3) <= '1' when
        signed(reg0Data) > signed(FOURTH_THRESHOLD_CONSTANT)
        else '0';
    
end behavior;

