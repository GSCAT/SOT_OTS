# Install missing packages ----
list.of.packages <- c("dplyr", "readr", "RODBC", "formattable", 
                      "rJava", "rChoiceDialogs", "ggvis", "tidyr", 
                      "colorspace",  "mosaic", "yaml", "RJDBC", "DBI")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

# Install libraries ----
library(dplyr)
library(readr)
library(RODBC)
library(formattable)
library(rJava)
library(rChoiceDialogs)
library(ggvis)
library(tidyr)
library(colorspace)
library(mosaic)
library(yaml)
library(lubridate)
library(RJDBC)
library(DBI)

# Start with clean environment ----
# rm(list = ls())

# create functions and prompt for environment variables ----
SOT_set_env <- function(){
  source("prompts.R")
}

# Type SOT_set_env() in the Console after running the above code ----

# For username and password ----
if(!"credentials" %in% ls()){
  path <- Sys.getenv("USERPROFILE")
  credentials <- yaml.load_file(paste(path, "Desktop", "credentials.yml", sep = .Platform$file.sep))
}

# Save Workspace ----
# rm(credentials)
# save.image(paste(SOT_OTS_directory, paste("Week_", EOW, ".RData", sep = ""), sep=.Platform$file.sep))
# load(file = paste(SOT_OTS_directory, paste("Week_", EOW, ".RData", sep = ""), sep = .Platform$file.sep))

# Create RODBC connection ----
# my_connect <- odbcConnect(dsn= "IP EDWP", uid= credentials$my_uid, pwd= credentials$my_pwd)
# sqlTables(my_connect, catalog = "EDWP", tableName  = "tables")
# sqlQuery(my_connect, query = "SELECT  * from dbc.dbcinfo;")

drv=JDBC("com.teradata.jdbc.TeraDriver","C:\\TeraJDBC__indep_indep.16.10.00.05\\terajdbc4.jar;C:\\TeraJDBC__indep_indep.16.10.00.05\\tdgssconfig.jar")
conn=dbConnect(drv,"jdbc:teradata://10.107.56.31/LOGMECH=LDAP",credentials$my_uid, credentials$my_pwd)
dbGetQuery(conn, statement = "SELECT  * from dbc.dbcinfo;")
gc() # Garbage collection (BASE)

jdbc_fetch <- dbSendQuery(conn, "SELECT * FROM SRAA_SAND.VIEW_SOT_MASTER")

chunk <-  dbFetch(jdbc_fetch, 1)
chunk$Data_Pulled == Sys.Date()
length <- dbGetQuery(conn, "Select count(*) from SRAA_SAND.VIEW_SOT_MASTER")
system.time(while (!nrow(chunk) >= length) {
  chunk <- rbind(chunk, dbFetch(jdbc_fetch, 100000))
  gc()
  print(nrow(chunk))
})

SOT_Master <- chunk
rm(chunk)
dbClearResult(jdbc_fetch)
gc()

jdbc_fetch <- dbSendQuery(conn, "SELECT * FROM SRAA_SAND.VIEW_OTS_MASTER")

chunk <-  dbFetch(jdbc_fetch, 1)
chunk$Data_Pulled == Sys.Date()
length <- dbGetQuery(conn, "Select count(*) from SRAA_SAND.VIEW_OTS_MASTER")
system.time(while (!nrow(chunk) >= length) {
  chunk <- rbind(chunk, dbFetch(jdbc_fetch, 100000))
  gc()
  print(nrow(chunk))
})

OTS_Master <- chunk
rm(chunk)
dbClearResult(jdbc_fetch)
gc()


total_rows_SOT <- dbGetQuery(conn, statement = "select count(*) from SRAA_SAND.VIEW_SOT_MASTER; ")
total_rows_OTS <- dbGetQuery(conn, statement = "select count(*) from SRAA_SAND.VIEW_OTS_MASTER; ")
total_rows_SOT
total_rows_OTS
date_check <- dbGetQuery(conn, statement = "select Data_Pulled from SRAA_SAND.VIEW_SOT_MASTER sample 1;")
max_stock_date <-  dbGetQuery(conn, statement = "select max(ACTUAL_STOCKED_LCL_DATE) as max_stocked_date from SRAA_SAND.EDW_IUF_YTD;")

