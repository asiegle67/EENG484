----------------------------------------------------------------------------------
-- Include proper comment header block
-- ***Do not use mod operator in this code***
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.scopeToHdmi_package.all;

entity scopeFace is
    PORT ( 	clk: in  STD_LOGIC;
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
         ch2Enb: in STD_LOGIC);
end scopeFace;


architecture Behavioral of scopeFace is

    -- Set these signals to '1' when the features should be drawn at the current pixelHorz, pixelVert 
    -- cordinate.  These act like Feature Booleans which you will use in the process(clk) to set the 
    -- correct RGB for this pixel location. Finish and add more.
    signal borderH, borderV, gridH, gridV, hatchH, hatchV, triggerVoltMark, triggerTimeMark, insideGrid, drawCh1, drawCh2 : STD_LOGIC;


begin           

    ---------------------------------------------------------------------
    -- Use the Feature Booleans to set the RGB at this pixel location.
    -- The waveforms should sit "on top" of the grid.
    ---------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge (clk) then
            if resetn = '0' then
                red <= (others => '0');
                green <= (others => '0');
                blue <= (others => '0');
            else
                -- border
                if ((borderH = '1') or (borderV = '1')) then
                    red <= BORDER_R;
                    green <= BORDER_G;
                    blue <= BORDER_B;
                -- ch1
                elsif drawCh1 = '1' then
                    red <= CH1_R;
                    green <= CH1_G;
                    blue <= CH1_B;
                -- ch2
                elsif drawCh2 = '1' then
                    red <= CH2_R;
                    green <= CH2_G;
                    blue <= CH2_B;  
                -- trigger  
                elsif (triggerVoltMark = '1') and (triggerTimeMark = '1') then
                    red <= TRIGGER_R;
                    green <= TRIGGER_G;
                    blue <= TRIGGER_B;
                -- grid
                elsif (gridH = '1') or (gridV = '1') or (hatchH = '1') or (hatchV = '1') then
                    red <= GRID_R;
                    green <= GRID_G;
                    blue <= GRID_B;
                -- black/screen background
                else
                    red <= X"00";
                    green <= X"00";
                    blue <= X"00";
                end if;
            end if;
        end if;
    end process;


    borderH <= '1' when 
        -- check top or bottom Edge
        ((pixelHorz >= T_EDGE - BORDER_LINE_WIDTH) and (pixelHorz <= T_EDGE - BORDER_LINE_WIDTH) or
        (pixelHorz >= B_EDGE - BORDER_LINE_WIDTH) and (pixelHorz <= B_EDGE - BORDER_LINE_WIDTH)) and
        -- inside L and R EDGE
        (pixelHorz >= L_EDGE - BORDER_LINE_WIDTH) and (pixelHorz <= R_EDGE - BORDER_LINE_WIDTH)
        else '0';
        
    borderV <=	'1' when
        -- check L or R Edge
        ((pixelHorz >= L_EDGE - BORDER_LINE_WIDTH) and (pixelHorz <= L_EDGE - BORDER_LINE_WIDTH) or
        (pixelHorz >= R_EDGE - BORDER_LINE_WIDTH) and (pixelHorz <= R_EDGE - BORDER_LINE_WIDTH)) and
        -- inside top and bottom EDGE
        (pixelHorz >= T_EDGE - BORDER_LINE_WIDTH) and (pixelHorz <= B_EDGE - BORDER_LINE_WIDTH)
        else '0';
    
    insideGrid <= '1' when
        -- pixelHorz and pixelVert inside edge size
        (pixelHorz > L_EDGE + BORDER_LINE_WIDTH) and (pixelHorz < R_EDGE - BORDER_LINE_WIDTH) and
        (pixelVert > T_EDGE + BORDER_LINE_WIDTH) and (pixelVert < B_EDGE - BORDER_LINE_WIDTH)
        else '0';
  
    -- grid and hash marks
    process(pixelHorz, pixelVert)
        variable gV, gH, hV, hH : STD_LOGIC;
    begin
        -- initialize the variables
        gV := '0';
        gH := '0';
        hV := '0';
        hH := '0';
        -- loop for the grid position
        for k in 1 to NUM_DIVISIONS - 1 loop
            if pixelHorz = L_EDGE + k*H_DIV_PIXELS then gV := '1'; 
                end if;
            if 
        

end Behavioral;


