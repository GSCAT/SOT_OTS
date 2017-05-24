library(dplyr)
library(readr)
library(RODBC)
library(formattable)
library(RJDBC)
library(rChoiceDialogs)
library(ggvis)

my_uid <- read_lines("C:\\Users\\Ke2l8b1\\Documents\\my_uid.txt")
my_pwd <- read_lines("C:\\Users\\Ke2l8b1\\Documents\\my_pwd.txt")

# Create RODBC connection ----
my_connect <- odbcConnect(dsn= "IP EDWP", uid= my_uid, pwd= my_pwd)
# sqlTables(my_connect, catalog = "EDWP", tableName  = "tables")
sqlQuery(my_connect, query = "SELECT  * from dbc.dbcinfo;")

# Create RJDBC connection - In Dev ----
#Sys.setenv(JAVA_HOME= "C:\\Users\\Ke2l8b1\\Documents\\Teradata\\JDBC_Driver\\jre-8u101-windows-x64.exe")
# drv2 <- JDBC("com.teradata.jdbc.TeraConnectionPoolDataSource", "C:\\Users\\Ke2l8b1\\Documents\\Teradata\\JDBC_Driver\\terajdbc4.jar;C:\\Users\\Ke2l8b1\\Documents\\Teradata\\JDBC_Driver\\tdgssconfig.jar")
# conn <- dbConnect(drv2, "jdbc:teradata://tdprodcop1.gap.com", my_uid, my_pwd)
# SOT_Master_RJDBC <- dbGetQuery(conn, 
#                       query = "SELECT  * from dbc.dbcinfo;")


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

# load(file = paste(SOT_OTS_directory,  'SOT_Master_object.rtf', sep = .Platform$file.sep))
# load(file = paste(SOT_OTS_directory,  'OTS_Master_object.rtf', sep = .Platform$file.sep ))

# Create Master Objects ----
SOT_Master <- sqlQuery(my_connect, 
                     query = "SELECT  * from SRAA_SAND.VIEW_SOT_MASTER;")

OTS_Master <- sqlQuery(my_connect, 
                           query = "SELECT  * from SRAA_SAND.VIEW_OTS_MASTER;")

# OTS_Master <- sqlQuery(my_connect, 
#                           query = "SELECT  * from SRAA_SAND.VIEW_OTS_MASTER_TEST;")

# save(OTS_Master, file = paste(SOT_OTS_directory,  'OTS_Master_object_TEST.rtf', sep = .Platform$file.sep ))


# Close connection ----
close(my_connect)

SOT_Data_Pulled <- SOT_Master$Data_Pulled[1]
OTS_Data_Pulled <- OTS_Master$Data_Pulled[1]
# Check date
SOT_Data_Pulled
OTS_Data_Pulled

# Create/write Summary Metadata ----
SOT_Master_Summary <- as.data.frame(summary(SOT_Master))
OTS_Master_Summary <- as.data.frame(summary(OTS_Master))


write_csv(SOT_Master_Summary, path = paste(SOT_OTS_directory,  paste('SOT_Master_RAW_Metadata_WK', EOW, '.csv',sep = ""), sep = '/' ))
write_csv(OTS_Master_Summary, path = paste(SOT_OTS_directory,  paste('OTS_Master_RAW_Metadata_WK', EOW, '.csv',sep = ""), sep = '/' ))

# Write Raw files to .csv ----
write_csv(SOT_Master, path = paste(SOT_OTS_directory,  'SOT_Master_Raw.csv', sep = '/' ))
write_csv(OTS_Master, path = paste(SOT_OTS_directory,  'OTS_Master_Raw.csv', sep = '/' ))

# Save Raw objects ----
save(SOT_Master, file = paste(SOT_OTS_directory,  'SOT_Master_object.rtf', sep = .Platform$file.sep))
save(OTS_Master, file = paste(SOT_OTS_directory,  'OTS_Master_object.rtf', sep = .Platform$file.sep ))

# load(file = paste(SOT_OTS_directory,  'SOT_Master_object.rtf', sep = .Platform$file.sep))

# load(file = paste(SOT_OTS_directory,  'SOT_Master_object.rtf', sep = .Platform$file.sep))

# Scrub Noise from Master Objects ----
OTS_Master <- OTS_Master %>% 
  filter(!grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed=FALSE)) %>% 
  filter(Week <= EOW,
        !is.na(DC_NAME),
        !grepl("Liberty Distribution Company", Parent_Vendor, ignore.case = TRUE),
        !grepl("dummy", Parent_Vendor, ignore.case = TRUE),
        !grepl("JPF", DC_NAME, ignore.case = TRUE)) 

