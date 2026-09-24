# EENG484

**Aaron Siegle - 9/23 3:30pm**
videoSignalGenerator should be complete. Working on scopeFace. Did a little bit of scopeToHdmi_package. Haven't touched scopeToHdmi.
Need to figure out how to implement scopeToHdmi_package to stop getting errors for not declared variables --> I think we need to finish scopeToHdmi first to fully write those, but H_FP should be done and I'm still getting not declared errors in videoSignalGenerator. 



4for the triangle arithmetic, the previous and statment removes that condition of looking outside of the triangle bounts

You're right that the earlier and bounds pixelHorz, which bounds the distance term. That part is fine — the distance is guaranteed to sit between 0 and 10, no wrap there.

But that's not where the wrap happens. Look at what gets subtracted:

vhdl
pixelVert >= triggerVolt - (distance)

The subtraction is triggerVolt - distance. Bounding pixelHorz constrains distance, but it says nothing about triggerVolt. And triggerVolt is a runtime value the buttons move around — nothing in this expression stops it from being small.

Concretely: press the button enough times to walk triggerVolt down to 5. Distance is 10. Then 5 - 10 under unsigned arithmetic gives 2043, not −5. The condition becomes pixelVert >= 2043, false for every row on screen, and the entire upper half of the triangle disappears.

The reason short-circuiting doesn't save you: VHDL's and with the when/else form doesn't guarantee short-circuit evaluation for signal expressions, and more to the point, this synthesizes to combinational logic where all terms are computed in parallel. There's no sequencing. The subtractor exists in hardware and produces its wrapped result regardless of what the other comparison says.

The fix is the same either way — move the subtraction to the other side so both operands stay non-negative:

vhdl
and (pixelVert + (L_EDGE + BORDER_LINE_WIDTH + 11 - pixelHorz) >= triggerVolt)

Now the only subtraction is L_EDGE + BORDER_LINE_WIDTH + 11 - pixelHorz, which your pixelHorz bound genuinely does protect.

One thing to check while you're there: does triggerVolt ever legitimately get near zero? Its reset value is mid-screen and the buttons step by 10 with no limit checking — the lab explicitly says you don't have to keep it on screen. So yes, a user can walk it to a small value or wrap it past zero. Worth knowing that the triangle will do odd things there by design.


2. Triangle arithmetic will wrap
vhdl
and (pixelVert >= triggerVolt - (L_EDGE + BORDER_LINE_WIDTH + 11 - pixelHorz))

This is the problem I flagged earlier. Everything here is std_logic_vector under std_logic_unsigned, so subtraction wraps instead of going negative.

Concretely: triggerVolt = 20, distance term = 11. You want pixelVert >= 9. You get 20 - 11 fine here — but when triggerVolt is small and the distance is larger, say triggerVolt = 5 with distance 11, 5 - 11 becomes 2042. The comparison then fails for every real row and half the triangle vanishes. It also wraps at the 11-bit boundary.

Fix by moving the subtraction so nothing goes negative — add to both sides:

vhdl
and (pixelVert + (L_EDGE + BORDER_LINE_WIDTH + 11 - pixelHorz) >= triggerVolt)

Same inequality, all operands non-negative. Do the same on the triggerTimeMark line with pixelHorz and triggerTime.

