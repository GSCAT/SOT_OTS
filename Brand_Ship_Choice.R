library(dplyr)
library(readr)
library(xlsx)
library(tidyr)

Ship_Choice_status <- read.csv("Ship_Choice_Status.csv")

Three_PL_ship_Choice <- SOT_Master %>%
  subset(Category == "3P & Lic" & Lateness == "Late" & ShipCancelWeek == EOW) %>% 
  group_by(Category, SHIP_MODE_CD, Trade_Lane_Type, SALES_TERMS_CODE, ShipDateChoice) %>% 
  summarise("Vendor Units" = sum(`Units`)) %>% 
  arrange(desc(`Vendor Units`))

write.xlsx(as.data.frame(Three_PL_ship_Choice), file = paste(SOT_OTS_directory, "Three_PL_Ship Choice.xlsx", sep = .Platform$file.sep), sheetName = "By Ship Choice Matrix")


Three_PL_EOW <- SOT_Master %>%
  subset(Category == "3P & Lic" & Lateness == "Late" & ShipCancelWeek == EOW) 

write.xlsx(as.data.frame(Three_PL_EOW), file = paste(SOT_OTS_directory, "Three_PL_Ship Choice.xlsx", sep = .Platform$file.sep), sheetName = "Late DPOs curr week", append = TRUE)


Brand_ship_Choice <- SOT_Master %>%
  subset(ReportingBrand == "ATHLETA" & Lateness == "Late" & ShipCancelWeek == EOW) %>% 
  group_by(ReportingBrand, SHIP_MODE_CD, Trade_Lane_Type, SALES_TERMS_CODE, ShipDateChoice) %>% 
  summarise("Vendor Units" = sum(`Units`)) %>% 
  arrange(desc(`Vendor Units`))

ship_Choice_Table<- SOT_Master %>%
  group_by(SHIP_MODE_CD, Trade_Lane_Type, SALES_TERMS_CODE, ShipDateChoice) %>% 
  summarise("Vendor Units" = sum(`Units`)) %>% 
  arrange(desc(`Vendor Units`))

First_Choice <- Ship_Choice_status %>% 
  subset(`Ship_Choice_Status` == 1)
# Ship Choice ----
ship_Choice <- SOT_Master %>%
  # subset(Lateness == "Late") %>%
  group_by(ReportingBrand, ShipCancelWeek, SHIP_MODE_CD, Trade_Lane_Type, SALES_TERMS_CODE, ShipDateChoice, SHP_RSN_TYP_DESC, Lateness) %>% 
  summarise("Vendor Units" = sum(`Units`)) %>% 
  right_join(Ship_Choice_status, by = c("SHIP_MODE_CD" = "SHIP_MODE_CD", "Trade_Lane_Type" = "Trade_Lane_Type", "SALES_TERMS_CODE" = "SALES_TERMS_CODE", "ShipDateChoice"="ShipDateChoice")) %>% 
  mutate("Transportation Delay Reason" = ifelse(SHP_RSN_TYP_DESC != "-", "Delay Reason", "")) %>%
  arrange(desc(`Vendor Units`))

Perf_ship_choice <- ship_Choice %>%
  group_by(ShipCancelWeek, Ship_Choice_Status, `Transportation Delay Reason`) %>% 
  summarise("OnTimeUnits"= sum(`Vendor Units`[Lateness=="OnTime"]),
             "LateUnits" = sum(`Vendor Units`[Lateness=="Late"]),
                 "SOT %" = (sum(`Vendor Units`[Lateness=="OnTime"])/ sum(`Vendor Units`))*100,
                  "Units"= sum(`Vendor Units`)) %>%
 # group_by(ShipCancelWeek) %>% 
  #  summarise("SOT % to Grand Total" = (sum(`OnTimeUnits`)/ sum(`Vendor Units`))*100) %>% 
  filter(`Units`>= 10000)
# For January ----
ship_Choice <- SOT_Master %>%
  # subset(Lateness == "OnTime") %>%
  group_by(ReportingBrand, Category, ShipCancelMonth, SHIP_MODE_CD, Trade_Lane_Type, SALES_TERMS_CODE, ShipDateChoice, SHP_RSN_TYP_DESC, Lateness) %>% 
  summarise("Vendor Units" = sum(`Units`)) %>% 
  right_join(Ship_Choice_status, by = c("SHIP_MODE_CD" = "SHIP_MODE_CD", "Trade_Lane_Type" = "Trade_Lane_Type", "SALES_TERMS_CODE" = "SALES_TERMS_CODE", "ShipDateChoice"="ShipDateChoice")) %>%
  mutate("Transportation Delay Reason" = SHP_RSN_TYP_DESC != "-") %>% 
  arrange(desc(`Vendor Units`))

Perf_ship_choice <- ship_Choice %>%
  group_by(ReportingBrand, Category, ShipCancelMonth) %>% 
  summarise("OnTimeUnits"= sum(`Vendor Units`[Lateness=="OnTime"]),
             "LateUnits" = sum(`Vendor Units`[Lateness=="Late"]),
                 "SOT %" = (sum(`Vendor Units`[Lateness=="OnTime"])/ sum(`Vendor Units`))*100,
                  "Units"= sum(`Vendor Units`),
            "Unit late Trans Delay" = sum(`Vendor Units`[`Transportation Delay Reason` == TRUE & Lateness == "Late"], na.rm = TRUE)) %>%
 # group_by(ShipCancelWeek) %>% 
  #  summarise("SOT % to Grand Total" = (sum(`OnTimeUnits`)/ sum(`Vendor Units`))*100) %>% 
  filter(`Units`>= 10000)

write.xlsx(as.data.frame(Perf_ship_choice), file = paste(SOT_OTS_directory, "Ship_Choice2.xlsx", sep = .Platform$file.sep), sheetName = "By brand Category")
# ship_Choice <- SOT_Master %>%
#   subset(Lateness == "Late") %>% 
#   group_by(SHIP_MODE_CD, Trade_Lane_Type, SALES_TERMS_CODE, ShipDateChoice) %>% 
#   summarise("Vendor Units" = sum(`Units`)) %>% 
#   arrange(desc(`Vendor Units`))



Brand_EOW <- SOT_Master %>%
  subset(ReportingBrand == "ATHLETA" & Lateness == "Late" & ShipCancelWeek == EOW)


write.xlsx(as.data.frame(Brand_ship_Choice), file = paste(SOT_OTS_directory, "Athleta Choice.xlsx", sep = .Platform$file.sep), sheetName = "By Ship Choice Matrix")
write.xlsx(as.data.frame(Brand_EOW), file = paste(SOT_OTS_directory, "Athleta Choice.xlsx", sep = .Platform$file.sep), sheetName = "Late DPOs curr week", append = TRUE)
