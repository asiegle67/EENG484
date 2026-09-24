# EENG484

**Aaron Siegle - 9/23 3:30pm**
videoSignalGenerator should be complete. Working on scopeFace. Did a little bit of scopeToHdmi_package. Haven't touched scopeToHdmi.
Need to figure out how to implement scopeToHdmi_package to stop getting errors for not declared variables --> I think we need to finish scopeToHdmi first to fully write those, but H_FP should be done and I'm still getting not declared errors in videoSignalGenerator. 

Claude’s syntax-error claim is wrong. Your trigger process is already a valid flat structure:

if rising_edge(sysClk) then
    if resetn = '0' then
        ...
    elsif key3_release then
        if key2_held then
            ...
        else
            ...
        end if;
    elsif key4_release then
        if key2_held then
            ...
        else
            ...
        end if;
    end if;
end if;

You have exactly two outer end if; statements: one closes the reset/key chain; one closes rising_edge. The two additional ones close the small “Key2 held?” tests.

The button-bounce warning is physically valid, but it is not a syntax or simulation problem. Your current code matches the lab’s requested current/previous/XOR change-detection approach. I would not add debounce logic yet—it makes the design and testbench more complicated. Simulate first; if the real buttons later move the trigger multiple times per press, add a debouncer then.

Claude’s minor cleanup notes are right:

constant V_DIV_PIXELS : NATURAL := HEIGHT_N / NUM_DIVISIONS;

And keep the hatch setup internally consistent with four marks:

constant HATCH_PER_DIV : NATURAL := 4;
constant H_HATCH_PIXELS : NATURAL := H_DIV_PIXELS / (HATCH_PER_DIV + 1);
constant V_HATCH_PIXELS : NATURAL := V_DIV_PIXELS / (HATCH_PER_DIV + 1);
