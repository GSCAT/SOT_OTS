# library(dplyr)
# library(readr)
# library(RODBC)
# library(formattable)
# library(rChoiceDialogs)
# library(ggvis)
#
# # Only Run this first section if the weekly SOT_Master is insufficient
# # i.e. Only necessary if starting from scratch
# # Setup Environment Variables/Functions ----
# # create functions and prompt for environment variables ----
# SOT_set_env <- function(){
#   source("prompts.R")
# }
# 
# # Type SOT_set_env() in the Console after running the above code ----
# 
# # For username and password ----
# if(!"credentials" %in% ls()){
#   path <- Sys.getenv("USERPROFILE")
#   credentials <- yaml.load_file(paste(path, "Desktop", "credentials.yml", sep = .Platform$file.sep))
# }
# 
# # Create RODBC connection ----
# my_connect <- odbcConnect(dsn= "IP EDWP", uid= credentials$my_uid, pwd= credentials$my_pwd)
# # sqlTables(my_connect, catalog = "EDWP", tableName  = "tables")
# sqlQuery(my_connect, query = "SELECT  * from dbc.dbcinfo;")
# 
# 
# save(SOT_Master, file = paste(SOT_OTS_directory,  'SOT_Master_object.rtf', sep = .Platform$file.sep))

# Install any missing packages 
list.of.packages <- c("readxl", "xlsx", "plotly", "tidyr", "mosaic", "devtools")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

# Sys.setenv(JAVA_HOME='C:\\Program Files\\Java\\jre1.8.0_161')

library(readxl)
library(xlsx)
library(plotly)
library(tidyr)
library(mosaic)
library(devtools)
# devtools::install_github("tidyverse/magrittr")
library(magrittr)
library(dplyr)
library(readr)

# TTP link: https://gapweb.gap.com/gw/content/gweb/en/sites/SupplyChain/Logistics/Logistics_Tools_and_Resources.html >> Supply Chain Master Data >> TTP
# TTP_table <- read.xlsx(file= "Transportation_Impact\\TTP_20170821.xlsx", sheetName = "Sheet1")

ttp_file <- grep("TTP", list.files(paste(getwd(), "Transportation_Impact", sep = .Platform$file.sep)), value = TRUE)[1]
paste("Reading in : ", ttp_file)
TTP_table <- read.xlsx(paste(getwd(), "Transportation_Impact", ttp_file, sep = .Platform$file.sep), sheetIndex = 1)

if(!dir.exists(file.path(SOT_OTS_directory, "Impact_files"))) {dir.create(file.path(SOT_OTS_directory, "Impact_files"))}

