library(dplyr)
library(readr)
library(RODBC)
library(formattable)
library(rChoiceDialogs)
library(ggvis)
library(readxl)
library(xlsx)
library(plotly)
library(tidyr)
library(mosaic)

# Setup Environment Variables/Functions ----
prompt_for_week <- function()
{ 
  n <- readline(prompt="Enter Week number: ")
  return(as.integer(n))
}

prompt_for_year <- function()
{ 
  n <- readline(prompt="Enter Fiscal Year as YYYY: ")
  return(as.integer(n))
}

choose_file_directory <- function()
{
  v <- jchoose.dir()
  return(v)
}

SOT_OTS_directory <- choose_file_directory()

EOW <- prompt_for_week()
fis_yr <- prompt_for_year()


my_uid <- read_lines("C:\\Users\\Ke2l8b1\\Documents\\my_uid.txt")
my_pwd <- read_lines("C:\\Users\\Ke2l8b1\\Documents\\my_pwd.txt")

# Create RODBC connection ----
my_connect <- odbcConnect(dsn= "IP EDWP", uid= my_uid, pwd= my_pwd)
# sqlTables(my_connect, catalog = "EDWP", tableName  = "tables")
sqlQuery(my_connect, query = "SELECT  * from dbc.dbcinfo;")

SOT_Master <- sqlQuery(my_connect, 
                       query = "SELECT * from SRAA_SAND.VIEW_SOT_MASTER_FIS_2016
                       where (ShipCancelMonth = 12 and FISCAL_YEAR = 2016) or (ShipCancelMonth = 1 and  FISCAL_YEAR= 2017);")
close(my_connect)

save(SOT_Master, file = paste(SOT_OTS_directory,  'SOT_Master_object.rtf', sep = .Platform$file.sep))

# For Week 4 ----
load(file = paste(SOT_OTS_directory,  'SOT_Master_object.rtf', sep = .Platform$file.sep ))
SOT_Master <- SOT_Master %>% 
  filter(SOT_Master$ShipCancelWeek <= EOW,
         SOT_Master$FISCAL_YEAR == fis_yr,
         !grepl("Liberty Distribution Company", Parent_Vendor, ignore.case = TRUE),
         !grepl("dummy", Parent_Vendor, ignore.case = TRUE),
         MetricShipDate <= SOT_Data_Pulled) 

# load(file = paste(SOT_OTS_directory,  'SOT_Master.rda', sep = .Platform$file.sep)) ----
# load(file = paste(SOT_OTS_directory,  'OTS_Master_object.rtf', sep = .Platform$file.sep ))

# SOT_Master <- SOT_Master %>% 
#   filter(SOT_Master$ShipCancelWeek <= EOW,
#          SOT_Master$FISCAL_YEAR == fis_yr,
#          !grepl("Liberty Distribution Company", Parent_Vendor, ignore.case = TRUE),
#          !grepl("dummy", Parent_Vendor, ignore.case = TRUE),
#          MetricShipDate <= SOT_Data_Pulled) 
# 
# SOT_Master_Unmeasured <- SOT_Master %>% 
#   filter(SOT_Master$ShipCancelWeek <= EOW,
#          SOT_Master$FISCAL_YEAR == fis_yr,
#          !grepl("Liberty Distribution Company", Parent_Vendor, ignore.case = TRUE),
#          !grepl("dummy", Parent_Vendor, ignore.case = TRUE),
#          Lateness == "Unmeasured") 

# Import TTP table ----
TTP_table <- read.xlsx(file= "TTP.xlsx", sheetName = "Sheet1")

# # Join and mutate SOT_Master with TTP table ----
# SOT_Master_FOB <- SOT_Master %>% 
#   subset(SALES_TERMS_CODE == "FOB" & 
#            SHIP_MODE_CD == "O" & 
#            DAYS_LATE >= (-45) & 
#            DAYS_LATE <= 45 & 
#            !is.na(ACTUAL_ORIGIN_CONSOL_LCL_DATE) &
#             Lateness == "Late") %>% 
#   droplevels() %>% 
#   left_join(TTP_table, by = c("XFR_Point_Place" = "TP.Place", "DC_GEO_LOC" = "Geo.Description")) %>% 
#   mutate("Planned OC (Derived)" = Contract_Ship_Cancel - Days.Before.Ship.Cancel,
#          "Days Late to OC" = ACTUAL_ORIGIN_CONSOL_LCL_DATE -`Planned OC (Derived)`,
#          "Days Anticipated vs Contract" = SHIP_CANCEL_DATE - Contract_Ship_Cancel,
#          "LP vs Anticipated" = ACTUAL_LP_LCL_DATE - SHIP_CANCEL_DATE,
#          "Probable Failure" = derivedVariable("Transportation" = (`Days Anticipated vs Contract` >= 1 & `Days Anticipated vs Contract` <= 6),
#                                               "Vendor" =( `Days Anticipated vs Contract` >= 7),
#                                               "Trans" = `LP vs Anticipated` >= 2,
#                                             .method = "first"),
#          "Test by OC" = derivedVariable("Vendor" = (DAYS_LATE < `Days Late to OC`),
#                                         "Trans" = (DAYS_LATE > `Days Late to OC`),
#                                         "Vendor" = (DAYS_LATE - `Days Late to OC`) == 0,
#                                         .method = "first")
#          )
# 
# # Subset of SOT_Master_FOB v1 ----
# SOT_Master_FOB <- SOT_Master %>% 
#   subset(SALES_TERMS_CODE == "FOB" & 
#            SHIP_MODE_CD == "O" & 
#            DAYS_LATE >= (-45) & 
#            DAYS_LATE <= 45 & 
#            !is.na(ACTUAL_ORIGIN_CONSOL_LCL_DATE) &
#             Lateness == "Late") %>% 
#   droplevels() %>% 
#   left_join(TTP_table, by = c("XFR_Point_Place" = "TP.Place", "DC_GEO_LOC" = "Geo.Description")) %>% 
#   mutate("Planned OC (Derived)" = Contract_Ship_Cancel - Days.Before.Ship.Cancel,
#          "Days Late to OC" = ACTUAL_ORIGIN_CONSOL_LCL_DATE -`Planned OC (Derived)`,
#          "Days Anticipated vs Contract" = SHIP_CANCEL_DATE - Contract_Ship_Cancel,
#          "LP vs Anticipated" = ACTUAL_LP_LCL_DATE - SHIP_CANCEL_DATE,
#          "Probable Failure" = derivedVariable("Trans" = (((Contract_Ship_Cancel + 1) < SHIP_CANCEL_DATE) & (SHIP_CANCEL_DATE < (Contract_Ship_Cancel + 6))),
#                                               "Vendor" =(SHIP_CANCEL_DATE >= (Contract_Ship_Cancel + 6)),
#                                               "Trans" = ACTUAL_LP_LCL_DATE > SHIP_CANCEL_DATE,
#                                             .method = "first"),
#          "Test by OC" = derivedVariable("Vendor" = (DAYS_LATE < `Days Late to OC`),
#                                         "Trans" = (DAYS_LATE > `Days Late to OC`),
#                                         "Vendor" = (DAYS_LATE - `Days Late to OC`) == 0,
#                                         .method = "first")
#          )

# Subset of SOT_Master_FOB v2 ----
SOT_Master_FOB <- SOT_Master %>% 
   # subset(
  #   # SALES_TERMS_CODE == "FOB" & 
  #          # SHIP_MODE_CD == "O" & 
  #          DAYS_LATE >= (-45) & 
  #          DAYS_LATE <= 45) %>%  
   #         !is.na(ACTUAL_ORIGIN_CONSOL_LCL_DATE)) %>% 
  #           # Lateness == "Late") %>% 
  droplevels() %>% 
  left_join(TTP_table, by = c("XFR_Point_Place" = "TP.Place", "DC_GEO_LOC" = "Geo.Description")) %>% 
  mutate("Planned OC (Derived)" = Contract_Ship_Cancel - Days.Before.Ship.Cancel,
         "Days Late to OC" = ACTUAL_ORIGIN_CONSOL_LCL_DATE -`Planned OC (Derived)`,
         "Days Anticipated vs Contract" = SHIP_CANCEL_DATE - Contract_Ship_Cancel,
         "LP vs Anticipated" = ACTUAL_LP_LCL_DATE - SHIP_CANCEL_DATE,
         "Probable Failure" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "FOB" & SHIP_MODE_CD == "O", 
                                      derivedVariable("Transportation" = (( SHIP_CANCEL_DATE > (Contract_Ship_Cancel)) & (SHIP_CANCEL_DATE <= (Contract_Ship_Cancel + 6))),
                                              "Vendor" =(ACTUAL_LP_LCL_DATE > (Contract_Ship_Cancel + 2) & (SHIP_CANCEL_DATE >= (Contract_Ship_Cancel + 7))),
                                              # "Transportation" = (ACTUAL_LP_LCL_DATE > (Contract_Ship_Cancel + 2) & ( SHIP_CANCEL_DATE <= (Contract_Ship_Cancel))),
                                              "Vendor" = (`ACTUAL_ORIGIN_CONSOL_LCL_DATE` > `Planned OC (Derived)`),
                                              "Transportation" = (`ACTUAL_ORIGIN_CONSOL_LCL_DATE` <= `Planned OC (Derived)`),
                                              #"Trans" = (ACTUAL_LP_LCL_DATE + 2) > SHIP_CANCEL_DATE,
                                              .default = "NA",
                                            .method = "first"), "Not Tested"),
         "Sub Reason" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "FOB" & SHIP_MODE_CD == "O", 
                                     derivedVariable("Test1" = (( SHIP_CANCEL_DATE > (Contract_Ship_Cancel)) & (SHIP_CANCEL_DATE <= (Contract_Ship_Cancel + 6))),
                                                     "Test2" =(ACTUAL_LP_LCL_DATE > (Contract_Ship_Cancel + 2) & (SHIP_CANCEL_DATE >= (Contract_Ship_Cancel + 7))),
                                                     #"Test2b" =(ACTUAL_LP_LCL_DATE > (Contract_Ship_Cancel + 2) & ( SHIP_CANCEL_DATE <= (Contract_Ship_Cancel))),
                                                     "Test3" = (`ACTUAL_ORIGIN_CONSOL_LCL_DATE` > `Planned OC (Derived)`),
                                                     "Test3" = (`ACTUAL_ORIGIN_CONSOL_LCL_DATE` <= `Planned OC (Derived)`),
                                                     # "Trans" = (ACTUAL_LP_LCL_DATE + 2) > SHIP_CANCEL_DATE,
                                                     .default = "NA",
                                                     .method = "first"), "Not Tested"),
         "Test by OC" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "FOB" & SHIP_MODE_CD == "O" & !is.na(ACTUAL_ORIGIN_CONSOL_LCL_DATE), 
                                derivedVariable("Vendor" = (`ACTUAL_ORIGIN_CONSOL_LCL_DATE` > `Planned OC (Derived)`),
                                        "Trans" = (`ACTUAL_ORIGIN_CONSOL_LCL_DATE` > `Planned OC (Derived)` & (DAYS_LATE >= `Days Late to OC`)),
                                        "Trans" = ((`ACTUAL_ORIGIN_CONSOL_LCL_DATE` <= `Planned OC (Derived)`) & (DAYS_LATE > `Days Late to OC`)),
                                        "Vendor" = (DAYS_LATE - `Days Late to OC`) == 0,
                                        .default = "NA",
                                        .method = "first"), "Not Tested"),
         "Match?" = `Probable Failure` == `Test by OC`
         ) %>% 
  mutate("Probable Failure" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "FCA" & SHIP_MODE_CD == "O" & ACTUAL_ORIGIN_CONSOL_LCL_DATE > (Contract_Ship_Cancel +2), "Vendor", `Probable Failure`)) %>% 
  mutate("Probable Failure" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "FOB" & SHIP_MODE_CD == "A" & ACTUAL_ORIGIN_CONSOL_LCL_DATE > (Contract_Ship_Cancel +2), "Vendor", `Probable Failure`)) %>% 
  mutate("Probable Failure" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "CFR" & SHIP_MODE_CD == "A" & ACTUAL_ORIGIN_CONSOL_LCL_DATE > (Contract_Ship_Cancel +2), "Vendor", `Probable Failure`)) %>% 
  mutate("Probable Failure" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "EXW", "Vendor", `Probable Failure`)) %>% 
  mutate("Probable Failure" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "DDP"& ShipDateChoice == "DCON", "Vendor", `Probable Failure`)) %>% 
  mutate("Probable Failure" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "DDU" & ShipDateChoice == "OC", "Vendor", `Probable Failure`)) %>% 
  
  mutate("Sub Reason" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "FCA" & SHIP_MODE_CD == "O" & ACTUAL_ORIGIN_CONSOL_LCL_DATE > (Contract_Ship_Cancel +2), "FCA Ocean", `Sub Reason`)) %>% 
  mutate("Sub Reason" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "FOB" & SHIP_MODE_CD == "A" & ACTUAL_ORIGIN_CONSOL_LCL_DATE > (Contract_Ship_Cancel +2), "FOB AIR", `Sub Reason`)) %>% 
  mutate("Sub Reason" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "CFR" & SHIP_MODE_CD == "A" & ACTUAL_ORIGIN_CONSOL_LCL_DATE > (Contract_Ship_Cancel +2), "CFR AIR", `Sub Reason`)) %>% 
  mutate("Sub Reason" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "EXW", "EXW", `Sub Reason`)) %>% 
  mutate("Sub Reason" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "DDP" & ShipDateChoice == "DCON", "DDP DCON", `Sub Reason`)) %>% 
  mutate("Sub Reason" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "DDU" & ShipDateChoice == "OC", "DDU OC", `Sub Reason`)) %>% 
  
  mutate("Test by OC" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "FCA" & SHIP_MODE_CD == "O" & ACTUAL_ORIGIN_CONSOL_LCL_DATE > (Contract_Ship_Cancel +2), "Vendor", `Test by OC`)) %>% 
  mutate("Test by OC" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "FOB" & SHIP_MODE_CD == "A" & ACTUAL_ORIGIN_CONSOL_LCL_DATE > (Contract_Ship_Cancel +2), "Vendor", `Test by OC`)) %>% 
  mutate("Test by OC" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "CFR" & SHIP_MODE_CD == "A" & ACTUAL_ORIGIN_CONSOL_LCL_DATE > (Contract_Ship_Cancel +2), "Vendor", `Test by OC`)) %>% 
  mutate("Test by OC" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "EXW", "Vendor", `Test by OC`)) %>% 
  mutate("Test by OC" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "DDP"& ShipDateChoice == "DCON", "Vendor", `Test by OC`)) %>% 
  mutate("Test by OC" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "DDU" & ShipDateChoice == "OC", "Vendor", `Test by OC`))
  
