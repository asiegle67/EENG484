#################################################################################
#Simulator TCL starts in: C:/Users/Chris/AppData/Roaming/Xilinx/Vivado
# cd C:/Users/Chris/Dropbox/Mycourses/EENG498/VHDL/lab03AcquireToHDMI    -- home
# cd C:/Users/coulston/Dropbox/Mycourses/EENG498/VHDL/lab03AcquireToHDMI -- office
# source acquireToHDMI_tbWaveSetup.tcl
#################################################################################
restart
remove_waves [get_waves *]

add_wave  -color green /acquireToHDMI_tb/uut/clk
add_wave  -color green /acquireToHDMI_tb/uut/resetn

set groupColor YELLOW
set TOP_ID [add_wave_group "topLevelIO"]
add_wave -into $TOP_ID -color $groupColor -radix unsigned /acquireToHDMI_tb/uut/btn
add_wave -into $TOP_ID -color $groupColor /acquireToHDMI_tb/uut/triggerCh1
add_wave -into $TOP_ID -color $groupColor -radix hex /acquireToHDMI_tb/uut/datapath_inst/fistCh1DataStdLogicVector
add_wave -into $TOP_ID -color $groupColor -radix hex /acquireToHDMI_tb/uut/datapath_inst/secondCh1DataStdLogicVector
add_wave -into $TOP_ID -color $groupColor /acquireToHDMI_tb/uut/datapath_inst/firstCh1GreaterThanTrigger
add_wave -into $TOP_ID -color $groupColor /acquireToHDMI_tb/uut/datapath_inst/secondCh1LessThanTrigger
add_wave -into $TOP_ID -color $groupColor /acquireToHDMI_tb/uut/conversionPlusReadoutTime
add_wave -into $TOP_ID -color $groupColor /acquireToHDMI_tb/uut/sampleTimerRollover

add_wave   -color aqua /acquireToHDMI_tb/uut/control_inst/state

set groupColor PURPLE
set COUNT_ID [add_wave_group "Counters"]
# Add sample rate counter
add_wave -into $COUNT_ID -color $groupColor -radix unsigned /acquireToHDMI_tb/uut/datapath_inst/shortDelayCounter
add_wave -into $COUNT_ID -color $groupColor -radix unsigned /acquireToHDMI_tb/uut/datapath_inst/longDelayCounter
add_wave -into $COUNT_ID -color $groupColor -radix unsigned /acquireToHDMI_tb/uut/datapath_inst/timerCounter

set groupColor ORANGE
set AD7606_ID [add_wave_group "AD7606 Interface"]
add_wave -into $AD7606_ID -color $groupColor /acquireToHDMI_tb/uut/an7606reset
add_wave -into $AD7606_ID -color $groupColor /acquireToHDMI_tb/uut/an7606convst
add_wave -into $AD7606_ID -color $groupColor /acquireToHDMI_tb/uut/an7606cs
add_wave -into $AD7606_ID -color $groupColor /acquireToHDMI_tb/uut/an7606rd
add_wave -into $AD7606_ID -color $groupColor /acquireToHDMI_tb/uut/an7606busy
add_wave -into $AD7606_ID -color $groupColor -radix hex	/acquireToHDMI_tb/uut/an7606data

