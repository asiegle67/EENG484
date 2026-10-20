--------------------------------------------------------------------
-- Name:	Aaron Siegle & Nathan Johnston
-- Date:	Fall 2026
-- File:	signalAcquire_Package.vhd
--
-- Purp: Defines signalAcquire specific components and defines constants
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


package signalAcquire_Package is


-- Clock period definitions
constant clk_period : time := 20 ns;			-- 50Mhz crystal input (XTL_IN).
   
-- Assign constants in FSM for fixed position
CONSTANT CONVST_CW_BIT_INDEX : NATURAL := 10;
CONSTANT RD_CW_BIT_INDEX : NATURAL := 9;
CONSTANT CS_CW_BIT_INDEX : NATURAL := 8;
CONSTANT RESET_AD7606_CW_BIT_INDEX : NATURAL := 7;
CONSTANT REF_FILE_WRITE_CW_BIT_INDEX : NATURAL := 6;

-- Added variables
-- CONSTANT REG_COUNTER_CW_LSB_INDEX : NATURAL := 4;
-- LONG_DELAY_COUNTER_CW_LSB_INDEX : NATURAL := 2;
-- SHORT_DELAY_COUNTER_CW_LSB_INDEX : NATURAL := 0;

-- where it is placed within the array
CONSTANT ALL_CHANNELS_HAVE_BEEN_READ_SW_BIT_INDEX : NATURAL := 0;
CONSTANT SHORT_DELAY_DONE_SW_BIT_INDEX : NATURAL := 1;
CONSTANT LONG_DELAY_DONE_SW_BIT_INDEX : NATURAL := 2;
-- the button pressed --> already assigned from datasheet
CONSTANT DATAPATH_SW_WIDTH : NATURAL := 3;


CONSTANT START_CONV_SW_BIT_INDEX : NATURAL := ?;
CONSTANT BUSY_SW_BIT_INDEX : NATURAL := ?;

-- determined based off array size
CONSTANT SW_WIDTH : NATURAL := 5;
CONSTANT CW_WIDTH : NATURAL := 11;

-- length based off of total counts (65,535 counts)
CONSTANT LONG_DELAY_50Mhz_CONST_WIDTH : NATURAL := 24;
CONSTANT LONG_DELAY_50Mhz_COUNTS : STD_LOGIC_VECTOR(LONG_DELAY_50Mhz_CONST_WIDTH - 1 downto 0) := x"00FFFF";

-- length based off every pulse (16 counts)
CONSTANT SHORT_DELAY_50Mhz_CONST_WIDTH : NATURAL := 8; 
CONSTANT SHORT_DELAY_50Mhz_COUNTS : STD_LOGIC_VECTOR(SHORT_DELAY_50Mhz_CONST_WIDTH - 1 downto 0) := x"10";


-- You need to determine the 16-bit 2's complement ADC values for these voltages
CONSTANT FOURTH_THRESHOLD_CONSTANT : STD_LOGIC_VECTOR(15 downto 0)  := x"????"; --  2.64V to counts
CONSTANT THIRD_THRESHOLD_CONSTANT : STD_LOGIC_VECTOR(15 downto 0) := x"????"; --  1.98V to counts
CONSTANT SECOND_THRESHOLD_CONSTANT : STD_LOGIC_VECTOR(15 downto 0)   := x"????"; --  1.32V to counts
CONSTANT FIRST_THRESHOLD_CONSTANT : STD_LOGIC_VECTOR(15 downto 0)   := x"????"; --  0.66V to counts


-- FSM components (CU)
component signalAcquire_Fsm is
    PORT (cw : out STD_LOGIC_VECTOR(CW_WIDTH -1 downto 0);
            sw : in STD_LOGIC_VECTOR(SW_WIDTH -1 downto 0);
            clk : in STD_LOGIC;
            reset : in STD_LOGIC;
            );
end component

-- DP components
component signalAcquire_Datapath is
    PORT (cw : in STD_LOGIC_VECTOR(CW_WIDTH -1 downto 0);
            sw : out STD_LOGIC_VECTOR(SW_WIDTH -1 downto 0);
            clk : in STD_LOGIC;
            reset : in STD_LOGIC;
            rfAdder : in STD_LOGIC_VECTOR(2 downto 0);
            rfData : out STD_LOGIC_VECTOR(15 downto 0)
            );
end component   
    
type state_type is <complete>

component signalAcquire is
    PORT ( clk : in  STD_LOGIC;
           resetn : in  STD_LOGIC;
		   btn: in	STD_LOGIC_VECTOR(2 downto 0);
		   an7606data: in STD_LOGIC_VECTOR(15 downto 0);
		   an7606convst, an7606cs, an7606rd, an7606reset: out STD_LOGIC;
		   an7606od: out STD_LOGIC_VECTOR(2 downto 0);
		   an7606busy : in STD_LOGIC;
		   reg0Magnitude: out STD_LOGIC_VECTOR(3 downto 0));				   
end component;	

component an7606_tb IS
    PORT ( clk : in  STD_LOGIC;
           an7606data: out STD_LOGIC_VECTOR(15 downto 0);
           an7606convst, an7606cs, an7606rd, an7606reset: in STD_LOGIC;
           an7606od: in STD_LOGIC_VECTOR(2 downto 0);
           an7606busy : out STD_LOGIC);
END component;
    
    	
end package;


