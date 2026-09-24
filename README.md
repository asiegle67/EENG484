# EENG484

**Aaron Siegle - 9/23 3:30pm**
videoSignalGenerator should be complete. Working on scopeFace. Did a little bit of scopeToHdmi_package. Haven't touched scopeToHdmi.
Need to figure out how to implement scopeToHdmi_package to stop getting errors for not declared variables --> I think we need to finish scopeToHdmi first to fully write those, but H_FP should be done and I'm still getting not declared errors in videoSignalGenerator. 


Not an error — it's a deliberate choice, and H_FP - 1 is the better one.

Both work. The only thing that matters is that v_cnt advances once per line, at a consistent point that isn't inside the active region. Either instant qualifies.

Here's the difference. Your counter order is FP → SYNC → BP → ACTIVE, so h_cnt = H_TOTAL - 1 is the last active pixel of the line. If v_cnt incremented there, the row number would change at the same edge as the final pixel's color decision — and since pixelVert is registered and lags a cycle, you'd be stepping the row boundary right at the point where scopeFace is still resolving the last pixel. Fragile.

h_cnt = H_FP - 1 is the end of the front porch, deep in blanking. Nothing is being drawn. The row advances, pixelVert settles, and by the time h_cnt reaches 370 and active video starts, everything is stable for the entire line. That's why the handout's given code uses it, and why vs and v_activeArea use the same instant — all three vertical events happen together, cleanly inside blanking.

One consequence worth understanding: a "line" in v_cnt terms spans h_cnt 110 → 1649 → 0 → 109, not 0 → 1649. The active pixels (370–1649) sit entirely within one v_cnt value either way, so the picture is correct.

The processes you'd be changing are all given code, unchanged from the handout. Your professor's reference waveforms were produced with H_FP - 1, so matching it also means your screenshots line up with his.