dbDisconnect(conn)
# Convert Dates and factors ----
SOT_Master[, c(6:7, 9:12, 41:43)] <- SOT_Master[, c(6:7, 9:12, 41:43)] %>% mutate_all(funs(as.Date(.)))
SOT_Master <- SOT_Master %>%
mutate_all(funs(if(is.character(.)) as.factor(.) else .))

OTS_Master[, c(7:11, 30:31, 33:34)] <- OTS_Master[, c(7:11, 30:31, 33:34)] %>% mutate_all(funs(as.Date(.)))
# OTS_Master <- OTS_Master %>%
#   mutate_all(funs(if(is.character(.)) as.factor(.) else .))

# total_rows_SOT <- sqlQuery(my_connect, query = "select count(*) from SRAA_SAND.VIEW_SOT_MASTER; ")
# total_rows_OTS <- sqlQuery(my_connect, query = "select count(*) from SRAA_SAND.VIEW_OTS_MASTER; ")
# date_check <- sqlQuery(my_connect, query = "select Data_Pulled from SRAA_SAND.VIEW_SOT_MASTER sample 1;")
# max_stock_date <-  sqlQuery(my_connect, query = "select max(ACTUAL_STOCKED_LCL_DATE) as max_stocked_date from SRAA_SAND.EDW_IUF_YTD;")

date_check
max_stock_date


# if(date_check[[1]] == Sys.Date()) {
#   test_exists = 1
#   paste("Latest refresh is ", date_check[[1]], "Proceding to query")
#   # Create Master Objects ----
#   system.time(SOT_Master <- sqlQuery(my_connect,
#                                      query = "SELECT  * from SRAA_SAND.VIEW_SOT_MASTER;"))
# 
#   system.time(OTS_Master <- sqlQuery(my_connect,
#                                      query = "SELECT  * from SRAA_SAND.VIEW_OTS_MASTER;"))
# } else if (readline("Data is old. Would you like to continue? Y or N: ") == 'Y') {
#   test_exists = 1
#   paste("Latest refresh is", Sys.Date() - date_check[[1]], "days old. Continuing anyway")
#   # Create Master Objects ----
#   system.time(SOT_Master <- sqlQuery(my_connect,
#                                      query = "SELECT  * from SRAA_SAND.VIEW_SOT_MASTER;"))
# 
#   system.time(OTS_Master <- sqlQuery(my_connect,
#                                      query = "SELECT  * from SRAA_SAND.VIEW_OTS_MASTER;"))
#   
# } else {
#   test_exists = 0
#   paste("Aborting")
# }

## Run below load statements if restoring from a previously saved object stored in the working directory. 
## Skip to "Create Master Objects" if pulling fresh data ----
# load(file = paste(SOT_OTS_directory, 'RAW_Objects','SOT_Master_object.rtf', sep = .Platform$file.sep))
# load(file = paste(SOT_OTS_directory, 'RAW_Objects', 'OTS_Master_object.rtf', sep = .Platform$file.sep ))

# Close connection ----
# close(my_connect)

# if ( test_exists == 1){
#   paste("Data has been pulled")

#  system.time(SOT_Master_ODBC <- sqlQuery(my_connect,
#                                    query = "SELECT  * from SRAA_SAND.VIEW_SOT_MASTER sample 2000;"))

SOT_Data_Pulled <- SOT_Master$Data_Pulled[1]
OTS_Data_Pulled <- OTS_Master$Data_Pulled[1]
# Check date
SOT_Data_Pulled
OTS_Data_Pulled

# Create/write Summary Metadata ----
SOT_Master_Summary <- as.data.frame(summary(SOT_Master))
OTS_Master_Summary <- as.data.frame(summary(OTS_Master))

dir.create((file.path(SOT_OTS_directory, "Summary_Files")))
dir.create((file.path(SOT_OTS_directory, "RAW_Files")))
dir.create((file.path(SOT_OTS_directory, "RAW_Objects")))
dir.create((file.path(SOT_OTS_directory, "Clean_Files")))
dir.create((file.path(SOT_OTS_directory, "Master_Files")))

write_csv(SOT_Master_Summary, path = paste(SOT_OTS_directory, "Summary_Files", paste('SOT_Master_RAW_Metadata_WK', EOW, '.csv',sep = ""), sep = .Platform$file.sep ))
write_csv(OTS_Master_Summary, path = paste(SOT_OTS_directory, "Summary_Files", paste('OTS_Master_RAW_Metadata_WK', EOW, '.csv',sep = ""), sep = .Platform$file.sep ))

