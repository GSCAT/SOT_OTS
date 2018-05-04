library(dplyr)
library(tidyr)

load(paste(Sys.getenv("USERPROFILE"), "Documents\\SOTC-OTS\\PBI", "Week_7.RData", sep=.Platform$file.sep))
cal <- read.csv(file = paste(Sys.getenv("USERPROFILE"), "Documents\\SOTC-OTS\\PBI", 'fiscal_calendar.csv', sep=.Platform$file.sep))

# SOT Impact for PBI
SOT_Impact <- SOT_Master_FOB %>%
  filter(!grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed= FALSE)) %>% 
  group_by(ReportingBrand, Category, LOC_ABBR_NM, ShipCancelWeek) %>% 
  summarise(
    "Late_Units" = sum(subset(Units,Lateness == "Late"), na.rm = TRUE),
    "OnTime_Units" = sum(subset(Units, Lateness == "OnTime"), na.rm = TRUE),
    "Total_Units" = sum(Units, na.rm = TRUE),
    "Transport_Impact" = sum(subset(Units, `Probable Failure` == "Transportation")),
    "Air_Vendor_Impact" = sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD == "A" )),
    "Vendor_non_Air_Impact" = sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD != "A" ))) %>% 
  right_join(as.data.frame(brand_vec), by = c("ReportingBrand" = "brand_vec")) %>% 
  select(ReportingBrand, Category, LOC_ABBR_NM, `Late_Units`,`OnTime_Units`,`Total_Units`,
         `Transport_Impact`, `Air_Vendor_Impact`, `Vendor_non_Air_Impact`, ShipCancelWeek) %>% 
  gather(Reason, Impacted_Units, c('Transport_Impact', 'Air_Vendor_Impact', 'Vendor_non_Air_Impact'))

#OTS Impact for PBI
OTS_Impact <- OTS_Master_Logistics_Impact %>% 
  group_by(Week, ReportingBrand, Category, LOC_ABBR_NM) %>% 
  summarise("Total_Units" = sum(Units),
            "Late_Units" = sum(subset(Units,Lateness == "Late"), na.rm = TRUE),
            "OnTime_Units" = sum(subset(Units, Lateness == "OnTime"), na.rm = TRUE),
            "Brand RD/Hold" = sum(subset(Units, grepl("Brand", OTS, ignore.case = TRUE) & Lateness == "Late"), na.rm = T),
            "Vendor" = sum(subset(Units, OTS == "Vendor" & Lateness == "Late"), na.rm = T),
            "Int'l Transportation" = sum(subset(Units, OTS == "Origin"& Lateness == "Late"), na.rm = T),
            "Weather" = sum(subset(Units, OTS == "Extreme Weather" & Lateness == "Late"), na.rm = T),
            "Domestic Transportation" = sum(subset(Units, OTS == "Destination" & Lateness == "Late"), na.rm = T),
            "DC Stocking" = sum(subset(Units, OTS == "OT" & Lateness == "Late"), na.rm = T),
            "Other" = sum(subset(Units, OTS %in% c("Other", NA) & Lateness == "Late"), na.rm = T)) %>% 
  right_join(as.data.frame(brand_vec), by = c("ReportingBrand" = "brand_vec")) %>% 
  select(Week, ReportingBrand, Category, LOC_ABBR_NM, `Total_Units`,`Late_Units`, `OnTime_Units`, `Brand RD/Hold`, `Vendor`,`Int'l Transportation`, `Weather`, `Domestic Transportation`, 
         `DC Stocking`, `Other`) %>% 
  gather(Reason, Impacted_Units, c(`Brand RD/Hold`, `Vendor`,`Int'l Transportation`, `Weather`, `Domestic Transportation`, 
                                   `DC Stocking`, `Other`))

save(list = c('OTS_by_Category', 'OTS_by_Vendor',
              'SOT_by_Category', 'SOT_by_Vendor',
              'SOT_Impact', 'OTS_Impact',
              'cal'), 
     file = paste(Sys.getenv("USERPROFILE"), "Documents\\SOTC-OTS\\PBI", "forPBI.rda", sep=.Platform$file.sep))

