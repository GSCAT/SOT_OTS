library(RODBC)

# Connect to Access db
# channel <- odbcConnectAccess2007("G:\\SF-LOGISTICS_METRICS\\Dashboards\\Databases\\IB Databases\\IB_Daily_2018.accdb", Driver='{Microsoft Access Driver (*.mdb, *.accdb)}')
###############################################################################################
####### MUST install Microsoft Access Database Engine for 64 bit if running 64 bit R ##########
###############################################################################################
channel <- odbcDriverConnect("Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=\\\\Americas\\sf\\SF-LOGISTICS_METRICS\\Dashboards\\Databases\\IB Databases\\IB_Daily_2018.accdb")
#Transportation_Daily_IB <- sqlQuery( channel , "select [Purchase Order Number], [PO Type], [Container Number1], [BL/AWB#1], [Vessel], [InDC Calc Method], [INDC], [INDC+2], [Total Shipped Qty] from Daily_Tracker_2_0")
Transportation_Daily_IB <- sqlQuery( channel , "select [Purchase Order Number], [PO Type], [Mode1], [Mode2], [Container Number1], [BL/AWB#1], [Vessel], [Planned Stocked Date], [Full Out Gate from Ocean Terminal (CY or Port) Actual Date (LT)], [InDC Calc Method], [DayDiff], [INDC], [INDC+2], [Total Shipped Qty] from Daily_Tracker_2_0")
close(channel)

channel <- odbcDriverConnect("Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=\\\\Americas\\sf\\SF-LOGISTICS_METRICS\\Dashboards\\Databases\\IB Databases\\Monthly\\IB_Monthly_2018.accdb")
Transportation_Month_IB <- sqlQuery( channel , "select [Purchase Order Number], [PO Type], [Mode1], [Mode2], [Container Number1], [BL/AWB#1], [Vessel], [Planned Stocked Date], [Full Out Gate from Ocean Terminal (CY or Port) Actual Date (LT)], [InDC Calc Method], [DayDiff], [INDC], [INDC+2], [Total Shipped Qty] from IB_Summary;")
close(channel)

Transportation_data_combine <- rbind(Transportation_Daily_IB, Transportation_Month_IB)

rm(list= c("Transportation_Daily_IB", "Transportation_Month_IB"))
