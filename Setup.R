# Install missing packages ----
list.of.packages <- c("dplyr", "readr", "RODBC", "formattable", 
                      "rJava", "rChoiceDialogs", "ggvis", "tidyr", 
                      "colorspace",  "mosaic", "yaml", "RJDBC", "DBI", "devtools", "lubridate", "glue")
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
library(devtools)
library(glue)

# Start with clean environment ----
# rm(list = ls())

# # create functions and prompt for environment variables ----
# SOT_set_env <- function(){
#   source("prompts.R")
# }

# For username and password ----
if(!"credentials" %in% ls()){
  path <- Sys.getenv("USERPROFILE")
  credentials <- yaml.load_file(paste(path, "Desktop", "credentials.yml", sep = .Platform$file.sep))
}

#Function for passing Week, Month, Year to Global environment ----
Report_period <- function(We, Mo, Yr) {
  EOW <<- if(interactive()) as.integer(We)
  fis_yr <<- if(interactive()) as.integer(Yr)
  fis_month <<- as.integer(Mo)
}


fiscal_conv <- function(dt){
  
  date_align = week(dt) - 4
  month_num <- case_when(
    date_align %in% c(1:4) ~ as.integer(1),
    date_align %in% c(5:9) ~ as.integer(2),
    date_align %in% c(10:13) ~ as.integer(3),
    date_align %in% c(14:17) ~ as.integer(4),
    date_align %in% c(18:22) ~ as.integer(5),
    date_align %in% c(23:26) ~ as.integer(6),
    date_align %in% c(27:30) ~ as.integer(7),
    date_align %in% c(31:35) ~ as.integer(8),
    date_align %in% c(36:39) ~ as.integer(9),
    date_align %in% c(40:43) ~ as.integer(10),
    date_align %in% c(44:48) ~ as.integer(11),
    date_align %in% c(49:53) ~ as.integer(12))
  month_name <- month(month_num, label = TRUE, abbr = FALSE)
  year_num <- case_when(date_align %in% c(1:4) ~ year(dt) - 1, 
                        date_align %in% c(5:53) ~ year(dt))

  
  return(list(fis_month_number = month_num, fis_month_name = month_name, fis_year_num = year_num))
}

year_52 <- rep(1:53, each = 7, len = 364)
year_53 <- rep(1:53, each = 7, len = 371)

Fiscal_cal <- data.frame("Fiscal_Date" = seq.Date(from = as.Date("2017-01-29"), to = as.Date("2020-02-01"), by = "1 day"),
                     "Fiscal_Week" = c(year_53, year_52, year_52))


function (x, with_year = FALSE) 
{
  m <- month(x)
  quarters <- rep(1:4, each = 3)
  q <- quarters[m]
  if (with_year) 
    year(x) + q/10
  else q
}


# If Feb 1st is a Monday, Tuesday, or Wednesday, then first day of FY is last Sunday of January.
# If Feb 1st is a Thursday, Friday, Saturday, or Sunday, then first day of FY is first Sunday of February.

function (x) 
{
  year_52 <- rep(1:53, each = 7, len = 364)
  year_53 <- rep(1:53, each = 7, len = 371)

  y <- year(x)
  if (leap_year(x)) 
    year_53[y]
  else q
}

end_date <- "2017-04-01"

fiscal_454 <- function (a_date)
{
  y = year(a_date)
  # cat(y)
  Feb1st = as.Date(glue("{y}-02-01"))
  Sunday1 = Feb1st
  week_day = as.character(wday(Feb1st, label = TRUE, abbr = TRUE))
  cat(week_day)
  
  if (week_day %in% c("Mon", "Tues", "Wed")) {
    # cat("Is it Wed? ", week_day == c("Wed"))
     while (week_day != "Sun") {
       week_day = as.character(wday(Sunday1 - 1, label = TRUE, abbr = TRUE))
       Sunday1 = Sunday1 - 1
      cat("First Sunday is ", Sunday1)
    # last Sunday in January is first day of year
    }
   }
    else if(week_day %in% c("Thu", "Fri", "Sat")){
  #     # First Sunday in February 
  while (week_day != "Sun") {
    week_day = as.character(wday(Sunday1 + 1, label = TRUE, abbr = TRUE))
    Sunday1 = Sunday1 + 1
    cat("First Sunday is ", Sunday1)
  } 
    }
  else {}
  return(Sunday1)
}



