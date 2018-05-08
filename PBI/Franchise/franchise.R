# Scrub Noise from Master Objects and Select Frnchise Only ----
OTS_Master <- OTS_Master %>% 
  filter(grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed=FALSE)) %>%
  filter(Week <= EOW,
         PLANNED_STOCKED_DATE >= "2018-02-04",
         !is.na(DC_NAME),
         !grepl("Liberty Distribution Company", Parent_Vendor, ignore.case = TRUE),
         !grepl("dummy", Parent_Vendor, ignore.case = TRUE),
         !grepl("JPF", DC_NAME, ignore.case = TRUE)) %>% 
  droplevels()

SOT_Data_Pulled <- SOT_Master$Data_Pulled[1]
SOT_Master <- SOT_Master %>% 
  filter(grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed=FALSE)) %>%
  filter(ShipCancelWeek <= EOW,
         FISCAL_YEAR == fis_yr,
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

SOT_by_Category <- SOT_Master %>%
  group_by(ReportingBrand, Category, ShipCancelMonth, ShipCancelWeek) %>%
  summarise(TotalUnits= sum(Units), 
            OnTimeUnits = sum(Units[Lateness=="OnTime"]), 
            LateUnits = sum(Units[Lateness=="Late"]), 
            WtDaysLate = sum(Units[Lateness=="Late"] * DAYS_LATE[Lateness=="Late"]),
            DaysLate5 = sum(Units[DAYS_LATE>5], na.rm = TRUE),
            UnitsArriveLessThanNeg5 = sum(Units[Lateness=="OnTime" & DAYS_LATE <= -5]),
            UnitsArriveLessThanNeg3 = sum(Units[Lateness=="OnTime" & DAYS_LATE <= -2]),
            UnitsArriveLessThan0 = sum(Units[Lateness=="OnTime" & DAYS_LATE <= 0]),
            UnitsArriveLessThan3 = sum(Units[(Lateness=="OnTime" | Lateness == "Late") & DAYS_LATE <= 2]),
            UnitsArriveLessThan5 = sum(Units[(Lateness=="OnTime" | Lateness == "Late") & DAYS_LATE <= 5])) %>% 
  droplevels()

OTS_by_Category <- OTS_Master %>%
  group_by(ReportingBrand, Category, Month_Number,Week, DC_NAME) %>%
  summarise(TotalUnits= sum(Units), 
            OnTimeUnits = sum(Units[Lateness=="OnTime"], na.rm = T), 
            LateUnits = sum(Units[Lateness=="Late"]), 
            WtDaysLate = sum(Units[Lateness=="Late"] * Days_Late[Lateness=="Late"]),
            DaysLate5 = sum(Units[Days_Late > 5 & Lateness=="Late"]),
            UnitsArriveLessThanNeg5 = sum(Units[(Lateness=="OnTime" | Lateness == "Late") & (Days_Late <= -5)]),
            UnitsArriveLessThanNeg3 = sum(Units[(Lateness=="OnTime" | Lateness == "Late") & (Days_Late <= -3)]),
            UnitsArriveLessThan0 = sum(Units[(Lateness=="OnTime" | Lateness == "Late") & (Days_Late <= 0)]),
            UnitsArriveLessThan3 = sum(Units[(Lateness=="OnTime" | Lateness == "Late") & (Days_Late <= 3)]),
            UnitsArriveLessThan5 = sum(Units[(Lateness=="OnTime" | Lateness == "Late") & (Days_Late <= 5)])) %>% 
  droplevels()

save(list = c('OTS_by_Category', 
              'SOT_by_Category'), 
     file = paste(Sys.getenv("USERPROFILE"), "Documents\\SOTC-OTS\\PBI", "FranchisePBI.rda", sep=.Platform$file.sep))