# Write Raw files to .csv ----
write_csv(SOT_Master, path = paste(SOT_OTS_directory, "RAW_Files",  'SOT_Master_Raw.csv', sep = '/' ))
write_csv(OTS_Master, path = paste(SOT_OTS_directory, "RAW_Files",  'OTS_Master_Raw.csv', sep = '/' ))

# Save Raw objects ----
save(SOT_Master, file = paste(SOT_OTS_directory, "RAW_Objects",  'SOT_Master_object.rtf', sep = .Platform$file.sep))
save(OTS_Master, file = paste(SOT_OTS_directory, "RAW_Objects",  'OTS_Master_object.rtf', sep = .Platform$file.sep ))
 
# Save Unmeasured subset ----
SOT_Master_Unmeasured <- SOT_Master %>% 
  filter(!grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed=FALSE)) %>%
  filter(ShipCancelWeek <= EOW,
         FISCAL_YEAR == fis_yr,
         !grepl("Liberty Distribution Company", Parent_Vendor, ignore.case = TRUE),
         !grepl("dummy", Parent_Vendor, ignore.case = TRUE),
         Lateness == "Unmeasured") %>% 
  droplevels()

save(SOT_Master_Unmeasured, file = paste(SOT_OTS_directory, 
                                         "RAW_Objects",  'SOT_Master_Unmeasured_object.rtf', 
                                         sep = .Platform$file.sep))
write_csv(SOT_Master_Unmeasured, path = paste(SOT_OTS_directory, "Master_Files",  
                                              paste('SOT_Master_Unmeasured_WK', EOW, '_YTD.csv',sep = ""), 
                                              sep = .Platform$file.sep ))

# Scrub Noise from Master Objects ----
OTS_Master <- OTS_Master %>% 
  filter(!grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed=FALSE)) %>% 
  filter(Week <= EOW,
        !is.na(DC_NAME),
        !grepl("Liberty Distribution Company", Parent_Vendor, ignore.case = TRUE),
        !grepl("dummy", Parent_Vendor, ignore.case = TRUE),
        !grepl("JPF", DC_NAME, ignore.case = TRUE)) %>% 
  droplevels()

SOT_Master <- SOT_Master %>% 
  filter(!grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed=FALSE)) %>%
  filter(ShipCancelWeek <= EOW,
         FISCAL_YEAR == fis_yr,
         !grepl("Liberty Distribution Company", Parent_Vendor, ignore.case = TRUE),
         !grepl("dummy", Parent_Vendor, ignore.case = TRUE),
         MetricShipDate <= SOT_Data_Pulled) %>% 
  droplevels()


########## FIX UNITS in OTS_MASTER #############
OTS_Master <- OTS_Master %>% 
  # filter(`Week` >= 21) %>% 
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


# Write out the cleaned master files ----
write_csv(SOT_Master, path = paste(SOT_OTS_directory, "Clean_Files",  'SOT_Master_clean_YTD.csv', sep = .Platform$file.sep ))
write_csv(OTS_Master, path = paste(SOT_OTS_directory, "Clean_Files",  'OTS_Master_clean_YTD.csv', sep = .Platform$file.sep ))

# Save Clean objects for visualization ----
save(SOT_Master, file = paste(SOT_OTS_directory, "Clean_Files",  'SOT_Master_clean_object.rtf', sep = .Platform$file.sep))
save(OTS_Master, file = paste(SOT_OTS_directory, "Clean_Files",  'OTS_Master_clean_object.rtf', sep = .Platform$file.sep ))
 
SOT_Master %>% filter(ShipCancelWeek == EOW) %>% write_csv( path = paste(SOT_OTS_directory, "Clean_Files",  paste('SOT_Master_clean_wk', EOW, '.csv', sep = ""), sep = .Platform$file.sep ))
OTS_Master %>% filter(Week == EOW) %>% write_csv( path = paste(SOT_OTS_directory, "Clean_Files",  paste('OTS_Master_clean_wk', EOW, '.csv', sep = ""), sep = .Platform$file.sep ))


# Create/write Metadata for Week subset ----
SOT_Master_Summary_curr_week <- SOT_Master %>% filter(ShipCancelWeek ==EOW) %>% summary() %>% as.data.frame() 
OTS_Master_Summary_curr_week <- OTS_Master %>% filter(Week ==EOW) %>% summary() %>% as.data.frame() 

