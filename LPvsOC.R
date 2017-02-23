library(dplyr)
library(readr)
library(RODBC)
library(formattable)
library(rChoiceDialogs)
library(ggvis)
library(xlsx)

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
                       query = "SELECT  * from SRAA_SAND.VIEW_SOT_MASTER_TTP;")
close(my_connect)

# load(file = paste(SOT_OTS_directory,  'SOT_Master_object.rtf', sep = .Platform$file.sep))
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

TTP_table <- read.xlsx(file= "TTP.xlsx", sheetName = "Sheet4")

SOT_Master_FOB <- SOT_Master %>% 
  subset(SALES_TERMS_CODE == "FOB" & SHIP_MODE_CD == "O") %>% 
  droplevels() %>% 
  left_join(TTP_table, by = c("XFR_PT_COUNTRY_CODE" = "TP.Code", "DC_GEO_LOC" = "Geo.Description")) %>% 
  mutate("Planned OC (Derived)" = Contract_Ship_Cancel - Days.Before.Ship.Cancel)