# ---- BRAM group ----
# The memory[] lines use the IP's internal name blk_mem_gen_v8_4_5_inst. If your Vivado
# version made a different one (e.g. v8_4_7, v8_4_8), check the Scope window and edit
# those 4 lines, or delete them (the write address line will still work).
set groupColor YELLOW
set BRAM_ID [add_wave_group "BRAM Interface"]
add_wave -into $BRAM_ID -color $groupColor -radix unsigned -name "Ch1 Write Address" /acquireToHDMI_tb/uut/datapath_inst/dataStorage_ch1/addra
add_wave -into $BRAM_ID -color $groupColor -radix unsigned -name "Read Address" /acquireToHDMI_tb/uut/datapath_inst/rdAddr
add_wave -into $BRAM_ID -color $groupColor -radix hex -name "Ch1 BRAM out" /acquireToHDMI_tb/uut/datapath_inst/ch1BramOut
add_wave -into $BRAM_ID -color $groupColor -name "ch1Wave" /acquireToHDMI_tb/uut/datapath_inst/ch1Wave
add_wave -into $BRAM_ID -color $groupColor /acquireToHDMI_tb/uut/datapath_inst/dataStorage_ch1/inst/native_mem_module.blk_mem_gen_v8_4_5_inst/memory[0]
add_wave -into $BRAM_ID -color $groupColor /acquireToHDMI_tb/uut/datapath_inst/dataStorage_ch1/inst/native_mem_module.blk_mem_gen_v8_4_5_inst/memory[1]
add_wave -into $BRAM_ID -color $groupColor /acquireToHDMI_tb/uut/datapath_inst/dataStorage_ch1/inst/native_mem_module.blk_mem_gen_v8_4_5_inst/memory[2]
add_wave -into $BRAM_ID -color $groupColor /acquireToHDMI_tb/uut/datapath_inst/dataStorage_ch1/inst/native_mem_module.blk_mem_gen_v8_4_5_inst/memory[3]


set groupColor BLUE
set HDMI_ID [add_wave_group "Video Interface"]
add_wave -into $HDMI_ID -color $groupColor -radix unsigned /acquireToHDMI_tb/uut/datapath_inst/vsg/h_cnt
add_wave -into $HDMI_ID -color $groupColor -radix unsigned /acquireToHDMI_tb/uut/datapath_inst/vsg/pixelHorz
add_wave -into $HDMI_ID -color $groupColor -radix unsigned /acquireToHDMI_tb/uut/datapath_inst/hs
add_wave -into $HDMI_ID -color $groupColor -radix unsigned /acquireToHDMI_tb/uut/datapath_inst/vsg/v_cnt
add_wave -into $HDMI_ID -color $groupColor -radix unsigned /acquireToHDMI_tb/uut/datapath_inst/vsg/pixelVert
add_wave -into $HDMI_ID -color $groupColor -radix unsigned /acquireToHDMI_tb/uut/datapath_inst/vs
add_wave -into $HDMI_ID -color $groupColor -radix unsigned /acquireToHDMI_tb/uut/datapath_inst/de
add_wave -into $HDMI_ID -color red -radix unsigned /acquireToHDMI_tb/uut/datapath_inst/red
add_wave -into $HDMI_ID -color green -radix unsigned /acquireToHDMI_tb/uut/datapath_inst/green
add_wave -into $HDMI_ID -color blue -radix unsigned /acquireToHDMI_tb/uut/datapath_inst/blue

set groupColor MAROON
set SW_ID [add_wave_group "Status Word"]
add_wave -into $SW_ID -color $groupColor -name "FORCED MODE" 		/acquireToHDMI_tb/uut/sw[9]
add_wave -into $SW_ID -color $groupColor -name "SINGLE"              {/acquireToHDMI_tb/uut/sw[8]}
add_wave -into $SW_ID -color $groupColor -name "AN7606 BUSY"         {/acquireToHDMI_tb/uut/sw[7]}
add_wave -into $SW_ID -color $groupColor -name "CH2 TRIGGER"         {/acquireToHDMI_tb/uut/sw[6]}
add_wave -into $SW_ID -color $groupColor -name "CH1 TRIGGER"         {/acquireToHDMI_tb/uut/sw[5]}
add_wave -into $SW_ID -color $groupColor -name "STORE INTO BRAM"     {/acquireToHDMI_tb/uut/sw[4]}
add_wave -into $SW_ID -color $groupColor -name "FULL"                {/acquireToHDMI_tb/uut/sw[3]}
add_wave -into $SW_ID -color $groupColor -name "SAMPLE"              {/acquireToHDMI_tb/uut/sw[2]}
add_wave -into $SW_ID -color $groupColor -name "LONG DELAY DONE"     {/acquireToHDMI_tb/uut/sw[1]}
add_wave -into $SW_ID -color $groupColor -name "SHORT DELAY DONE"    {/acquireToHDMI_tb/uut/sw[0]}

