library(dplyr)

Dest_cty <- OTS_Master %>% group_by(DestCtryCD, Lateness) %>% summarise(sum(Units))
View(Dest_cty)



options(java.parameters = "-Xmx2048m")
library(RJDBC)
library(DBI)
drv=JDBC("com.teradata.jdbc.TeraDriver","C:\\TeraJDBC__indep_indep.16.10.00.05\\terajdbc4.jar;C:\\TeraJDBC__indep_indep.16.10.00.05\\tdgssconfig.jar")
conn=dbConnect(drv,"jdbc:teradata://10.107.56.31/LOGMECH=LDAP",credentials$my_uid, credentials$my_pwd)
dbGetQuery(conn, statement = "SELECT  * from dbc.dbcinfo;")
gc() # Garbage collection (BASE)

# system.time(jdbc_fetch_test <- dbGetQuery(conn, "SELECT * FROM SRAA_SAND.VIEW_SOT_MASTER sample 100000;"))

gc()
dbDisconnect(conn)

jdbc_fetch_chunk_test <- dbSendQuery(conn, "SELECT * FROM SRAA_SAND.VIEW_SOT_MASTER")
dbHasCompleted(jdbc_fetch_chunk_test)
# n = 0
# while (n < 14) {
#   chunk_temp <- dbFetch(jdbc_fetch_chunk_test, 200000)
#   chunk <- rbind(chunk, chunk_temp)
#   n = n + 1
#   print(nrow(chunk))
# }

chunk <-  dbFetch(jdbc_fetch_chunk_test, 1)
length <- dbGetQuery(conn, "Select count(*) from SRAA_SAND.VIEW_SOT_MASTER")
system.time(while (!nrow(chunk) >= length) {
  chunk <- rbind(chunk, dbFetch(jdbc_fetch_chunk_test, 100000))
  gc()
  print(nrow(chunk))
})

# chunk = NULL
# for(x in seq_along(1:10)) {
#   chunk <- rbind(chunk, dbFetch(jdbc_fetch_chunk_test, 200000))
#   if(nrow(chunk) == 0){
#     break;
#   }
#   print(nrow(chunk))
# }

dbClearResult(jdbc_fetch_chunk_test)
dbDisconnect(conn)