write_csv(as.data.frame(SOT_Master_Summary_curr_week), 
          path = paste(SOT_OTS_directory, "Summary_Files",  paste('SOT_Master_Metadata_curr_week', EOW, '.csv',sep = ""), sep = .Platform$file.sep ))
write_csv(as.data.frame(OTS_Master_Summary_curr_week), 
          path = paste(SOT_OTS_directory, "Summary_Files",  paste('OTS_Master_Metadata_curr_week', EOW, '.csv',sep = ""), sep = .Platform$file.sep ))

# Create Output Tables ----

# 1) OTS by Category Summary
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

# 2) OTS by Vendor Summary
OTS_by_Vendor <- OTS_Master %>%
  # filter(!grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed=FALSE)) %>%
  group_by(Vendor_Rank, Parent_Vendor, Month_Number,Week) %>%
  summarise(TotalUnits= sum(Units), 
            OnTimeUnits = sum(Units[Lateness=="OnTime"]), 
            LateUnits = sum(Units[Lateness=="Late"]), 
            WtDaysLate = sum(Units[Lateness=="Late"] * Days_Late[Lateness=="Late"]),
            DaysLate5 = sum(Units[Days_Late > 5 & Lateness=="Late"]),
            UnitsArriveLessThanNeg5 = sum(Units[(Lateness=="OnTime" | Lateness == "Late") & (Days_Late <= -5)]),
            UnitsArriveLessThanNeg3 = sum(Units[(Lateness=="OnTime" | Lateness == "Late") & (Days_Late <= -3)]),
            UnitsArriveLessThan0 = sum(Units[(Lateness=="OnTime" | Lateness == "Late") & (Days_Late <= 0)]),
            UnitsArriveLessThan3 = sum(Units[(Lateness=="OnTime" | Lateness == "Late") & (Days_Late <= 3)]),
            UnitsArriveLessThan5 = sum(Units[(Lateness=="OnTime" | Lateness == "Late") & (Days_Late <= 5)])) %>%
  droplevels()


# 3) SOT by Category Summary
SOT_by_Category <- SOT_Master %>%
  # filter(!grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed=FALSE)) %>%
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

# 4) SOT by Vendor Summary
SOT_by_Vendor <- SOT_Master %>%
  # filter(!grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed=FALSE)) %>%
  group_by(Vendor_Rank, Parent_Vendor, ShipCancelMonth, ShipCancelWeek) %>%
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

# Output Tables to .csv ----
write_csv(OTS_by_Category, path = paste(SOT_OTS_directory,  'OTS_by_Category.csv', sep = .Platform$file.sep ))
write_csv(OTS_by_Vendor, path = paste(SOT_OTS_directory,  'OTS_by_Vendor.csv', sep = .Platform$file.sep ))

write_csv(SOT_by_Category, path = paste(SOT_OTS_directory,  'SOT_by_Category.csv', sep = .Platform$file.sep ))
write_csv(SOT_by_Vendor, path = paste(SOT_OTS_directory,  'SOT_by_Vendor.csv', sep = .Platform$file.sep ))

# YTD Masters
write_csv(SOT_Master, path = paste(SOT_OTS_directory, "Master_Files",  paste('SOT_Master_WK', EOW, '_YTD.csv',sep = ""), sep = .Platform$file.sep ))
write_csv(OTS_Master, path = paste(SOT_OTS_directory, "Master_Files",  paste('OTS_Master_WK', EOW, '_YTD.csv',sep = ""), sep = .Platform$file.sep))

# 7 day Masters
write_csv(subset(SOT_Master, ShipCancelWeek == EOW), path = paste(SOT_OTS_directory, "Master_Files",  paste('SOT_Master_WK', EOW, '.csv',sep = ""), sep = .Platform$file.sep))
write_csv(subset(OTS_Master, Week == EOW), path = paste(SOT_OTS_directory, "Master_Files",  paste('OTS_Master_WK', EOW, '.csv',sep = ""), sep = .Platform$file.sep))
# }
# #### Save SOT and OTS Master objects to Monthly dir for reporting ----
# Monthly_directory <- choose_file_directory()
# dir.create((file.path(Monthly_directory, "Monthly_objects")))
# 
# save(SOT_Master, file = paste(Monthly_directory, "Monthly_objects",  'SOT_Master_object.rtf', sep = .Platform$file.sep))
# save(OTS_Master, file = paste(Monthly_directory, "Monthly_objects",  'OTS_Master_object.rtf', sep = .Platform$file.sep ))

