library(dplyr)
library(tidyr)
library(mosaic)

load("C:\\Users\\wenlu\\Documents\\SOTC-OTS\\Week 2\\SOT_Master_object.rtf")
load("C:\\Users\\wenlu\\Documents\\SOTC-OTS\\Week 2\\OTS_Master_object.rtf")
SOT_Data_Pulled <- SOT_Master$Data_Pulled[1]

# Scrub Noise from Master Objects ----
OTS_Master <- OTS_Master %>% 
  filter(!grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed=FALSE)) %>% 
  filter(PLANNED_STOCKED_DATE >= '2017-02-12' & PLANNED_STOCKED_DATE <= '2018-02-17',
    !is.na(DC_NAME),
    !grepl("Liberty Distribution Company", Parent_Vendor, ignore.case = TRUE),
    !grepl("dummy", Parent_Vendor, ignore.case = TRUE),
    !grepl("JPF", DC_NAME, ignore.case = TRUE)) %>% 
  mutate(Year = ifelse(PLANNED_STOCKED_DATE <= '2018-02-03', '17', '18')) %>% 
  droplevels()

SOT_Master <- SOT_Master %>% 
  filter(!grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed=FALSE)) %>%
  filter(SHIP_CANCEL_DATE >= '2017-02-12' & SHIP_CANCEL_DATE <= '2018-02-17',
         !grepl("Liberty Distribution Company", Parent_Vendor, ignore.case = TRUE),
         !grepl("dummy", Parent_Vendor, ignore.case = TRUE),
         MetricShipDate <= SOT_Data_Pulled) %>% 
  droplevels()

########## FIX UNITS in OTS_MASTER #############
OTS_Master <- OTS_Master %>% 
  group_by(`DEST_PO_ID` ) %>% 
  mutate("Old Units" = Units) %>% 
  mutate("Rem_Units" = 
           ifelse(test = Lateness == "Late", 
                  (sum(Units, na.rm = T) - sum(ACTL_STK_QTY, na.rm = T))/count(Lateness == "Late"),
                  0)) %>% 
  mutate(`ACTL_STK_QTY` = ifelse(is.na(ACTL_STK_QTY), 0, ACTL_STK_QTY)) %>% 
  mutate("Rem_Units" = ifelse(test = `Rem_Units` > 0, `Rem_Units`, 0)) %>% 
  mutate("Units" = floor(ifelse(Lateness == "OnTime", ACTL_STK_QTY, 
                                (ACTL_STK_QTY + `Rem_Units` + 0)))) %>% 
  arrange(desc(DEST_PO_ID))

# SOT by brand weekly trend  
SOT_viz_by_brand <- SOT_Master %>%
  group_by(ReportingBrand, FISCAL_YEAR, ShipCancelWeek) %>%
  summarise(TotalUnits= sum(Units), 
            OnTime = sum(Units[Lateness=="OnTime"]), 
            Late = sum(Units[Lateness=="Late"])) %>% 
  ungroup() %>% 
  mutate(Wk = ifelse(ShipCancelWeek<10, paste0("0",ShipCancelWeek), ShipCancelWeek),
         SOT = round(OnTime/TotalUnits,4)*100,
         YearWk = paste(FISCAL_YEAR-2000,"-",Wk)) %>% 
  droplevels() %>% 
  arrange(ReportingBrand, YearWk)

SOT_GapInc <- SOT_Master %>% 
  group_by(FISCAL_YEAR, ShipCancelWeek) %>%
  summarise(TotalUnits= sum(Units), 
            OnTime = sum(Units[Lateness=="OnTime"]), 
            Late = sum(Units[Lateness=="Late"])) %>% 
  ungroup() %>% 
  mutate(Wk = ifelse(ShipCancelWeek<10, paste0("0",ShipCancelWeek), ShipCancelWeek),
         SOT = round(OnTime/TotalUnits,4)*100,
         YearWk = paste(FISCAL_YEAR-2000,"-",Wk)) %>% 
  droplevels() %>% 
  arrange(YearWk)

SOT <- split(SOT_viz_by_brand, f = SOT_viz_by_brand$ReportingBrand)

# OTS by brand weekly trend  
OTS_viz_by_brand <- OTS_Master %>%
  group_by(ReportingBrand, Year, Week) %>%
  summarise(TotalUnits= sum(Units), 
            OnTime = sum(Units[Lateness=="OnTime"], na.rm = T), 
            Late = sum(Units[Lateness=="Late"])) %>% 
  ungroup() %>% 
  mutate(Wk = ifelse(Week < 10, paste0("0",Week), Week),
         OTS = round(OnTime/TotalUnits,4)*100,
         YearWk = paste(Year,"-",Wk)) %>%
  droplevels()

OTS_GapInc <- OTS_Master %>%
  group_by(Year,Week) %>%
  summarise(TotalUnits= sum(Units), 
            OnTime = sum(Units[Lateness=="OnTime"], na.rm = T), 
            Late = sum(Units[Lateness=="Late"])) %>% 
  ungroup() %>% 
  mutate(OTS = round(OnTime/TotalUnits,4)*100,
         Wk = ifelse(Week < 10, paste0("0",Week), Week),
         YearWk = paste(Year,"-",Wk)) %>%
  droplevels()

OTS <- split(OTS_viz_by_brand, f = OTS_viz_by_brand$ReportingBrand)

save.image('.RData')