# Subset of SOT_Master_FOB v2 ----
SOT_Master_FOB <- SOT_Master %>% 
  droplevels() %>% 
  left_join(TTP_table, by = c("XFR_Point_Place" = "Transfer.Point", "DC_GEO_LOC" = "Geo.Description", "SHIP_MODE_CD" = "Ship.Mode")) %>% 
  mutate("Planned OC (Derived)" = Contract_Ship_Cancel - Days.Before.Ship.Cancel,
         "Days Late to OC" = ACTUAL_ORIGIN_CONSOL_LCL_DATE -`Planned OC (Derived)`,
         "Days Anticipated vs Contract" = SHIP_CANCEL_DATE - Contract_Ship_Cancel,
         "LP vs Anticipated" = ACTUAL_LP_LCL_DATE - SHIP_CANCEL_DATE,
         "Probable Failure" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "FOB" & SHIP_MODE_CD == "O", 
                                      derivedVariable("Transportation" = (SHIP_CANCEL_DATE <= (Contract_Ship_Cancel + 6)),
                                              "Vendor" =(SHIP_CANCEL_DATE >= (Contract_Ship_Cancel + 7)),
                                              # "Transportation" = (ACTUAL_LP_LCL_DATE > (Contract_Ship_Cancel + 2) & ( SHIP_CANCEL_DATE <= (Contract_Ship_Cancel))),
                                              "Vendor" = (`ACTUAL_ORIGIN_CONSOL_LCL_DATE` > `Planned OC (Derived)`),
                                              "Transportation" = (`ACTUAL_ORIGIN_CONSOL_LCL_DATE` <= `Planned OC (Derived)`),
                                              #"Trans" = (ACTUAL_LP_LCL_DATE + 2) > SHIP_CANCEL_DATE,
                                              .default = "NA",
                                            .method = "first"), "Not Tested"),
         "Sub Reason" = ifelse(Lateness == "Late" & SALES_TERMS_CODE == "FOB" & SHIP_MODE_CD == "O", 
                                     derivedVariable("Test1" = ( SHIP_CANCEL_DATE >= (Contract_Ship_Cancel)) & (SHIP_CANCEL_DATE <= (Contract_Ship_Cancel + 6)),
                                                     "Test2" =(SHIP_CANCEL_DATE >= (Contract_Ship_Cancel + 7)),
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
  # mutate("Probable Failure" = ifelse(Lateness == "Late" & SHIP_MODE_CD == "A", "Vendor", `Probable Failure`)) %>% 
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

# write_csv(SOT_Master_FOB[, c(1:5, 9, 12:15, 17:38, 40:42, 39, 43, 7, 6, 8, 16, 10:11, 44:45, 46:49)], 
#           path = paste(SOT_OTS_directory, "Impact_files", "SOT_MASTER_Impact_adhoc.csv", sep = "\\"))

SOT_Master_FOB %>% select(`NUMBER_SEQ`, `DEST_PO_ID`, `ReportingBrand`, `Category`, 
                          `Parent_Vendor`, `MetricShipDate`, `StockedDate`, `CountryOfOrigin`, 
                          `Lateness`, `ShipCancelMonth`, `DAYS_LATE`, `Vendor_Rank`, `Fiscal_Month`, 
                          `Quarter`, `FISCAL_YEAR`, `DC_GEO_LOC`, `MasterVendorID`, `AGT_DEPT_ID`, 
                          `AGENT_DEPT`, `OPR_BRD_STY_ID`, `Category_Source`, `SALES_TERMS_CODE`,
                          `SHIP_MODE_CD`, `ShipDateChoice`, `Trade_Lane_Type`, `ProgramType`, 
                          `BUYING_AGENT_GROUP`, `XFR_PT_COUNTRY_CODE`, `XFR_PT_PLACE_CODE`, 
                          `XFR_Point_Place`, `LOC_ABBR_NM`, `PROMPT_COUNTRY_ORIGIN`, 
                          `SHP_MODE_CATG_NM`, `Data_Pulled`, `Days.Before.Ship.Cancel`, 
                          `Planned OC (Derived)`, `SHP_RSN_TYP_DESC`, `Days Late to OC`, 
                          `SHIP_CANCEL_DATE`, `Contract_Ship_Cancel`, `Units`, `ShipCancelWeek`, 
                          `ACTUAL_ORIGIN_CONSOL_LCL_DATE`, `ACTUAL_LP_LCL_DATE`, `Days Anticipated vs Contract`, 
                          `LP vs Anticipated`, `Probable Failure`, `Sub Reason`, `Test by OC`, `Match?`) %T>%
  write_csv(path = paste(SOT_OTS_directory, "Impact_files", "SOT_MASTER_Impact_YTD.csv", sep = "\\")) %>% 
  filter(ShipCancelWeek == EOW) %>% 
  write_csv(path = paste(SOT_OTS_directory, "Impact_files", paste("SOT_MASTER_Impact_wk_", EOW, ".csv", sep = ""), sep = "\\"))

RCurl::ftpUpload(paste(SOT_OTS_directory, "Impact_files", "SOT_MASTER_Impact_YTD.csv", sep = "\\"),
                 "ftp://ftp.gap.com/data/to_hq/SupplyChainReporting/OTS_SOT%20Raw%20Data/SOT_MASTER_Impact_YTD.csv")
RCurl::ftpUpload(paste(SOT_OTS_directory, "Impact_files", paste("SOT_MASTER_Impact_wk_", EOW, ".csv", sep = ""), sep = "\\"),
                 paste("ftp://ftp.gap.com/data/to_hq/SupplyChainReporting/OTS_SOT%20Raw%20Data", paste("SOT_MASTER_Impact_wk_", EOW, ".csv", sep = ""), sep = .Platform$file.sep))

# # split outputs for GIS
# if(!dir.exists(file.path(SOT_OTS_directory, "Impact_files", "GIS_Splits_Output"))) {dir.create(file.path(SOT_OTS_directory, "Impact_files", "GIS_Splits_Output"))}
# SOT_MASTER_Impact <- SOT_Master_FOB %>% select(`NUMBER_SEQ`, `DEST_PO_ID`, `ReportingBrand`, `Category`, 
#                                   `Parent_Vendor`, `MetricShipDate`, `StockedDate`, `CountryOfOrigin`, 
#                                   `Lateness`, `ShipCancelMonth`, `DAYS_LATE`, `Vendor_Rank`, `Fiscal_Month`, 
#                                   `Quarter`, `FISCAL_YEAR`, `DC_GEO_LOC`, `MasterVendorID`, `AGT_DEPT_ID`, 
#                                   `AGENT_DEPT`, `OPR_BRD_STY_ID`, `Category_Source`, `SALES_TERMS_CODE`,
#                                   `SHIP_MODE_CD`, `ShipDateChoice`, `Trade_Lane_Type`, `ProgramType`, 
#                                   `BUYING_AGENT_GROUP`, `XFR_PT_COUNTRY_CODE`, `XFR_PT_PLACE_CODE`, 
#                                   `XFR_Point_Place`, `LOC_ABBR_NM`, `PROMPT_COUNTRY_ORIGIN`, 
#                                   `SHP_MODE_CATG_NM`, `Data_Pulled`, `Days.Before.Ship.Cancel`, 
#                                   `Planned OC (Derived)`, `SHP_RSN_TYP_DESC`, `Days Late to OC`, 
#                                   `SHIP_CANCEL_DATE`, `Contract_Ship_Cancel`, `Units`, `ShipCancelWeek`, 
#                                   `ACTUAL_ORIGIN_CONSOL_LCL_DATE`, `ACTUAL_LP_LCL_DATE`, `Days Anticipated vs Contract`, 
#                                   `LP vs Anticipated`, `Probable Failure`, `Sub Reason`, `Test by OC`, `Match?`) %>% 
#   arrange(`ShipCancelMonth`)
# 
# SOT_MASTER_Impact %>% filter(ShipCancelMonth <= 6) %>%
#   write_csv(path = paste(SOT_OTS_directory, "Impact_files", "GIS_Splits_Output", "SOT_MASTER_Impact_YTD_part1.csv", sep = "\\"))
# SOT_MASTER_Impact %>% filter(ShipCancelMonth > 6) %>%
#   write_csv(path = paste(SOT_OTS_directory, "Impact_files", "GIS_Splits_Output", "SOT_MASTER_Impact_YTD_part2.csv", sep = "\\"))

save(SOT_Master_FOB, file = paste(SOT_OTS_directory, "Impact_files",  'SOT_Master_FOB.rda', sep = .Platform$file.sep))

cat_vec <- c("Wovens", "Knits", "Denim and Woven Bottoms", "Sweaters", "IP", "Accessories", "Category Other", "3P & Lic")
brand_vec <- c("GAP NA", "BR NA", "ON NA", "GO NA", "BRFS NA", "GAP INTL", "BR INTL", "ON INTL", "GO INTL", "ATHLETA")

Trans_output <- SOT_Master_FOB %>%
  filter(ShipCancelWeek == EOW,  !grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed= FALSE)) %>% 
  group_by(ReportingBrand) %>% 
  summarise(
    "Late_Units" = (sum(subset(Units,Lateness == "Late"), na.rm = TRUE)),
    "Total_Units" = (sum(Units, na.rm = TRUE)),
    "SOT %" = (sum(subset(Units, Lateness == "OnTime"), na.rm = TRUE))/sum(subset(Units, Lateness != "Unmeasured")),
    "Transport_Impact" = (sum(subset(Units, `Probable Failure` == "Transportation")))/sum(subset(Units, Lateness != "Unmeasured")),
    "Air_Vendor_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD == "A" )))/sum(subset(Units, Lateness != "Unmeasured")),
    "Vendor_non_Air_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD != "A" )))/sum(subset(Units, Lateness != "Unmeasured")),
    "Unmeasured_Impact" = 1 - sum(`Transport_Impact` + `Air_Vendor_Impact` + `Vendor_non_Air_Impact` + `SOT %`),
    "Total_Impact" = sum(`Transport_Impact` + `Air_Vendor_Impact` + `Vendor_non_Air_Impact` + `Unmeasured_Impact` + `SOT %`)) %>% 
  right_join(as.data.frame(brand_vec), by = c("ReportingBrand" = "brand_vec")) %>% 
  mutate("SOT Variance from Target" = `SOT %` -.95) %>% 
  select(ReportingBrand, `Late_Units`,`Total_Units`, `SOT %`, `SOT Variance from Target`, `Transport_Impact`, `Air_Vendor_Impact`, `Vendor_non_Air_Impact`, `Unmeasured_Impact`,  `Total_Impact`)

Trans_output_Category <- SOT_Master_FOB %>%
  filter(ShipCancelWeek == EOW, !grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed= FALSE)) %>% 
  group_by(Category) %>% 
  summarise(
            "Late_Units" = (sum(subset(Units,Lateness == "Late"), na.rm = TRUE)),
            "Total_Units" = (sum(Units, na.rm = TRUE)),
            "SOT %" = (sum(subset(Units, Lateness == "OnTime"), na.rm = TRUE))/sum(subset(Units, Lateness != "Unmeasured")),
            "Transport_Impact" = (sum(subset(Units, `Probable Failure` == "Transportation")))/sum(subset(Units, Lateness != "Unmeasured")),
            "Air_Vendor_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD == "A" )))/sum(subset(Units, Lateness != "Unmeasured")),
            "Vendor_non_Air_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD != "A" )))/sum(subset(Units, Lateness != "Unmeasured")),
            "Unmeasured_Impact" = 1 - sum(`Transport_Impact` + `Air_Vendor_Impact` + `Vendor_non_Air_Impact` + `SOT %`),
            "Total_Impact" = sum(`Transport_Impact` + `Air_Vendor_Impact` + `Vendor_non_Air_Impact` + `Unmeasured_Impact` + `SOT %`)) %>% 
  right_join(as.data.frame(cat_vec), by = c("Category" = "cat_vec")) %>% 
  mutate("SOT Variance from Target" = `SOT %` -.95) %>% 
  select(Category, `Late_Units`,`Total_Units`,`SOT %`, `SOT Variance from Target`, `Transport_Impact`, `Air_Vendor_Impact`, `Vendor_non_Air_Impact`, `Unmeasured_Impact`,  `Total_Impact`)