SOT_Master <- SOT_Master %>% 
  filter(!grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed=FALSE)) %>%
  filter(ShipCancelWeek <= EOW,
         FISCAL_YEAR == fis_yr,
         !grepl("Liberty Distribution Company", Parent_Vendor, ignore.case = TRUE),
         !grepl("dummy", Parent_Vendor, ignore.case = TRUE),
         MetricShipDate <= SOT_Data_Pulled) %>% 
  droplevels()

SOT_Master_Unmeasured <- SOT_Master %>% 
  filter(!grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed=FALSE)) %>%
  filter(ShipCancelWeek <= EOW,
         FISCAL_YEAR == fis_yr,
         !grepl("Liberty Distribution Company", Parent_Vendor, ignore.case = TRUE),
         !grepl("dummy", Parent_Vendor, ignore.case = TRUE),
         Lateness == "Unmeasured") 

write_csv(SOT_Master_Unmeasured, path = paste(SOT_OTS_directory,  paste('SOT_Master_Unmeasured_WK', EOW, '_YTD.csv',sep = ""), sep = '/' ))
# Write out the cleaned master files ----
write_csv(SOT_Master, path = paste(SOT_OTS_directory,  'SOT_Master_clean.csv', sep = '/' ))
write_csv(OTS_Master, path = paste(SOT_OTS_directory,  'OTS_Master_clean.csv', sep = '/' ))

# Create/write Metadata for Week subset ----
SOT_Master_Summary_curr_week <- SOT_Master %>% filter(ShipCancelWeek ==EOW) %>% summary() %>% as.data.frame() 
OTS_Master_Summary_curr_week <- OTS_Master %>% filter(Week ==EOW) %>% summary() %>% as.data.frame() 

write_csv(as.data.frame(SOT_Master_Summary_curr_week), path = paste(SOT_OTS_directory,  paste('SOT_Master_Metadata_curr_week', EOW, '.csv',sep = ""), sep = '/' ))
write_csv(as.data.frame(OTS_Master_Summary_curr_week), path = paste(SOT_OTS_directory,  paste('OTS_Master_Metadata_curr_week', EOW, '.csv',sep = ""), sep = '/' ))

# Create Output Tables ----

# 1) OTS by Category Summary
OTS_by_Category <- OTS_Master %>%
  group_by(ReportingBrand, Category, Month_Number,Week, DC_NAME) %>%
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
write_csv(OTS_by_Category[, c(1:4, 6:10, 5, 11:15)], path = paste(SOT_OTS_directory,  'OTS_by_Category.csv', sep = '/' ))
write_csv(OTS_by_Vendor, path = paste(SOT_OTS_directory,  'OTS_by_Vendor.csv', sep = '/' ))

write_csv(SOT_by_Category, path = paste(SOT_OTS_directory,  'SOT_by_Category.csv', sep = '/' ))
write_csv(SOT_by_Vendor, path = paste(SOT_OTS_directory,  'SOT_by_Vendor.csv', sep = '/' ))

# YTD Masters
write_csv(SOT_Master, path = paste(SOT_OTS_directory,  paste('SOT_Master_WK', EOW, '_YTD.csv',sep = ""), sep = '/' ))
write_csv(OTS_Master, path = paste(SOT_OTS_directory,  paste('OTS_Master_WK', EOW, '_YTD.csv',sep = ""), sep = '/' ))

# 7 day Masters
write_csv(subset(SOT_Master, ShipCancelWeek == EOW), path = paste(SOT_OTS_directory,  paste('SOT_Master_WK', EOW, '.csv',sep = ""), sep = '/' ))
write_csv(subset(OTS_Master, Week == EOW), path = paste(SOT_OTS_directory,  paste('OTS_Master_WK', EOW, '.csv',sep = ""), sep = '/' ))

# Experimental section ----
# functions for Calculating SOT/OTS

OTS_percent <- function(OTUnits, TotalUnits){
  OTS <- OTUnits/TotalUnits
  round(OTS*100, digits = 1)
}

# Tables for Visuals

# On_Time_Stock_table <- OTS_Master %>% 
#   filter(OTS_Master$Week <= 30) %>%
#   summarise(OnTime_Units_sum =sum(OTS_Master$Units[OTS_Master$Lateness=="OnTime"]), 
#             Total_Units_sum=sum(OTS_Master$Units),
#             Measurable_Units_sum=sum(OTS_Master$Units[OTS_Master$Lateness!= "Unmeasurable"])) 

