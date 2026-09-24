----------------------------------------------------------------------------------
-- Nathan & Aaron
-- EENG484 
-- September 23, 2026
--
--	Ascii art showing monitor and O'scope face
--				----------------------------------------|
--				|										|
--				|	|-------------------------------|	|
--				|	|(UL)					    (UR)|	|
--				|	|								|	|
--				|	|								|	|
--				|	|								|	|
--				|	|								|	|
--				|	|								|	|
--				|	|(LL)					    (LR)|	|
--				|	|-------------------------------|	|
--				|										|
--				|										|
--				----------------------------------------|
--              SQUARE GRID: 700x700p drawable area, centered in 1280x720p
--				UL = Upper Left = (290, 10)
--				UR = Upper Right = (990, 10)
--				LL = Lower Left = (290, 710)
--				LR = Lower Right = (990, 710)
--				Total scope display is 1280 x 720
--              Border
--				There are 10 major horiziontal divisions (70 pixels between divisions)	
--					Each division will have 4 hatch marks (14 pixels between hatches)
--				There are 10 major vertcal divisions (70 pixels between divisions)
--					Each division will have 4 hatch marks (14 pixels between hatches)
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;

package scopeToHdmi_package is
-- 11bit number is needed to store the 1650 pixel cycle for horzontal (vertical is 750, can also be represented with 11bits) 
    constant VIDEO_WIDTH_IN_BITS: NATURAL := 11;
    
-- HORIZONTAL VIDEO CYCLE FOR 1280x720 HDMI
    constant H_ACTIVE : STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0) := std_logic_vector(to_unsigned(1280, VIDEO_WIDTH_IN_BITS));
    constant H_FP : STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0) := std_logic_vector(to_unsigned(110, VIDEO_WIDTH_IN_BITS)); 
    constant H_SYNC : STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0) := std_logic_vector(to_unsigned(40, VIDEO_WIDTH_IN_BITS));
    constant H_BP : STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0) := std_logic_vector(to_unsigned(220, VIDEO_WIDTH_IN_BITS));
    constant H_TOTAL : STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0) := H_ACTIVE + H_FP + H_SYNC + H_BP;
    
-- VERTICAL VIDEO CYCLE FOR 1280x720 HDMI
    constant V_ACTIVE : STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0) := std_logic_vector(to_unsigned(720, VIDEO_WIDTH_IN_BITS));
    constant V_FP : STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0) := std_logic_vector(to_unsigned(5, VIDEO_WIDTH_IN_BITS));	
    constant V_SYNC : STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0) := std_logic_vector(to_unsigned(5, VIDEO_WIDTH_IN_BITS)); 
    constant V_BP : STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0) := std_logic_vector(to_unsigned(20, VIDEO_WIDTH_IN_BITS));	
    constant V_TOTAL : STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0) := V_ACTIVE + V_FP + V_SYNC + V_BP;
    
-- DISPLAY VARIABLES
    -- Edges to get a 700x700p square display, centered in the 1280x720p monitor       
    constant L_EDGE : STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0) := std_logic_vector(to_unsigned(290, VIDEO_WIDTH_IN_BITS));	
    constant R_EDGE  : STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0) := std_logic_vector(to_unsigned(990, VIDEO_WIDTH_IN_BITS));	
    
    --Drawable screen width 700p
    constant WIDTH : STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0) := std_logic_vector(to_unsigned(700, VIDEO_WIDTH_IN_BITS));	 
    
    -- Top and bottom edges (recall where the coordinate axis starts on the screen: top left)
    constant T_EDGE : STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0) := std_logic_vector(to_unsigned(10, VIDEO_WIDTH_IN_BITS));	
    constant B_EDGE : STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0) := std_logic_vector(to_unsigned(710, VIDEO_WIDTH_IN_BITS));
    
    -- Drawable screen height 700p	
    constant HEIGHT : STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0) := std_logic_vector(to_unsigned(700, VIDEO_WIDTH_IN_BITS));	 
    
	-- This is actually half of the width
    constant BORDER_LINE_WIDTH : STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0) := std_logic_vector(to_unsigned(3, VIDEO_WIDTH_IN_BITS));	

	-- RGB color values
-- BORDER: WHITE
    constant BORDER_R : STD_LOGIC_VECTOR(7 downto 0) := X"FF";
    constant BORDER_G : STD_LOGIC_VECTOR(7 downto 0) := X"FF";
    constant BORDER_B : STD_LOGIC_VECTOR(7 downto 0) := X"FF";
    
-- GRID: GREY
    constant GRID_R : STD_LOGIC_VECTOR(7 downto 0) := std_logic_vector(TO_UNSIGNED(64, 8));
    constant GRID_G : STD_LOGIC_VECTOR(7 downto 0) := std_logic_vector(TO_UNSIGNED(64, 8));
    constant GRID_B : STD_LOGIC_VECTOR(7 downto 0) := std_logic_vector(TO_UNSIGNED(64, 8));
    
