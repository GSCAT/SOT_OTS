Report_period <- function(We, Mo, Yr) {
  EOW <<- if(interactive()) as.integer(We)
  fis_yr <<- if(interactive()) as.integer(Yr)
  fis_month <<- as.integer(Mo)
}