OTS_percent(On_Time_Stock_table$OnTime_Units_sum, On_Time_Stock_table$Measurable_Units_sum)
OTS_percent(On_Time_Stock_table$OnTime_Units_sum, On_Time_Stock_table$Total_Units_sum)

On_Time_Stock_table <- OTS_Master %>% 
  # filter(OTS_Master$Week <= 35) %>%
  group_by(Parent_Vendor, Month_Number,Week) %>%
  summarise(OnTime_Units_sum =sum(Units[Lateness=="OnTime"]), 
            Total_Units_sum=sum(Units),
            Measurable_Units_sum=sum(Units[Lateness!= "Unmeasurable"])) 

OTS_Percent_value <- mapply(OTS_percent, On_Time_Stock_table$OnTime_Units_sum, On_Time_Stock_table$Measurable_Units_sum)
On_Time_Stock_table <- as.data.frame(On_Time_Stock_table)
On_Time_Stock_table <- On_Time_Stock_table %>% mutate("OTS_Percent_value"= OTS_Percent_value)




# Experimental section
On_Time_Stock_table <- OTS_Master %>% 
  #filter(OTS_Master$Week <= 30) %>%
  group_by(Parent_Vendor, Month_Number,Week) %>%
  summarise(OnTime_Units_sum =sum(Units[Lateness=="OnTime"]),
            Late_Units_sum =sum(Units[Lateness=="Late"]),
            Total_Units_sum=sum(Units),
            Measurable_Units_sum=sum(Units[Lateness!= "Unmeasurable"])) %>% 
  mapply(OTS_percent, On_Time_Stock_table$OnTime_Units_sum, On_Time_Stock_table$Measurable_Units_sum)
            mutate("OTS_Percent_value"= as.data.frame(mapply(OTS_percent, On_Time_Stock_table$OnTime_Units_sum, On_Time_Stock_table$Measurable_Units_sum)))

# %>% 
 # mutate_each(mapply(OTS_percent, On_Time_Stock_table$OnTime_Units_sum, On_Time_Stock_table$Measurable_Units_sum) )

cbind(On_Time_Stock_table, OTS_Percent_value)
head(On_Time_Stock_table)

View(OTS_by_Category)
View(OTS_by_Vendor)
View(SOT_by_Category)
View(SOT_by_Vendor)


Trans_delay_reason <-  SOT_Master %>% select(ShipCancelWeek, SHP_RSN_TYP_DESC, Units) %>% 
  filter(SOT_Master$ShipCancelWeek == EOW) %>% 
  group_by(ShipCancelWeek, SHP_RSN_TYP_DESC) %>% 
  summarize("Delayed Units" = sum(Units, na.rm = TRUE)) %>% 
  arrange(desc(`Delayed Units`))

Trans_delay_reason <-  SOT_Master %>% 
  filter(SOT_Master$ShipCancelWeek == EOW) %>% 
  select(SHP_RSN_TYP_DESC, Units) %>% 
  group_by(SHP_RSN_TYP_DESC) %>%  
  plot(Trans_delay_reason$SHP_RSN_TYP_DESC, Trans_delay_reason$`Delayed Units`)


Trans_delay_reason_vis <-  SOT_Master %>%
  filter(SOT_Master$ShipCancelWeek == EOW) %>% 
  select(SHP_RSN_TYP_DESC, Units) %>% 
  group_by(SHP_RSN_TYP_DESC) %>%  
  ggvis(~SHP_RSN_TYP_DESC, ~`Units`)  guide_axis("y", subdivide = 1, values = seq(0, 2000000, by = 500000))  %>% 
  add_axis("x", title = "", properties = axis_props(labels = list(angle = 45, align = "left", fontSize = 9))) %>% 
  add_axis("y", title = "")
Trans_delay_reason_vis

Trans_delay_reason_vis2 <-  SOT_Master %>% 
  filter(SHP_RSN_TYP_DESC != "-") %>% 
  select(SHP_RSN_TYP_DESC, Units) %>% 
  group_by(SHP_RSN_TYP_DESC) %>%  
  ggvis(~SHP_RSN_TYP_DESC, ~`Units`) %>% 
  add_axis("x", title = "", properties = axis_props(labels = list(angle = 45, align = "left", fontSize = 9))) %>% 
  add_axis("y", title = "")

Trans_delay_reason_vis2
