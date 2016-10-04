library(dplyr)
library(readr)
library(RSQLServer)
library(RODBC)
library(formattable)

# Create connection 
my_connect <- odbcConnect(dsn= "IP EDWP", uid= my_uid, pwd= my_pwd)
sqlTables(my_connect, catalog = "EDWP", tableName  = "tables")

path <- file.path( '~', 'SOT Weekly', '2016', 'Weekly', 'SOT_Master.R')

prompt_for_week <- function()
{ 
  n <- readline(prompt="Enter Week number: ")
  return(as.integer(n))
}

choose_file_directory <- function()
{
  v <- jchoose.dir()
  return(v)
}

SOT_OTS_directory <- choose_file_directory()

EOW <- prompt_for_week()

# Create SOT Master
SOT_Master <- sqlQuery(my_connect, 
                     query = "SELECT  * from SRAA_SAND.VIEW_SOT_MASTER;")

OTS_Master <- sqlQuery(my_connect, 
                           query = "SELECT  * from SRAA_SAND.VIEW_OTS_MASTER;")

write_csv(SOT_Master, path = paste(SOT_OTS_directory,  'SOT_Master_Raw.csv', sep = '/' ))
write_csv(OTS_Master, path = paste(SOT_OTS_directory,  'OTS_Master_Raw.csv', sep = '/' ))

OTS_Master <- OTS_Master %>% 
  filter(OTS_Master$Week <= EOW,
        !is.na(OTS_Master$DC_NAME),
        !grepl("Liberty Distribution Company", Parent_Vendor, ignore.case = TRUE),
        !grepl("dummy", Parent_Vendor, ignore.case = TRUE),
        !grepl("JPF", DC_NAME, ignore.case = TRUE)) 

SOT_Master <- SOT_Master %>% 
  filter(SOT_Master$ShipCancelWeek <= EOW,
         !grepl("Liberty Distribution Company", Parent_Vendor, ignore.case = TRUE),
         !grepl("dummy", Parent_Vendor, ignore.case = TRUE)) 

# Output tables

# 1) OTS by Category Summary
OTS_by_Category <- OTS_Master %>%
  filter(!grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed=FALSE)) %>%
  group_by(ReportingBrand, Category, Month_Number,Week, DC_NAME) %>%
  summarise(TotalUnits= sum(Units), 
            OnTimeUnits = sum(Units[Lateness=="OnTime"]), 
            LateUnits = sum(Units[Lateness=="Late"]), 
            WtDaysLate = sum(Units[Lateness=="Late"] * Days_Late[Lateness=="Late"]),
            DaysLate5 = sum(Units[Days_Late>5], na.rm = TRUE))%>%
  droplevels()

# 2) OTS by Vendor Summary
OTS_by_Vendor <- OTS_Master %>%
  filter(!grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed=FALSE)) %>%
  group_by(Vendor_Rank, Parent_Vendor, Month_Number,Week) %>%
  summarise(TotalUnits= sum(Units), 
            OnTimeUnits = sum(Units[Lateness=="OnTime"]), 
            LateUnits = sum(Units[Lateness=="Late"]), 
            WtDaysLate = sum(Units[Lateness=="Late"] * Days_Late[Lateness=="Late"]),
            DaysLate5 = sum(Units[Days_Late>5], na.rm = TRUE))%>%
  droplevels()


# 3) SOT by Category Summary
SOT_by_Category <- SOT_Master %>%
  filter(!grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed=FALSE)) %>%
  group_by(ReportingBrand, Category, ShipCancelMonth, ShipCancelWeek) %>%
  summarise(TotalUnits= sum(Units), 
            OnTimeUnits = sum(Units[Lateness=="OnTime"]), 
            LateUnits = sum(Units[Lateness=="Late"]), 
            WtDaysLate = sum(Units[Lateness=="Late"] * DAYS_LATE[Lateness=="Late"]),
            DaysLate5 = sum(Units[DAYS_LATE>5], na.rm = TRUE))%>%
  droplevels()

# 4) OTS by Vendor Summary
SOT_by_Vendor <- SOT_Master %>%
  filter(!grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed=FALSE)) %>%
  group_by(Vendor_Rank, Parent_Vendor, ShipCancelMonth, ShipCancelWeek) %>%
  summarise(TotalUnits= sum(Units), 
            OnTimeUnits = sum(Units[Lateness=="OnTime"]), 
            LateUnits = sum(Units[Lateness=="Late"]), 
            WtDaysLate = sum(Units[Lateness=="Late"] * DAYS_LATE[Lateness=="Late"]),
            DaysLate5 = sum(Units[DAYS_LATE>5], na.rm = TRUE))%>%
  droplevels()


# Output 
write_csv(OTS_by_Category[, c(1:4, 6:10, 5)], path = paste(SOT_OTS_directory,  'OTS_by_Category.csv', sep = '/' ))
write_csv(OTS_by_Vendor, path = paste(SOT_OTS_directory,  'OTS_by_Vendor.csv', sep = '/' ))

write_csv(SOT_by_Category, path = paste(SOT_OTS_directory,  'SOT_by_Category.csv', sep = '/' ))
write_csv(SOT_by_Vendor, path = paste(SOT_OTS_directory,  'SOT_by_Vendor.csv', sep = '/' ))

write_csv(SOT_Master, path = paste(SOT_OTS_directory,  paste('SOT_Master_WK', EOW, '.csv',sep = ""), sep = '/' ))
write_csv(OTS_Master, path = paste(SOT_OTS_directory,  paste('OTS_Master_WK', EOW, '.csv',sep = ""), sep = '/' ))

write_csv(SOT_Master, path = paste(SOT_OTS_directory ,  paste('SOT_Master_WK', EOW, '.csv',sep = ""), sep = '/' ))
write_csv(OTS_Master, path = paste(SOT_OTS_directory,  paste('OTS_Master_WK', EOW, '.csv',sep = ""), sep = '/' ))

# functions for Calculating SOT/OTS

OTS_percent <- function(OTUnits, TotalUnits){
  OTS <- OTUnits/TotalUnits
  round(OTS*100, digits = 1)
}

# Tables for Visuals
On_Time_Stock_table <- OTS_Master %>% 
  filter(OTS_Master$Week <= 30) %>%
  summarise(OnTime_Units_sum =sum(OTS_Master$Units[OTS_Master$Lateness=="OnTime"]), 
            Total_Units_sum=sum(OTS_Master$Units),
            Measurable_Units_sum=sum(OTS_Master$Units[OTS_Master$Lateness!= "Unmeasurable"])) 

OTS_percent(On_Time_Stock_table$OnTime_Units_sum, On_Time_Stock_table$Measurable_Units_sum)
OTS_percent(On_Time_Stock_table$OnTime_Units_sum, On_Time_Stock_table$Total_Units_sum)

On_Time_Stock_table <- OTS_Master %>% 
  #filter(OTS_Master$Week <= 30) %>%
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
            Measurable_Units_sum=sum(Units[Lateness!= "Unmeasurable"])) # %>% 
 # mutate_each(mapply(OTS_percent, On_Time_Stock_table$OnTime_Units_sum, On_Time_Stock_table$Measurable_Units_sum) )

cbind(On_Time_Stock_table, OTS_Percent_value)
head(On_Time_Stock_table)

View(OTS_by_Category)
View(OTS_by_Vendor)
View(SOT_by_Category)
View(SOT_by_Vendor)




