library(RODBC)
library(yaml)
library(RJDBC)
library(glue)
library(lubridate)


# # For username and password ----
# if(!"credentials" %in% ls()){
#   path <- Sys.getenv("USERPROFILE")
#   credentials <- yaml.load_file(paste(path, "Desktop", "credentials.yml", sep = .Platform$file.sep))
# }

# Create RODBC connection ----
# my_connect <- odbcConnect(dsn= "IP EDWP", uid= credentials$my_uid, pwd= credentials$my_pwd)
# sqlTables(my_connect, catalog = "EDWP", tableName  = "tables")
# sqlQuery(my_connect, query = "SELECT  * from dbc.dbcinfo;")
drv <- JDBC("com.teradata.jdbc.TeraDriver", 
            "/mnt/Ke2l8b1/Resources/drivers/teradata/terajdbc4.jar:/mnt/Ke2l8b1/Resources/drivers/teradata/tdgssconfig.jar")

#drv=JDBC("com.teradata.jdbc.TeraDriver","C:\\TeraJDBC__indep_indep.16.10.00.05\\terajdbc4.jar;C:\\TeraJDBC__indep_indep.16.10.00.05\\tdgssconfig.jar")
my_connect = dbConnect(drv,
                       paste("jdbc:teradata://TDPRODCOP1.GID.GAP.COM/LOGMECH=LDAP,charset=UTF8,USER=",Sys.getenv("USERNAME"),",", "PASSWORD=",PASSWORD=Sys.getenv("PASSWORD"), sep = "")
)
dbGetQuery(my_connect, statement = "SELECT  * from dbc.dbcinfo;")

# my_query <- readLines('test_sql3.sql')

my_query <- readLines("https://github.gapinc.com/raw/SRAA/EDW_IUF/master/Create%20SRAA_SAND%20EDW_IUF_YTD%20Prod.sql")
# my_query <- readLines("Create SRAA_SAND EDW_IUF_YTD Prod_test.sql", warn = FALSE)
#sqlQuery(my_connect, query = readr::read_file('test_sql3.sql'))


start_date <- date(today()) - 379

while ((weekdays(start_date) != "Sunday")) {
  start_date <- start_date - 1
}
end_date <- date(today())

while ((weekdays(end_date) != "Saturday")) {
  end_date <- end_date - 1
}


my_query <- paste(my_query, collapse = "","")
my_query <- gsub("^\\s+|\\s+$", "", my_query) 
my_query <- gsub("\t", " ", my_query) 
my_query <- gsub("\n", " ", my_query) 
# my_query <- gsub(";\\*/", "\\*/;", my_query) 
my_query <- gsub("/\\*.*?\\*/", "", my_query) 
# my_query <- gsub("--", "-- \n", my_query)

# replace where statement that bounds the query
pattern = "where\\s*\\(\\s*\\(\\s*a11\\.SHIP_CANCEL_DATE\\s*between\\s*DATE\\s*'.*?'\\s*and\\s*CURRENT_DATE\\s*\\)\\s*or\\s*\\(\\s*a11\\.PLANNED_STOCKED_DATE\\s*between\\s*DATE\\s*'.*?'\\s*and\\s*CURRENT_DATE\\s*\\)\\s*\\)"
replacement = glue("where ((a11.SHIP_CANCEL_DATE between DATE '{start_date}' and CURRENT_DATE ) or (a11.PLANNED_STOCKED_DATE between DATE '{start_date}' and CURRENT_DATE ))")

my_query <- sub(pattern = pattern, 
                replacement = replacement, x = my_query)

my_query <- strsplit(my_query, split = ";")


iterate_sql <- function(list){
  
  dbSendUpdate(my_connect, list)
  return(list)
}

system.time(lapply(my_query[[1]], FUN = iterate_sql))

dbGetQuery(my_connect, statement = "SELECT data_pulled from SRAA_SAND.EDW_IUF_YTD sample 1;")
# dbGetQuery(my_connect, statement = "SELECT * from SRAA_SAND.EDW_IUF_YTD sample 1;")

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