set groupColor LIME
set CW_ID [add_wave_group "Control Word"]
add_wave -into $CW_ID -color $groupColor -name "CLEAR STORE FLAG" /acquireToHDMI_tb/uut/cw[21]
add_wave -into $CW_ID -color $groupColor -name "SET STORE FLAG" /acquireToHDMI_tb/uut/cw[20]
add_wave -into $CW_ID -color $groupColor -name "TRIG CH2 WRITE" {/acquireToHDMI_tb/uut/cw[19]}
add_wave -into $CW_ID -color $groupColor -name "TRIG CH1 WRITE" {/acquireToHDMI_tb/uut/cw[18]}
add_wave -into $CW_ID -color $groupColor -name "CONVERSION PLUS READOUT" {/acquireToHDMI_tb/uut/cw[17]}
add_wave -into $CW_ID -color $groupColor -name "SAMPLE TIMER ROLLOVER" {/acquireToHDMI_tb/uut/cw[16]}
add_wave -into $CW_ID -color $groupColor -name "DATA STORAGE CH2 WRITE" {/acquireToHDMI_tb/uut/cw[15]}
add_wave -into $CW_ID -color $groupColor -name "DATA STORAGE CH1 WRITE" {/acquireToHDMI_tb/uut/cw[14]}
add_wave -into $CW_ID -color $groupColor -name "CONVST" {/acquireToHDMI_tb/uut/cw[13]}
add_wave -into $CW_ID -color $groupColor -name "RD" {/acquireToHDMI_tb/uut/cw[12]}
add_wave -into $CW_ID -color $groupColor -name "CS" {/acquireToHDMI_tb/uut/cw[11]}
add_wave -into $CW_ID -color $groupColor -name "RESET AD7606" {/acquireToHDMI_tb/uut/cw[10]}
add_wave -into $CW_ID -color $groupColor -name "DATA STORAGE CNT (9)" {/acquireToHDMI_tb/uut/cw[9]}
add_wave -into $CW_ID -color $groupColor -name "DATA STORAGE CNT (8)" {/acquireToHDMI_tb/uut/cw[8]}
add_wave -into $CW_ID -color $groupColor -name "SAMPLING CNT (7)" {/acquireToHDMI_tb/uut/cw[7]}
add_wave -into $CW_ID -color $groupColor -name "SAMPLING CNT (6)" {/acquireToHDMI_tb/uut/cw[6]}
add_wave -into $CW_ID -color $groupColor -name "RATE SELECT (5)" {/acquireToHDMI_tb/uut/cw[5]}
add_wave -into $CW_ID -color $groupColor -name "RATE SELECT (4)" {/acquireToHDMI_tb/uut/cw[4]}
add_wave -into $CW_ID -color $groupColor -name "LONG DELAY CNT (3)" {/acquireToHDMI_tb/uut/cw[3]}
add_wave -into $CW_ID -color $groupColor -name "LONG DELAY CNT (2)" {/acquireToHDMI_tb/uut/cw[2]}
add_wave -into $CW_ID -color $groupColor -name "SHORT DELAY CNT (1)" {/acquireToHDMI_tb/uut/cw[1]}
add_wave -into $CW_ID -color $groupColor -name "SHORT DELAY CNT (0)" {/acquireToHDMI_tb/uut/cw[0]}

# The handout times assume a 1000-sample screen. With a 700-sample screen the
# BRAM fills at about 5539 us (forced) and 5642 us (trigger) instead.
set FORCED_CHECK01        500ns   
set FORCED_CHECK02      700000ns  
set FORCED_CHECK03    1311500ns   
set FORCED_CHECK04    1340000ns   
set FORCED_CHECK05    2900000ns   
set FORCED_CHECK06    7360000ns   

set FORCED_T01toT02    699500ns
set FORCED_T02toT03    611500ns
set FORCED_T03toT04     28500ns
set FORCED_T04toT05   1560000ns
set FORCED_T05toT06   4460000ns

set TRIGGER_CHECK01        500ns  
set TRIGGER_CHECK02    1311200ns  
set TRIGGER_CHECK03    1413820ns 
set TRIGGER_CHECK04    7455000ns

set TRIGGER_T01toT02   1310700ns
set TRIGGER_T02toT03    102620ns
set TRIGGER_T03toT04   6041180ns
