# EENG484

**Aaron Siegle - 9/23 3:30pm**
videoSignalGenerator should be complete. Working on scopeFace. Did a little bit of scopeToHdmi_package. Haven't touched scopeToHdmi.
Need to figure out how to implement scopeToHdmi_package to stop getting errors for not declared variables --> I think we need to finish scopeToHdmi first to fully write those, but H_FP should be done and I'm still getting not declared errors in videoSignalGenerator. 




Syntax error — scopeToHdmi.vhdl, trigger process

The indentation hides it, but the if/elsif chain is malformed:

vhdl
if resetn = '0' then
triggerVolt <= ...;
triggerTime <= ...;
    elsif (activeButton(1) = '1') ...

You have a nested if opening after the reset assignments that never gets closed, so the end if; end if; at the bottom doesn't balance. Vivado will point at end process or later.

The structure should be flat — reset branch, then the two button branches as elsif at the same level:

vhdl
if rising_edge(sysClk) then
    if resetn = '0' then
        triggerVolt <= ...;
        triggerTime <= ...;
    elsif (activeButton(1) = '1') and (currButton(1) = '1') then
        ...
    elsif (activeButton(2) = '1') and (currButton(2) = '1') then
        ...
    end if;
end if;

Count the end if; — you need exactly two (inner chain, then rising_edge).

Logic bug — button bounce
vhdl
prevButton <= currButton;
currButton <= btn;

This samples every clock at 50 MHz. A mechanical switch bounces for several milliseconds, so one press produces dozens of transitions, each one a "release," each one moving the trigger by 10. In practice your trigger will jump by 200–500 pixels per press.

Fix: only update on a slow tick. Add a counter and gate both assignments:

vhdl
if sampleCnt = SAMPLE_MAX then
    sampleCnt <= 0;
    prevButton <= currButton;
    currButton <= btn;
else
    sampleCnt <= sampleCnt + 1;
end if;

At 50 MHz, SAMPLE_MAX around 500,000 gives 10 ms — well past bounce, fast enough to feel instant.

One consequence: with slow sampling, activeButton stays high for the whole 10 ms window, so the trigger process fires 500,000 times. You need it as a single-cycle pulse. Easiest fix is to register it inside the same process — set it to currButton xor btn on the sample tick, and "000" otherwise — rather than leaving it as a concurrent assignment.

Minor
Swapped comments on drawCh1/drawCh2 in scopeFace (ch1 is the yellow diagonal).
V_DIV_PIXELS := 70 is hardcoded while H_DIV_PIXELS is derived — make it HEIGHT_N / NUM_DIVISIONS for consistency. Same for the two hatch constants.

Everything else — videoSignalGenerator, the package, scopeFace geometry, the port maps, the hdmi_tx_0 name fix — looks right.

