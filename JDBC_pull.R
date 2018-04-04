drv=JDBC("com.teradata.jdbc.TeraDriver","C:\\TeraJDBC__indep_indep.16.10.00.05\\terajdbc4.jar;C:\\TeraJDBC__indep_indep.16.10.00.05\\tdgssconfig.jar")
conn=dbConnect(drv,"jdbc:teradata://10.101.83.123/LOGMECH=LDAP",credentials$my_uid, credentials$my_pwd)
dbGetQuery(conn, statement = "SELECT  * from dbc.dbcinfo;")
gc() # Garbage collection (BASE)

jdbc_fetch <- dbSendQuery(conn, "SELECT * FROM SRAA_SAND.VIEW_SOT_MASTER sample 200000")

chunk <-  dbFetch(jdbc_fetch, 1)
chunk$Data_Pulled == Sys.Date()
# length <- dbGetQuery(conn, "Select count(*) from SRAA_SAND.VIEW_SOT_MASTER sample 200000")
length <- 200000
print(glue::glue("Fetching {length} records from SOT_Master_View"))
system.time(while (!nrow(chunk) >= length) {
  chunk <- rbind(chunk, dbFetch(jdbc_fetch, 100000))
  gc()
  print(glue::glue("Processed {nrow(chunk)} records"))
})

SOT_Master <- chunk
rm(chunk)
dbClearResult(jdbc_fetch)
gc()

jdbc_fetch <- dbSendQuery(conn, "SELECT * FROM SRAA_SAND.VIEW_OTS_MASTER sample 200000")

chunk <-  dbFetch(jdbc_fetch, 1)
chunk$Data_Pulled == Sys.Date()
# length <- dbGetQuery(conn, "Select count(*) from SRAA_SAND.VIEW_OTS_MASTER")
print(glue::glue("Fetching {length} records from OTS_Master_View"))
system.time(while (!nrow(chunk) >= length) {
  chunk <- rbind(chunk, dbFetch(jdbc_fetch, 100000))
  gc()
  print(glue::glue("Processed {nrow(chunk)} records"))
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

# SOT_Master[, c(6:7, 9:12, 41:43)] <- SOT_Master[, c(6:7, 9:12, 41:43)] %>% mutate_all(funs(as.Date(.)))
SOT_Master[ , c('Contract_Ship_Cancel','SHIP_CANCEL_DATE','MetricShipDate','ACTUAL_ORIGIN_CONSOL_LCL_DATE',
                'ACTUAL_LP_LCL_DATE','StockedDate','Data_Pulled','PLANNED_IN_DC_DATE','ACTUAL_IN_DC_LCL_DATE')] <- SOT_Master[ , c('Contract_Ship_Cancel','SHIP_CANCEL_DATE','MetricShipDate','ACTUAL_ORIGIN_CONSOL_LCL_DATE',
                                                                                                                                   'ACTUAL_LP_LCL_DATE','StockedDate','Data_Pulled','PLANNED_IN_DC_DATE','ACTUAL_IN_DC_LCL_DATE')]  %>% mutate_all(funs(as.Date(.)))
SOT_Master <- SOT_Master %>%
  mutate_all(funs(if(is.character(.)) as.factor(.) else .))

# OTS_Master[, c(7:11, 30:31, 33:34)] <- OTS_Master[, c(7:11, 30:31, 33:34)] %>% mutate_all(funs(as.Date(.)))
OTS_Master[, c('Contract_Ship_Cancel','cur_in_dc_dt','PLANNED_STOCKED_DATE','inDCDTe','StkdDte','SHIP_CANCEL_DATE','ACTUAL_LP_LCL_DATE','ACTUAL_IN_DC_LCL_DATE','Data_Pulled')] <- OTS_Master[, c('Contract_Ship_Cancel','cur_in_dc_dt','PLANNED_STOCKED_DATE','inDCDTe','StkdDte','SHIP_CANCEL_DATE','ACTUAL_LP_LCL_DATE','ACTUAL_IN_DC_LCL_DATE','Data_Pulled')] %>% mutate_all(funs(as.Date(.)))
# OTS_Master <- OTS_Master %>%
#   mutate_all(funs(if(is.character(.)) as.factor(.) else .))

# total_rows_SOT <- sqlQuery(my_connect, query = "select count(*) from SRAA_SAND.VIEW_SOT_MASTER; ")
# total_rows_OTS <- sqlQuery(my_connect, query = "select count(*) from SRAA_SAND.VIEW_OTS_MASTER; ")
# date_check <- sqlQuery(my_connect, query = "select Data_Pulled from SRAA_SAND.VIEW_SOT_MASTER sample 1;")
# max_stock_date <-  sqlQuery(my_connect, query = "select max(ACTUAL_STOCKED_LCL_DATE) as max_stocked_date from SRAA_SAND.EDW_IUF_YTD;")

date_check
max_stock_date