SOT_Master_FOB$`Probable Failure` <- as.factor(SOT_Master_FOB$`Probable Failure`)
SOT_Master_FOB$`Test by OC` <- as.factor(SOT_Master_FOB$`Test by OC`)
SOT_Master_FOB$XFR_Point_Place <- as.factor(SOT_Master_FOB$XFR_Point_Place)
SOT_Master_FOB$`Sub Reason` <- as.factor(SOT_Master_FOB$`Sub Reason`)

brand_vec <- c("GAP NA", "BR NA", "ON NA", "GO NA", "BRFS NA", "GAP INTL", "BR INTL", "ON INTL", "GO INTL", "ATHLETA")

Trans_output <- SOT_Master_FOB %>%
  filter(ShipCancelWeek >= 1 & ShipCancelWeek <= 4,  !grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed= FALSE)) %>% 
  group_by(ReportingBrand) %>% 
  summarise("SOT %" = (sum(subset(Units, Lateness == "OnTime"), na.rm = TRUE))/sum(subset(Units, Lateness != "Unmeasured")),
    "Transport_Impact" = (sum(subset(Units, `Probable Failure` == "Transportation")))/sum(subset(Units, Lateness != "Unmeasured")),
    "Air_Vendor_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD == "A" )))/sum(subset(Units, Lateness != "Unmeasured"))) %>% 
  right_join(as.data.frame(brand_vec), by = c("ReportingBrand" = "brand_vec")) %>% 
  mutate("SOT Variance from Target" = `SOT %` -.95) %>% 
  select(ReportingBrand, `SOT %`, `SOT Variance from Target`, `Transport_Impact`, `Air_Vendor_Impact`)

cat_vec <- c("Wovens", "Knits", "Denim and Woven Bottoms", "Sweaters", "IP", "Accessories", "Category Other", "3P & Lic")

Trans_output_Category <- SOT_Master_FOB %>%
  filter(ShipCancelWeek >= 1 & ShipCancelWeek <= 4, !grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed= FALSE)) %>% 
  group_by(Category) %>% 
  summarise("SOT %" = (sum(subset(Units, Lateness == "OnTime"), na.rm = TRUE))/sum(subset(Units, Lateness != "Unmeasured")),
            "Transport_Impact" = (sum(subset(Units, `Probable Failure` == "Transportation" )))/sum(subset(Units, Lateness != "Unmeasured")), 
    "Air_Vendor_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD == "A" )))/sum(subset(Units, Lateness != "Unmeasured"))) %>% 
  right_join(as.data.frame(cat_vec), by = c("Category" = "cat_vec")) %>% 
  mutate("SOT Variance from Target" = `SOT %` -.95) %>% 
  select(Category, `SOT %`, `SOT Variance from Target`, `Transport_Impact`, `Air_Vendor_Impact`)

Trans_output_GapInc <- SOT_Master_FOB %>%
  filter(ShipCancelWeek >= 1 & ShipCancelWeek <= 4, !grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed= FALSE)) %>% 
  # group_by(ReportingBrand) %>% 
  summarise("SOT %" = (sum(subset(Units, Lateness == "OnTime"), na.rm = TRUE))/sum(subset(Units, Lateness != "Unmeasured")),
            "Transport_Impact" = (sum(subset(Units, `Probable Failure` == "Transportation" )))/sum(subset(Units, Lateness != "Unmeasured")),
    "Air_Vendor_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD == "A" )))/sum(subset(Units, Lateness != "Unmeasured"))) %>% 
  # right_join(as.data.frame(brand_vec), by = c("ReportingBrand" = "brand_vec")) %>% 
  mutate("SOT Variance from Target" = `SOT %` -.95) %>% 
  select(`SOT %`, `SOT Variance from Target`, `Transport_Impact`, `Air_Vendor_Impact`)


Trans_output_YTD <- SOT_Master_FOB %>%
  filter(ShipCancelWeek >= 1 & ShipCancelWeek <= 5, !grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed= FALSE)) %>% 
  group_by(ReportingBrand) %>% 
  summarise("SOT %" = (sum(subset(Units, Lateness == "OnTime"), na.rm = TRUE))/sum(subset(Units, Lateness != "Unmeasured")),
            "Transport_Impact" = (sum(subset(Units, `Probable Failure` == "Transportation" )))/sum(subset(Units, Lateness != "Unmeasured")),
    "Air_Vendor_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD == "A" )))/sum(subset(Units, Lateness != "Unmeasured"))) %>% 
  right_join(as.data.frame(brand_vec), by = c("ReportingBrand" = "brand_vec")) %>% 
  mutate("SOT Variance from Target" = `SOT %` -.95) %>% 
  select(ReportingBrand, `SOT %`, `SOT Variance from Target`, `Transport_Impact`,`Air_Vendor_Impact`)

cat_vec <- c("Wovens", "Knits", "Denim and Woven Bottoms", "Sweaters", "IP", "Accessories", "Category Other", "3P & Lic")

Trans_output_Category_YTD <- SOT_Master_FOB %>%
  filter(ShipCancelWeek >= 1 & ShipCancelWeek <= 5, !grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed= FALSE)) %>% 
  group_by(Category) %>% 
  summarise("SOT %" = (sum(subset(Units, Lateness == "OnTime"), na.rm = TRUE))/sum(subset(Units, Lateness != "Unmeasured")),
            "Transport_Impact" = (sum(subset(Units, `Probable Failure` == "Transportation" )))/sum(subset(Units, Lateness != "Unmeasured")),
    "Air_Vendor_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD == "A" )))/sum(subset(Units, Lateness != "Unmeasured"))) %>% 
  right_join(as.data.frame(cat_vec), by = c("Category" = "cat_vec"))%>% 
  mutate("SOT Variance from Target" = `SOT %` -.95) %>%
  select(Category, `SOT %`, `SOT Variance from Target`, `Transport_Impact`, `Air_Vendor_Impact`)

Trans_output_GapInc_YTD <- SOT_Master_FOB %>%
  filter(ShipCancelWeek >= 1 & ShipCancelWeek <= 5, !grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed= FALSE)) %>% 
  # group_by(ReportingBrand) %>% 
  summarise("SOT %" = (sum(subset(Units, Lateness == "OnTime"), na.rm = TRUE))/sum(subset(Units, Lateness != "Unmeasured")),
            "Transport_Impact" = (sum(subset(Units, `Probable Failure` == "Transportation" )))/sum(subset(Units, Lateness != "Unmeasured")),
    "Air_Vendor_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD == "A" )))/sum(subset(Units, Lateness != "Unmeasured"))) %>% 
  # right_join(as.data.frame(brand_vec), by = c("ReportingBrand" = "brand_vec")) %>% 
  mutate("SOT Variance from Target" = `SOT %` -.95) %>% 
  select(`SOT %`, `SOT Variance from Target`, `Transport_Impact`, `Air_Vendor_Impact`)

write_csv(Trans_output, paste(SOT_OTS_directory, "Trans_output.csv", sep = .Platform$file.sep))
write_csv(Trans_output_Category, paste(SOT_OTS_directory, "Trans_output_category.csv", sep = .Platform$file.sep))
write_csv(Trans_output_GapInc, paste(SOT_OTS_directory, "Trans_output_GapInc.csv", sep = .Platform$file.sep))
write_csv(Trans_output_YTD, paste(SOT_OTS_directory, "Trans_output_YTD.csv", sep = .Platform$file.sep))
write_csv(Trans_output_Category_YTD, paste(SOT_OTS_directory, "Trans_output_category_YTD.csv", sep = .Platform$file.sep))
write_csv(Trans_output_GapInc_YTD, paste(SOT_OTS_directory, "Trans_output_GapInc_YTD.csv", sep = .Platform$file.sep))




# Trans_output_YTD <- SOT_Master_FOB %>%
#   filter(ShipCancelWeek >= 1 & ShipCancelWeek <= 5, !grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed= FALSE)) %>% 
#   group_by(ReportingBrand) %>% 
#   summarise("SOT %" = (sum(subset(Units, Lateness == "OnTime"), na.rm = TRUE))/sum(subset(Units, Lateness != "Unmeasured")),
#             "Transport_Impact" = (sum(subset(Units, `Probable Failure` == "Transportation" )))/sum(subset(Units, Lateness != "Unmeasured"))) %>% 
#   right_join(as.data.frame(brand_vec), by = c("ReportingBrand" = "brand_vec")) %>% 
#   mutate("SOT Variance from Target" = `SOT %` -.95) %>% 
#   select(ReportingBrand, `SOT %`, `SOT Variance from Target`, `Transport_Impact`)
# 
# cat_vec <- c("Wovens", "Knits", "Denim and Woven Bottoms", "Sweaters", "IP", "Accessories", "Category Other", "3P & Lic")
# 
# Trans_output_Category_YTD <- SOT_Master_FOB %>%
#   filter(ShipCancelWeek >= 1 & ShipCancelWeek <= 5, !grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed= FALSE)) %>% 
#   group_by(Category) %>% 
#   summarise("SOT %" = (sum(subset(Units, Lateness == "OnTime"), na.rm = TRUE))/sum(subset(Units, Lateness != "Unmeasured")),
#             "Vendor SOT" = (sum(subset(Units, Lateness == "OnTime"), na.rm = TRUE) + 
#                               sum(subset(Units, `Probable Failure` == "Transportation" )))/sum(subset(Units, Lateness != "Unmeasured"))) %>% 
#   right_join(as.data.frame(cat_vec), by = c("Category" = "cat_vec")) %>% 
#   mutate("SOT Variance from Target" = `SOT %` -.95,
#          "Vendor Variance from Target" = `Vendor SOT` - .95) %>% 
#   select(Category, `SOT %`, `SOT Variance from Target`, `Vendor SOT`, `Vendor Variance from Target`)
# 
# Trans_output_GapInc_YTD <- SOT_Master_FOB %>%
#   filter(ShipCancelWeek >= 1 & ShipCancelWeek <= 5, !grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed= FALSE)) %>% 
#   # group_by(ReportingBrand) %>% 
#   summarise("SOT %" = (sum(subset(Units, Lateness == "OnTime"), na.rm = TRUE))/sum(subset(Units, Lateness != "Unmeasured")),
#             "Vendor SOT" = (sum(subset(Units, Lateness == "OnTime"), na.rm = TRUE) + 
#                               sum(subset(Units, `Probable Failure` == "Transportation", Lateness = "Late" )))/sum(subset(Units, Lateness != "Unmeasured"))) %>% 
#   # right_join(as.data.frame(brand_vec), by = c("ReportingBrand" = "brand_vec")) %>% 
#   mutate("SOT Variance from Target" = `SOT %` -.95,
#          "Vendor Variance from Target" = `Vendor SOT` - .95) %>% 
#   select( `SOT %`, `SOT Variance from Target`, `Vendor SOT`, `Vendor Variance from Target`)


# Convert difftime to integer ----
SOT_Master_FOB$`Planned OC (Derived)` <- as.integer(SOT_Master_FOB$`Planned OC (Derived)`)
SOT_Master_FOB$`Days Late to OC` <- as.integer(SOT_Master_FOB$`Days Late to OC`)
SOT_Master_FOB$`Days Anticipated vs Contract` <- as.integer(SOT_Master_FOB$`Days Anticipated vs Contract`)
SOT_Master_FOB$`LP vs Anticipated` <- as.integer(SOT_Master_FOB$`LP vs Anticipated`)

write.xlsx(as.data.frame(SOT_Master_FOB), file = "SOT_MASTER_FOB.xlsx")
write_csv(as.data.frame(On_Time_Stock_table), path = paste(SOT_OTS_directory, "OTS.csv", sep = "\\"))

write_csv(SOT_Master_FOB[, c(1:5, 9, 12:15, 17:38, 40:42, 39, 43, 7, 6, 8, 16, 10:11, 44:45, 46:49)], path = paste(SOT_OTS_directory, "SOT_MASTER_FOB2.csv", sep = "\\"))


Transportation_table<- SOT_Master_FOB %>%
  group_by(SHIP_MODE_CD, Trade_Lane_Type, SALES_TERMS_CODE, `Test by OC`) %>% 
  summarise("Vendor Units" = sum(`Units`)) %>% 
  arrange(desc(`Vendor Units`))



save(SOT_Master_FOB, file = paste(SOT_OTS_directory, "SOT_Master_FOB.rda", sep = .Platform$file.sep))
save(SOT_Master, file = paste(SOT_OTS_directory, "SOT_Master.rda", sep = .Platform$file.sep))

library(XLConnect)


load("SOT_Master_FOB.rda")

SOT_Master_FOB


p <- SOT_Master_FOB %>% 
  subset(`Days Late to OC`<= 45) %>% 
  subset(`Days Late to OC`>= (-45)) %>% 
  
  
 p %>% plot_ly(x = ~p$ACTUAL_ORIGIN_CONSOL_LCL_DATE, y = ~p$`Days Late to OC`) %>% 
   add_markers() %>% 
   add_lines()

s <- SOT_Master_FOB[1:100,] %>% 
  subset(`Days Late to OC`<= 45 & `Days Late to OC`>= (-45)) %>%
  subset(`Days Late to OC` !=0 | DAYS_LATE != 0) %>% 
  arrange(ACTUAL_ORIGIN_CONSOL_LCL_DATE) %>% 
  plot_ly() %>% 
  add_markers(x = ~as.Date(p$ACTUAL_ORIGIN_CONSOL_LCL_DATE), y = ~p$`Days Late to OC`) %>% 
  add_markers(x = ~as.Date(p$ACTUAL_ORIGIN_CONSOL_LCL_DATE), y = ~p$`DAYS_LATE`) %>% 
  add_lines(x = ~p$`Days Late to OC`, y = ~p$`DAYS_LATE`)
  # gather(key = "Milestone", value = "Days Late", `DAYS_LATE`, `Days Late to OC`)

plot_ly(s, x = ~s$`Days Late to OC`, y = ~s$ACTUAL_ORIGIN_CONSOL_LCL_DATE, z = ~s$`DAYS_LATE`, color = s$Lateness) %>% 
  add_markers()