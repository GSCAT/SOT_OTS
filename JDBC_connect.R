library(dplyr)

Dest_cty <- OTS_Master %>% group_by(DestCtryCD, Lateness) %>% summarise(sum(Units))
View(Dest_cty)



# options(java.parameters = "-Xmx2048m")
library(RJDBC)
library(DBI)
drv=JDBC("com.teradata.jdbc.TeraDriver","C:\\TeraJDBC__indep_indep.16.10.00.05\\terajdbc4.jar;C:\\TeraJDBC__indep_indep.16.10.00.05\\tdgssconfig.jar")
conn=dbConnect(drv,"jdbc:teradata://10.107.56.31/LOGMECH=LDAP",credentials$my_uid, credentials$my_pwd)
dbGetQuery(conn, statement = "SELECT  * from dbc.dbcinfo;")
gc() # Garbage collection (BASE)

# system.time(jdbc_fetch_test <- dbGetQuery(conn, "SELECT * FROM SRAA_SAND.VIEW_SOT_MASTER sample 100000;"))


jdbc_fetch <- dbSendQuery(conn, "SELECT * FROM SRAA_SAND.VIEW_SOT_MASTER")

chunk <-  dbFetch(jdbc_fetch, 1)
length <- dbGetQuery(conn, "Select count(*) from SRAA_SAND.VIEW_SOT_MASTER")
system.time(while (!nrow(chunk) >= length) {
  chunk <- rbind(chunk, dbFetch(jdbc_fetch, 100000))
  gc()
  print(nrow(chunk))
})

SOT_Master_JDBC <- chunk
rm(chunk)
dbClearResult(jdbc_fetch)
gc()

jdbc_fetch <- dbSendQuery(conn, "SELECT * FROM SRAA_SAND.VIEW_OTS_MASTER")

chunk <-  dbFetch(jdbc_fetch, 1)
length <- dbGetQuery(conn, "Select count(*) from SRAA_SAND.VIEW_OTS_MASTER")
system.time(while (!nrow(chunk) >= length) {
  chunk <- rbind(chunk, dbFetch(jdbc_fetch, 100000))
  gc()
  print(nrow(chunk))
})

OTS_Master_JDBC <- chunk
rm(chunk)
dbClearResult(jdbc_fetch)
gc()

# chunk = NULL
# for(x in seq_along(1:10)) {
#   chunk <- rbind(chunk, dbFetch(jdbc_fetch_chunk_test, 200000))
#   if(nrow(chunk) == 0){
#     break;
#   }
#   print(nrow(chunk))
# }

dbClearResult(jdbc_fetch)
gc()
dbDisconnect(conn)

save(SOT_Master, file = "SOT_Master_wk44.rds")
save(SOT_Master_JDBC, file = "SOT_Master_JDBC_wk44.rds")
save(OTS_Master, file = "OTS_Master_wk44.rds")
save(SOT_Master_JDBC, file = "OTS_Master_JDBC_wk44.rds")

