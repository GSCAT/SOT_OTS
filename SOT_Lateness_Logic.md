SOT Lateness Reason Logic Documentation
================

# Determine Lateness

*Metric Ship Date - Contract Ship Date > 2*

Units are late if the actual ship date (metric ship date) is more than 2 days after the contract ship date. 

# Determine Late Reasons

For units that are late, we use different logics based on different terms and ship modes to determine root causes. 

### FOB and Ocean

-   *Ship Cancel Date <= Contract Ship Cancel Date +6 ==>[Transportation]*
-   *Ship Cancel Date >= Contract Ship Cancel Date +7 ==>[Vendor]*
-   *Actual OC Date > Planned OC Date ==>[Vendor]*
-   *Actual OC Date < Planned OC Date ==>[Transportation]*

When vendors have a delay, they are required to request an extension to move the ship cancel date to a later date, typically in increments of one week. We have aligned with GIS to categorize lateness with ship cancel dates equal to or more than 7 days after the contract ship cancel date as vendor delays. 

### FCA and Ocean, FOB and Air, CFR and Air

-   *Actual OC Date >= Contract Ship Cancel Date +2 ==>[Vendor]*

Under the above terms and ship modes, OC is the first choice to measure Contract Ship Cancel Date for SOT performance. As such, we categorize latenss with actual OC date eqaul to or more than 2 days after the contract ship cancel date as vendor delays.

### EXW, DDP, DDU

For all lateness under EXW, DDP or DDU term, we attribute lateness to vendor delays. 





