library(RODBC)
library(yaml)
library(RJDBC)

# For username and password ----
if(!"credentials" %in% ls()){
  path <- Sys.getenv("USERPROFILE")
  credentials <- yaml.load_file(paste(path, "Desktop", "credentials.yml", sep = .Platform$file.sep))
}

# Create RODBC connection ----
 my_connect <- odbcConnect(dsn= "IP EDWP", uid= credentials$my_uid, pwd= credentials$my_pwd)
# sqlTables(my_connect, catalog = "EDWP", tableName  = "tables")
 sqlQuery(my_connect, query = "SELECT  * from dbc.dbcinfo;")
 
 drv=JDBC("com.teradata.jdbc.TeraDriver","C:\\TeraJDBC__indep_indep.16.10.00.05\\terajdbc4.jar;C:\\TeraJDBC__indep_indep.16.10.00.05\\tdgssconfig.jar")
 my_connect=dbConnect(drv,"jdbc:teradata://10.101.83.123/LOGMECH=LDAP",credentials$my_uid, credentials$my_pwd)
 dbGetQuery(my_connect, statement = "SELECT  * from dbc.dbcinfo;")
 
 my_query <- readLines('test_sql3.sql')
 
 #my_query <- readLines("https://github.gapinc.com/raw/SRAA/EDW_IUF/master/Create%20SRAA_SAND%20EDW_IUF_YTD%20Prod.sql")
 my_query <- readLines("Create SRAA_SAND EDW_IUF_YTD Prod_test.sql", warn = FALSE)
 #sqlQuery(my_connect, query = readr::read_file('test_sql3.sql'))
 my_query <- paste(my_query, collapse = "","")
 my_query <- gsub("^\\s+|\\s+$", "", my_query) 
 my_query <- gsub("\t", " ", my_query) 
 my_query <- gsub("\n", " ", my_query) 
 my_query <- gsub(";\\*/", "\\*/;", my_query) 
 # my_query <- gsub("--", "-- \n", my_query) 
 my_query <- strsplit(my_query, split = ";")
 
       # my_query <- paste("BT; \n",
       #                  "create table SRAA_SAND.test2
       #                    (my_col1 integer,
       #                     my_col2 varchar(6));"
       #                  ,"ET; \n",
       #                  "BT; \n",   
       #                     "insert into SRAA_SAND.test2 (my_col1, my_col2)
       #                     values (6, 'chicks');
       #                     
       #                     insert into SRAA_SAND.test2 (my_col1, my_col2)
       #                     values (1, 'dog');", "BT; \n", sep= " " )
       # my_query <- paste("BT; \n",
       #                     "insert into SRAA_SAND.test2 (my_col1, my_col2)
       #                     values (6, 'chicks');
       #                     
       #                     insert into SRAA_SAND.test2 (my_col1, my_col2)
       #                     values (1, 'dog');", "ET; \n", sep= " " )
 

 iterate_sql <- function(list){
   
   dbSendUpdate(my_connect, list)
   return(list)
 }
 
system.time(lapply(my_query[[1]], FUN = iterate_sql))
 
 # my_query <- as.list(my_query[[1]][-1])
 # dbSendUpdate(my_connect, "DROP TABLE SRAA_SAND.EDW_IUF_YTD;")
 
 # for(i in length(my_query[[1]])){
 #   dbSendUpdate(my_connect, my_query[[1]][i])
 #    Sys.sleep(480)
 # }
 # 
 # # dbSendUpdate(my_connect, my_query[[1]][3])
 # 
 # sqlQuery(my_connect, my_query)
  
 dbDisconnect(my_connect)         
 