Trans_output_GapInc <- SOT_Master_FOB %>%
  filter(ShipCancelWeek == EOW, !grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed= FALSE)) %>% 
  # group_by(ReportingBrand) %>% 
  summarise(
            "Late_Units" = (sum(subset(Units,Lateness == "Late"), na.rm = TRUE)),
            "Total_Units" = sum(Units),
            "SOT %" = (sum(subset(Units, Lateness == "OnTime"), na.rm = TRUE))/sum(subset(Units, Lateness != "Unmeasured")),
            "Transport_Impact" = (sum(subset(Units, `Probable Failure` == "Transportation")))/sum(subset(Units, Lateness != "Unmeasured")),
            "Air_Vendor_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD == "A" )))/sum(subset(Units, Lateness != "Unmeasured")),
            "Vendor_non_Air_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD != "A" )))/sum(subset(Units, Lateness != "Unmeasured")),
            "Unmeasured_Impact" = 1 - sum(`Transport_Impact` + `Air_Vendor_Impact` + `Vendor_non_Air_Impact` + `SOT %`),
            "Total_Impact" = sum(`Transport_Impact` + `Air_Vendor_Impact` + `Vendor_non_Air_Impact` + `Unmeasured_Impact` + `SOT %`)) %>% 
  # right_join(as.data.frame(brand_vec), by = c("ReportingBrand" = "brand_vec")) %>% 
  mutate("SOT Variance from Target" = `SOT %` -.95) %>% 
  select(`Late_Units`,`Total_Units`, `SOT %`, `SOT Variance from Target`, `Transport_Impact`, `Air_Vendor_Impact`, `Vendor_non_Air_Impact`, `Unmeasured_Impact`,  `Total_Impact`)

