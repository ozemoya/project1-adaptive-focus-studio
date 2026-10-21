# Session Scout evaluation log

Session Scout uses the three most recent completed sessions with the selected mood. It rejects completed durations outside 1–180 minutes, takes the median, then limits the suggestion to 10–60 minutes. The fixed baseline is 25 minutes. The user can apply the suggestion or ignore it.

| Case | Inputs | Expected | Test result |
| --- | --- | --- | --- |
| Normal | 20, 25, 30 minutes, plus an older matching row and another mood | 25 minutes from the three recent matches | Pass |
| Insufficient data | Two matching rows | No suggestion | Pass |
| Invalid data | 0, -2, and 181 minutes mixed with two valid rows | Invalid rows excluded; no suggestion | Pass |
| Boundary and outlier | 2, 100, 180 minutes | Median 100, limited to 60 | Pass |
| Short-session counterexample | 1, 2, 3 minutes | Median 2, raised to 10 | Pass |

These are controlled test fixtures, not peer outcomes or real-world accuracy evidence. The short-session case shows a limitation: 10 minutes may still be too long for that user. The in-app explanation displays the three values, the fixed baseline, and Apply/Not now controls so the user retains the decision.

For a later evaluation, record a new completed session after each valid suggestion. Compare the absolute difference between its actual completed minutes and (a) Session Scout's suggestion and (b) the fixed 25-minute baseline. Record the number of examples and do not generalize from a small sample. No later-session prediction dataset has been collected yet.
