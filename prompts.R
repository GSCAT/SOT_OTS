# Setup Environment Variables/Functions ----
prompt_for_week <- function()
{ 
  n <- readline(prompt="Enter Week number: ")
  
  return(as.integer(n))
}

prompt_for_year <- function()
{ 
  n <- readline(prompt="Enter Fiscal Year as YYYY: ")
  return(as.integer(n))
}

prompt_for_month <- function()
{
  n <- readline(prompt="Enter Fiscal Month number (i.e. Feb = 1): ")
  return(as.integer(n))
}

choose_file_directory <- function()
{
  v <- jchoose.dir()
  return(v)
}


SOT_OTS_directory <- if(interactive()) choose_file_directory()

EOW <-   if(interactive()) prompt_for_week()
fis_yr <- if(interactive()) prompt_for_year()
fis_month <- prompt_for_month()
