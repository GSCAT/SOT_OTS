# To setup PATH for calling RScript.R form cmd example
# PATH C:\Programme\R\R-3.0.1\bin;%path%
library(lubridate)
start_date <- date(today()) - 379

while ((weekdays(start_date) != "Sunday")) {
  start_date <- start_date - 1
}
end_date <- date(today())

while ((weekdays(end_date) != "Saturday")) {
  end_date <- end_date - 1
}



source("Setup.R")
# User defined function test(Week, Month, Yr) ----
Report_period(6, 2, 2018)
# preferred method of pulling data is via JDBC ----
source("JDBC_pull.R")