Trans_Units_for_commentary <- SOT_Master_FOB %>% 
  filter(ShipCancelWeek == EOW, !grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed= FALSE)) %>% 
  summarise("Total_Units" = sum(Units),
            "Total_Late_Units" = sum(subset(Units, Lateness == "Late")),
            "Transportation_Delay_Units" = floor(sum(subset(Units, `Probable Failure` == "Transportation"))),
            "Vendor_Air_Delay_Units" = sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD == "A" )),
            "Vendor_nonair_Delay_Units" = sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD != "A" )),
            "Untested_Units" = floor(sum(subset(Units, `Probable Failure` == "Not Tested" & Lateness == "Late"))),
            "Unmeasured_Units" = sum(subset(Units, Lateness == "Unmeasured")))
Trans_Units_for_commentary

# write_csv(Trans_Units_for_commentary, paste(SOT_OTS_directory, "Impact_files",  "Trans_Units_for_commentary.csv", sep = .Platform$file.sep))           


Trans_output_YTD <- SOT_Master_FOB %>%
  filter(FISCAL_YEAR == fis_yr,  !grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed= FALSE)) %>%
  group_by(ReportingBrand) %>% 
  summarise("SOT %" = (sum(subset(Units, Lateness == "OnTime"), na.rm = TRUE))/sum(subset(Units, Lateness != "Unmeasured")),
            "Transport_Impact" = (sum(subset(Units, `Probable Failure` == "Transportation")))/sum(subset(Units, Lateness != "Unmeasured")),
            "Air_Vendor_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD == "A" )))/sum(subset(Units, Lateness != "Unmeasured")),
            "Vendor_non_Air_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD != "A" )))/sum(subset(Units, Lateness != "Unmeasured")),
            "Unmeasured_Impact" = 1 - sum(`Transport_Impact` + `Air_Vendor_Impact` + `Vendor_non_Air_Impact` + `SOT %`),
            "Total_Impact" = sum(`Transport_Impact` + `Air_Vendor_Impact` + `Vendor_non_Air_Impact` + `Unmeasured_Impact` + `SOT %`)) %>%  
  right_join(as.data.frame(brand_vec), by = c("ReportingBrand" = "brand_vec")) %>% 
  mutate("SOT Variance from Target" = `SOT %` -.95) %>% 
  select(ReportingBrand, `SOT %`, `SOT Variance from Target`, `Transport_Impact`,`Air_Vendor_Impact`, `Vendor_non_Air_Impact`, `Unmeasured_Impact`,  `Total_Impact`)


