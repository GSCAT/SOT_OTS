# Install missing packages ----
list.of.packages <- c("dplyr", "readr", "RODBC", "formattable", 
                      "rJava", "rChoiceDialogs", "ggvis", "tidyr", 
                      "colorspace",  "mosaic", "yaml", "RJDBC", "DBI", "devtools")
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