-- CH1: YELLOW
    constant CH1_R : STD_LOGIC_VECTOR(7 downto 0) := X"FF";
    constant CH1_G : STD_LOGIC_VECTOR(7 downto 0) := X"FF";
    constant CH1_B : STD_LOGIC_VECTOR(7 downto 0) := X"00";
    
-- CH2: GREEN
    constant CH2_R : STD_LOGIC_VECTOR(7 downto 0) := X"00";
    constant CH2_G : STD_LOGIC_VECTOR(7 downto 0) := X"FF";
    constant CH2_B : STD_LOGIC_VECTOR(7 downto 0) := X"00";
    
-- TRIGGER: CYAN
    constant TRIGGER_R : STD_LOGIC_VECTOR(7 downto 0) := X"00";
    constant TRIGGER_G : STD_LOGIC_VECTOR(7 downto 0) := X"FF";
    constant TRIGGER_B : STD_LOGIC_VECTOR(7 downto 0) := X"FF";
    
-- CONSTANTS SET FOR DIVISONS   
    constant NUM_DIVISIONS : NATURAL := 10;
    constant WIDTH_N : NATURAL := to_integer(unsigned(WIDTH));
    constant HEIGHT_N : NATURAL := to_integer(unsigned(HEIGHT));
    constant H_DIV_PIXELS : NATURAL := WIDTH_N / NUM_DIVISIONS;
    constant V_DIV_PIXELS : NATURAL := HEIGHT_N / NUM_DIVISIONS;

-- CONSTANTS SET FOR HATCHES       
    constant HATCH_PER_DIV : NATURAL := 4;
    constant H_HATCH_PIXELS : NATURAL := H_DIV_PIXELS / (HATCH_PER_DIV + 1);
    constant V_HATCH_PIXELS : NATURAL := V_DIV_PIXELS / (HATCH_PER_DIV + 1);
    constant HATCH_HALF_LEN : NATURAL := 4;
    constant H_CENTER : NATURAL := 640;
    constant V_CENTER : NATURAL := 360;

component videoSignalGenerator is
    PORT( clk: in  STD_LOGIC;
         resetn : in  STD_LOGIC;
         hs: out STD_LOGIC;
         vs: out STD_LOGIC;
         de: out STD_LOGIC;
         pixelHorz: out STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0);
         pixelVert: out STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0)
         );
end component;

component scopeFace is
    PORT ( clk: in  STD_LOGIC;
         resetn : in  STD_LOGIC;
         pixelHorz : in  STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS - 1 downto 0);
         pixelVert : in  STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS -1 downto 0);
         triggerVolt: in STD_LOGIC_VECTOR (VIDEO_WIDTH_IN_BITS - 1 downto 0);
         triggerTime: in STD_LOGIC_VECTOR (VIDEO_WIDTH_IN_BITS - 1 downto 0);
         red : out  STD_LOGIC_VECTOR(7 downto 0);
         green : out  STD_LOGIC_VECTOR(7 downto 0);
         blue : out  STD_LOGIC_VECTOR(7 downto 0);
         ch1: in STD_LOGIC;
         ch1Enb: in STD_LOGIC;
         ch2: in STD_LOGIC;
         ch2Enb: in STD_LOGIC
         );
end component;

component clk_wiz_0 is
    PORT( clk_out1: out STD_LOGIC;
        clk_out2: out STD_LOGIC;
        resetn: in STD_LOGIC;
        locked: out STD_LOGIC;
        clk_in1: in STD_LOGIC
        );
end component;


component hdmi_tx_0 is
    PORT ( pix_clk: in STD_LOGIC;
        pix_clkx5: in STD_LOGIC;           
        pix_clk_locked: in STD_LOGIC;       
        rst: in STD_LOGIC;                  
        red : in STD_LOGIC_VECTOR(7 downto 0);
        green : in STD_LOGIC_VECTOR(7 downto 0);
        blue : in STD_LOGIC_VECTOR(7 downto 0);
        hsync: in STD_LOGIC;
        vsync: in STD_LOGIC;
        vde: in STD_LOGIC;
        aux0_din: in STD_LOGIC_VECTOR(3 downto 0);
        aux1_din: in STD_LOGIC_VECTOR(3 downto 0);
        aux2_din: in STD_LOGIC_VECTOR(3 downto 0);
        ade: in STD_LOGIC;            
        TMDS_CLK_P: out STD_LOGIC;
        TMDS_CLK_N: out STD_LOGIC;
        TMDS_DATA_P: out STD_LOGIC_VECTOR(2 downto 0);
        TMDS_DATA_N: out STD_LOGIC_VECTOR(2 downto 0)
        );
end component;

component scopeToHdmi is
    PORT ( sysClk : in  STD_LOGIC;
         resetn : in  STD_LOGIC;
         btn: in	STD_LOGIC_VECTOR(2 downto 0);
         tmdsDataP : out  STD_LOGIC_VECTOR (2 downto 0);
         tmdsDataN : out  STD_LOGIC_VECTOR (2 downto 0);
         tmdsClkP : out STD_LOGIC;
         tmdsClkN : out STD_LOGIC;
         hdmiOen:    out STD_LOGIC 
         );
end component;
     
        	
end package;