Trans_output_Category_YTD <- SOT_Master_FOB %>%
  filter(FISCAL_YEAR == fis_yr,  !grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed= FALSE)) %>%
  group_by(Category) %>% 
  summarise("SOT %" = (sum(subset(Units, Lateness == "OnTime"), na.rm = TRUE))/sum(subset(Units, Lateness != "Unmeasured")),
            "Transport_Impact" = (sum(subset(Units, `Probable Failure` == "Transportation")))/sum(subset(Units, Lateness != "Unmeasured")),
            "Air_Vendor_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD == "A" )))/sum(subset(Units, Lateness != "Unmeasured")),
            "Vendor_non_Air_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD != "A" )))/sum(subset(Units, Lateness != "Unmeasured")),
            "Unmeasured_Impact" = 1 - sum(`Transport_Impact` + `Air_Vendor_Impact` + `Vendor_non_Air_Impact` + `SOT %`),
            "Total_Impact" = sum(`Transport_Impact` + `Air_Vendor_Impact` + `Vendor_non_Air_Impact` + `Unmeasured_Impact` + `SOT %`)) %>% 
  right_join(as.data.frame(cat_vec), by = c("Category" = "cat_vec"))%>% 
  mutate("SOT Variance from Target" = `SOT %` -.95) %>%
  select(Category, `SOT %`, `SOT Variance from Target`, `Transport_Impact`, `Air_Vendor_Impact`, `Vendor_non_Air_Impact`, `Unmeasured_Impact`,  `Total_Impact`)

