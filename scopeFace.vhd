----------------------------------------------------------------------------------
-- Nathan & Aaron
-- EENG484 
-- September 23, 2026
-- ***Do not use mod operator in this code***
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Access to package constants
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
    --SO waveform comes first in elif
    ---------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge (clk) then
            if resetn = '0' then
                red <= (others => '0');
                green <= (others => '0');
                blue <= (others => '0');
            else
                -- border and trigger triangles first, omnipresent
                if ((borderH = '1') or (borderV = '1')) then
                    red <= BORDER_R;
                    green <= BORDER_G;
                    blue <= BORDER_B;
                -- trigger  
                elsif (triggerVoltMark = '1') or (triggerTimeMark = '1') then
                    red <= TRIGGER_R;
                    green <= TRIGGER_G;
                    blue <= TRIGGER_B;
                --Waveforms next, should go above grid/hatches
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


--DEFINING THE AREAS WHERE EACH DRAWING IS TRUE
    borderH <= '1' when
    --VERTICAL CONSTRAINTS: Inbetween the top and bottom border edges
        (((pixelVert >= T_EDGE - BORDER_LINE_WIDTH) and (pixelVert <= T_EDGE + BORDER_LINE_WIDTH)) 
        or ((pixelVert >= B_EDGE - BORDER_LINE_WIDTH) and (pixelVert <= B_EDGE + BORDER_LINE_WIDTH))) and
    -- HORIZONTAL CONSTRAINTS: within the left and right border bounds
        (pixelHorz >= L_EDGE - BORDER_LINE_WIDTH) and (pixelHorz <= R_EDGE + BORDER_LINE_WIDTH)
        else '0';
    
    borderV <= '1' when
    -- HORIZONTAL CONSTRAINTS: Between the left or right widths
        (((pixelHorz >= L_EDGE - BORDER_LINE_WIDTH) and (pixelHorz <= L_EDGE + BORDER_LINE_WIDTH)) 
        or ((pixelHorz >= R_EDGE - BORDER_LINE_WIDTH) and (pixelHorz <= R_EDGE + BORDER_LINE_WIDTH))) and
        --VERTICAL CONSTRAINTS: within the height of the frame
        (pixelVert >= T_EDGE - BORDER_LINE_WIDTH) and (pixelVert <= B_EDGE + BORDER_LINE_WIDTH)
        else '0';
            
    -- CH1: X green line @ volt trigger
    drawCh1 <= '1' when
        (insideGrid = '1') and
        (ch1Enb = '1') and
        (ch1 = '1')
        else '0';
    
    -- CH2: diagonal line
    drawCh2 <= '1' when
        (insideGrid = '1') and
        (ch2Enb = '1') and
        (ch2 = '1')
        else '0';

-- Trigger Triangles
    --Volt on left, y-axis
    triggerVoltMark <= '1' when
        (insideGrid = '1') and
        -- Triangle base to tip: 10 pixels
        (pixelHorz >= L_EDGE + BORDER_LINE_WIDTH + 1) and (pixelHorz <= L_EDGE + BORDER_LINE_WIDTH + 11)
        -- Triangle height: +- 10pixels from the marker
        and (pixelVert <= triggerVolt + (L_EDGE + BORDER_LINE_WIDTH + 11 - pixelHorz))
        -- Add distance rather than subtracting it from triggerVolt, avoiding unsigned underflow
        and (pixelVert + (L_EDGE + BORDER_LINE_WIDTH + 11 - pixelHorz) >= triggerVolt)
        else '0';
        
    --Time on top, x-axis
    triggerTimeMark <= '1' when
        (insideGrid = '1') and
        -- Triangle base to tip: 10 pixels
        (pixelVert >= T_EDGE + BORDER_LINE_WIDTH + 1) and (pixelVert <= T_EDGE + BORDER_LINE_WIDTH + 11)
        -- Triangle width: +-10 pixels at its base
        and (pixelHorz <= triggerTime + (T_EDGE + BORDER_LINE_WIDTH + 11 - pixelVert))
        -- Add distance rather than subtracting it from triggerTime, avoiding unsigned underflow
        and (pixelHorz + (T_EDGE + BORDER_LINE_WIDTH + 11 - pixelVert) >= triggerTime)
        else '0';
        
    --Helper for drawing grid
    insideGrid <= '1' when
        -- within the bounds
        (pixelHorz > L_EDGE + BORDER_LINE_WIDTH) and
        (pixelHorz < R_EDGE - BORDER_LINE_WIDTH) and
        (pixelVert > T_EDGE + BORDER_LINE_WIDTH) and
        (pixelVert < B_EDGE - BORDER_LINE_WIDTH)
        else '0';
        
    -- grid and hash marks
    process(pixelHorz, pixelVert, insideGrid)
        variable gV, gH, hV, hH : STD_LOGIC;
    begin
        -- initialize the variables
        gV := '0';
        gH := '0';
        hV := '0';
        hH := '0';
        -- loop for the grid position
        for k in 1 to NUM_DIVISIONS - 1 loop
            -- if horz/vert falls within the edge and the correct division of pixels, then high
            if pixelHorz = L_EDGE + k*H_DIV_PIXELS then gV := '1'; 
                end if;
            if pixelVert = T_EDGE + k*V_DIV_PIXELS then gH := '1';
                end if;
        end loop;  
        -- loop for the hatch position  
        for k in 1 to NUM_DIVISIONS*HATCH_PER_DIV - 1 loop
            -- if horz/vert falls within the edge and the correct division of pixels, then high
            if pixelHorz = L_EDGE + k*H_HATCH_PIXELS then hV := '1'; 
                end if;
            if pixelVert = T_EDGE + k*V_HATCH_PIXELS then hH := '1';
                end if;
        end loop;
        
        -- clipping for edge of screen for grid
        if insideGrid = '1'
            then gridV <= gV;
        else gridV <= '0';
        end if;
        if insideGrid = '1'
            then gridH <= gH;
        else gridH <= '0';
        end if;     
        
        -- clipping for hatches for edge of screen -- if it's in the center and within the hatch division
        if (pixelVert >= V_CENTER - HATCH_HALF_LEN) and (pixelVert <= V_CENTER + HATCH_HALF_LEN)
            then hatchV <= hV;
        else hatchV <= '0'; 
        end if;
        if(pixelHorz >= H_CENTER - HATCH_HALF_LEN) and (pixelHorz <= H_CENTER + HATCH_HALF_LEN)
            then hatchH <= hH; 
        else hatchH <= '0'; 
        end if;

    end process;

end Behavioral;