Trans_output_GapInc_YTD <- SOT_Master_FOB %>%
  filter(FISCAL_YEAR == fis_yr,  !grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed= FALSE)) %>%
  # group_by(ReportingBrand) %>% 
  summarise("SOT %" = (sum(subset(Units, Lateness == "OnTime"), na.rm = TRUE))/sum(subset(Units, Lateness != "Unmeasured")),
            "Transport_Impact" = (sum(subset(Units, `Probable Failure` == "Transportation")))/sum(subset(Units, Lateness != "Unmeasured")),
            "Air_Vendor_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD == "A" )))/sum(subset(Units, Lateness != "Unmeasured")),
            "Vendor_non_Air_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD != "A" )))/sum(subset(Units, Lateness != "Unmeasured")),
            "Unmeasured_Impact" = 1 - sum(`Transport_Impact` + `Air_Vendor_Impact` + `Vendor_non_Air_Impact` + `SOT %`),
            "Total_Impact" = sum(`Transport_Impact` + `Air_Vendor_Impact` + `Vendor_non_Air_Impact` + `Unmeasured_Impact` + `SOT %`)) %>% 
  # right_join(as.data.frame(brand_vec), by = c("ReportingBrand" = "brand_vec")) %>% 
  mutate("SOT Variance from Target" = `SOT %` -.95) %>% 
  select(`SOT %`, `SOT Variance from Target`, `Transport_Impact`, `Air_Vendor_Impact`, `Vendor_non_Air_Impact`, `Unmeasured_Impact`,  `Total_Impact`)

write_csv(Trans_output, paste(SOT_OTS_directory, "Impact_files",  "Trans_output.csv", sep = .Platform$file.sep))
write_csv(Trans_output_Category, paste(SOT_OTS_directory, "Impact_files",  "Trans_output_category.csv", sep = .Platform$file.sep))
write_csv(Trans_output_GapInc, paste(SOT_OTS_directory, "Impact_files",  "Trans_output_GapInc.csv", sep = .Platform$file.sep))
write_csv(Trans_output_YTD, paste(SOT_OTS_directory, "Impact_files",  "Trans_output_YTD.csv", sep = .Platform$file.sep))
write_csv(Trans_output_Category_YTD, paste(SOT_OTS_directory, "Impact_files", "Trans_output_category_YTD.csv", sep = .Platform$file.sep))
write_csv(Trans_output_GapInc_YTD, paste(SOT_OTS_directory, "Impact_files", "Trans_output_GapInc_YTD.csv", sep = .Platform$file.sep))


Unidentified_RC <- SOT_Master_FOB %>% filter(ShipCancelWeek == EOW, Lateness == "Late", `Probable Failure` == "Not Tested")

