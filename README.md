SOT/OTS Weekly Process
================

-   [Initial Steps to Setup (First time)](#initial-steps-to-setup-first-time)
    -   [Set up GIT so you can run the SOT OTS Project from R Studio](#set-up-git-so-you-can-run-the-sot-ots-project-from-r-studio)
    -   [Create Yaml File for Credential Handling](#create-yaml-file-for-credential-handling)
    -   [Set up ODBC for Teradata](#set-up-odbc-for-teradata)
-   [WEEKLY PROCESS STARTS HERE - WEDNESDAY](#weekly-process-starts-here---wednesday)
    -   [Open Teradata](#open-teradata)
    -   [Open R Studio from your local Git Repository](#open-r-studio-from-your-local-git-repository)
    -   [Open SOT\_Master.R script](#open-sot_master.r-script)
    -   [Excel File](#excel-file)
    -   [Copying Data to Excel](#copying-data-to-excel)
    -   [LPvsOC.R](#lpvsoc.r)
    -   [Parent\_vendor\_Output.R](#parent_vendor_output.r)
    -   [SOT Impact PDF](#sot-impact-pdf)
    -   [Create PDF for Leadership group - Wednesday email](#create-pdf-for-leadership-group---wednesday-email)
-   [Thursday Steps](#thursday-steps)
    -   [Create PDF for Thursday Publish](#create-pdf-for-thursday-publish)
    -   [Copy Files to Box](#copy-files-to-box)
    -   [Send Emails](#send-emails)
-   [Appendix](#appendix)
    -   [SOT\_Master.R](#sot_master.r)
        -   [Set up Environment](#set-up-environment)
        -   [Pulling Data](#pulling-data)
        -   [Check the date of Data Refresh in EDW](#check-the-date-of-data-refresh-in-edw)
        -   [Generate Metadata](#generate-metadata)
        -   [Save Binary Objects](#save-binary-objects)
        -   [Clean-up Unwanted Records](#clean-up-unwanted-records)
        -   [Summary Statistics](#summary-statistics)
        -   [Building the Output Tables](#building-the-output-tables)
        -   [Output Files](#output-files)
    -   [LPvsOC.R](#lpvsoc.r-1)
        -   [Read in Latest TTP file](#read-in-latest-ttp-file)

### Initial Steps to Setup (First time)

------------------------------------------------------------------------

#### Set up GIT so you can run the SOT OTS Project from R Studio

-   Fork or Clone GitHub repository <https://github.gapinc.com/SRAA/SOTC_OTS_Weekly>
    -   All files are in the above repo
    -   Create project with the above repo
-   Ask Kevin or Vineela for help if needed

#### Create Yaml File for Credential Handling

-   Text file (.yml) on desk top with this information
    -   my\_uid: "your ID"
    -   my\_pwd: "your Password"

#### Set up ODBC for Teradata

1.  Go to control panel &gt; Data Sources(ODBC)
2.  Click Add button
3.  click on Teradata click finish
4.  Add this information to this field, enter user name and PW click ok.
    -   ODBC - IP EDWP
    -   Description : Teradata
    -   Name or IP Address: 10.107.56.31
    -   Mechanism: LDAP

### WEEKLY PROCESS STARTS HERE - WEDNESDAY

------------------------------------------------------------------------

We need to run code in Teradata before doing anything in R Studio. This is to drop and recreate a fresh table from which to pull data from.

#### Open Teradata

1.  From GITHUB for Gap enterprise <https://github.gapinc.com/SRAA>
2.  Go to SRAA/EDW\_IUF folder
3.  Copy code called SRAA\_SAND EDW\_IUF\_YTD Prod.sql
4.  Paste into Teradata after loggin in
5.  Run code and close teradata

#### Open R Studio from your local Git Repository

From R Studio we run 3 .R scripts. These scripts contain all the code needed to output the csv files we need to generate.

1.  Click on SOT OTS R Project button

##### List of Files to Run

-   *SOT\_Master.R*
-   *LPvsOC.R*
-   *Parent\_Vendor\_outputs.R*

#### Open SOT\_Master.R script

###### From R Studio - open SOT\_Master.R script

1.  Run the first part of the code until the comment row "\# Type SOT\_set\_env() in the Console after running the above code ----"
2.  Type SOT\_set\_env() in the console
3.  Dialog box opens - create folder for where you want to dump the data files - click open
4.  Next Enter the previous week \# in the console - enter
5.  Enter the Year \# - enter
6.  Run the rest of the code - takes about an hour.

#### Excel File

##### Copy a version of the excel report file to the folder just created in R (the one to which you navigated in the previous step)

1.  File name similar to "On Time % Metric Report xxx.xx.xx (FS xx Week xx YTD) w OTS\_Impact
2.  Rename x's to this week

#### Copying Data to Excel

Next we copy paste data from the csv files (created in R) into the excel

1.  Open On Time % report
2.  Go to Master Tab
3.  Delete all data (from row 11 down)from the Summary sections of this report
    -   OTS by Category Summary
    -   OTS by Vendor Summary
    -   SOT by Category Summary
    -   SOT by Vendor Summary

4.  In the Folder we created their are four excel files that were created that we will paste to the area that we just deleted
    -   OTS by Category Summary -&gt; OTS\_by\_Category
    -   OTS by Vendor Summary -&gt; OTS\_by\_Vendor
    -   SOT by Category Summary -&gt; SOT\_by\_Category
    -   SOT by Vendor Summary -&gt; SOT\_by\_Vendor
    -   On the Master tab click the Refresh Pivot Tables button - a macro that refreshes all pivots
    -   Change Week \# (previous week number) and date as of \# (todays date)

#### LPvsOC.R

From R Studio - open LPvsOC.R script

1.  Run script - I run one line at a line to make sure each line runs

#### Parent\_vendor\_Output.R

From R Studio - open Parent\_vendor\_Output.R

1.  Run script - I run one line at a line to make sure each line runs

#### SOT Impact PDF

The two scripts described above write csv files to a folder called "Impact\_files" in the saved directory. These data needto be copied to the report in the "SOT Impact" tab in Excel. This is a copy paste excercise. The files that say YTD are copied to the right side of the report, the non YTD are the week files, so they go on the left.

-   Trans Output - Rows 12 to 21
-   Trans Output Category - Rows 23 - 30
-   Trans Output Vendor - rows 42 down
-   Trans output Gap Inc - row 10
-   Align columns that you are copying
    -   For category sections, make sure you get the right columns
    -   Category column is not copied over
-   Now that everything is updated - do a sanity check between the **SOT-OTS Brand & Category** tab in this report to make sure the %s match, etc.

#### Create PDF for Leadership group - Wednesday email

-   Save PDF of the following tab
    -   SOT Impact Tab -&gt; SOTC Impact adhoc Wk \#\#.pdf

### Thursday Steps

#### Create PDF for Thursday Publish

-   Create PDFs by saving the following tabs
    -   SOT-OTS Brand & Category Exec -&gt; SOTC Executive Summary Wk \#\#.pdf
    -   SOT-OTS Brand & Category Trend -&gt; SOTC Trend Summary Wk \#\#.pdf
    -   Green and Orange tabs - SOTC Appendix Wk \#\#.pdf

#### Copy Files to Box

Copy these three files to box for sharing purposes

1.  Box Location: SOT OTS files
2.  Files copied
    -   SOT\_Master\_Unmeasured\_Wk\#\#\_YTD
    -   OTS\_Master\_clean
    -   SOT\_Master\_clean

3.  Box Location: Lateness Impact Raw Data
    -   SOT\_Master\_Impact\_adhoc.csv
    
#### Copy to FTP site
- Copy SOT_Master_clean.csv and OTS_Master_clean.csv to:
[ftp://ftp.gap.com/data/to_hq/SupplyChainReporting/OTS_SOT%20Raw%20Data/](ftp://ftp.gap.com/data/to_hq/SupplyChainReporting/OTS_SOT%20Raw%20Data/)
#### Send Emails

-   The Impact adhoc is sent out to a small distro on Wednesdays with some notes
-   The rest are sent out on Thursdays to 2 distros

*E-mail notes*:

-   Thursday e-mail to large group
    -   SOT Summary and OTS Summary \#s - comes from our excel report
    -   Vendor lateness impact - comes from Global tranpsoration weekly update file. Vendor delay line report sent by Brandon Purdy
    -   Transporation Performance - comes from e-mail from Tim Hemmert or Brandon Purdy
    -   DC Performance - comes from e-mail from Rick Ollman

------------------------------------------------------------------------

------------------------------------------------------------------------

Appendix
--------

Below is detail code in each file

### SOT\_Master.R

``` r
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
```

After loading the required libraries, create a connection to EDWP using the *RODBC* library. Once you have stored your username and password as ***my\_uid*** and ***my\_pwd*** in a file named ***credentials.yml*** on your Desktop. You will also need to create a DSN, in order to connect with the database. Then verify that we have successfully connected by performing a query on the dbcinfo table.

<br>

#### Set up Environment

After insuring that we are starting from a clean environment,and added a few functions, type ***SOT\_set\_env()*** in the console.

``` r
SOT_set_env()
```

You will be prompted to enter the paramaters to be stored as environment variables and used in the following code. First you should see a file chooser like so: <br>

![](https://github.com/kwbonds/SOT_OTS/blob/master/Markdown/choose_file_directory.PNG) <br> Navigate to the directory where you want to store this weeks master data and files and choose open. This will store the path as a string.

Now enter the week for which you are reporting. This will prompt you at the console.

<br>

Now create a connection to pull in the data from EDW. Be sure to represh the EDW table if necessary. First read in the *credentials.yml* file.

``` r
# For username and password ----
if(!"credentials" %in% ls()){
  path <- Sys.getenv("USERPROFILE")
  credentials <- yaml.load_file(paste(path, "Desktop", "credentials.yml", sep = .Platform$file.sep))
}
```

and test that you have connected.

``` r
# Create RODBC connection ----
my_connect <- odbcConnect(dsn= "IP EDWP", uid= credentials$my_uid, pwd= credentials$my_pwd)
# sqlTables(my_connect, catalog = "EDWP", tableName  = "tables")
sqlQuery(my_connect, query = "SELECT  * from dbc.dbcinfo;")
```

    ##                 InfoKey    InfoData
    ## 1               VERSION 14.10.07.10
    ## 2               RELEASE 14.10.07.09
    ## 3 LANGUAGE SUPPORT MODE    Standard

<br> Now that we have a connection, let's store a few variables for QA later on.

``` r
total_rows_SOT <- sqlQuery(my_connect, query = "select count(*) from SRAA_SAND.VIEW_SOT_MASTER; ")
total_rows_OTS <- sqlQuery(my_connect, query = "select count(*) from SRAA_SAND.VIEW_OTS_MASTER; ")
date_check <- sqlQuery(my_connect, query = "select Data_Pulled from SRAA_SAND.VIEW_SOT_MASTER sample 1;")
max_stock_date <-  sqlQuery(my_connect, query = "select max(ACTUAL_STOCKED_LCL_DATE) as max_stocked_date from SRAA_SAND.EDW_IUF_YTD;")

total_rows_SOT
```

    ##   Count(*)
    ## 1  1181886

``` r
total_rows_OTS
```

    ##   Count(*)
    ## 1  1181886

``` r
date_check
```

    ##   Data_Pulled
    ## 1  2017-10-11

``` r
max_stock_date
```

    ##   max_stocked_date
    ## 1       2017-10-11

#### Pulling Data

All tables are built from two *Master* tables. We need to create them now via query to EDW.

``` r
# Create Master Objects ----
SOT_Master <- sqlQuery(my_connect, 
                     query = "SELECT  * from SRAA_SAND.VIEW_SOT_MASTER;")

OTS_Master <- sqlQuery(my_connect, 
                           query = "SELECT  * from SRAA_SAND.VIEW_OTS_MASTER;")
```

<br> Close the connection:

``` r
# Close connection ----
close(my_connect)
```

#### Check the date of Data Refresh in EDW

<br> The tables, we just created, have a field labeled *Data\_Pulled* that is populated during *CREATE TABLE* in Teradata. It indicates when the data was pulled from the IUF tables. Let's store the first value from each table for reference.

``` r
SOT_Data_Pulled <- SOT_Master$Data_Pulled[1]
OTS_Data_Pulled <- OTS_Master$Data_Pulled[1]

SOT_Data_Pulled
```

    ## [1] "2017-10-04"

``` r
OTS_Data_Pulled
```

    ## [1] "2017-10-04"

<br>

#### Generate Metadata

<br>

Let's now create and store some Metadata about our raw data frames...

``` r
# Create/write Summary Metadata ----
SOT_Master_Summary <- as.data.frame(summary(SOT_Master))
OTS_Master_Summary <- as.data.frame(summary(OTS_Master))


write_csv(SOT_Master_Summary, path = paste(
  SOT_OTS_directory,
  paste('SOT_Master_RAW_Metadata_WK', EOW, '.csv', sep = ""),
  sep = '/'
  ))
  write_csv(OTS_Master_Summary, path = paste(
  SOT_OTS_directory,
  paste('OTS_Master_RAW_Metadata_WK', EOW, '.csv', sep = ""),
  sep = '/'
  ))
```

...and also write our masters to .csv.

``` r
# Write Raw files to .csv ----
write_csv(SOT_Master, path = paste(SOT_OTS_directory,  'SOT_Master_Raw.csv', sep = '/' ))
write_csv(OTS_Master, path = paste(SOT_OTS_directory,  'OTS_Master_Raw.csv', sep = '/' ))
```

<br>

#### Save Binary Objects

Now let's save the Raw objects. These will be saved as binary files that can be quickly loaded into R. This will allow us to reproduce our results, at any time, using the same raw data.

``` r
# Save Raw objects ----
save(
SOT_Master,
file = paste(SOT_OTS_directory,  'SOT_Master_object.rtf', sep = .Platform$file.sep)
)
save(
OTS_Master,
file = paste(SOT_OTS_directory,  'OTS_Master_object.rtf', sep = .Platform$file.sep)
)
```

<br>

#### Clean-up Unwanted Records

We usually don't include all vendors (i.e. non-apparel); nor do we include the virtual DC (JPF). Clean them up with the below.

``` r
# Scrub Noise from Master Objects ----
OTS_Master <- OTS_Master %>% 
  filter(OTS_Master$Week <= EOW,
        !is.na(OTS_Master$DC_NAME),
        !grepl("Liberty Distribution Company", Parent_Vendor, ignore.case = TRUE),
        !grepl("dummy", Parent_Vendor, ignore.case = TRUE),
        !grepl("JPF", DC_NAME, ignore.case = TRUE)) 

SOT_Master <- SOT_Master %>% 
  filter(SOT_Master$ShipCancelWeek <= EOW,
         !grepl("Liberty Distribution Company", Parent_Vendor, ignore.case = TRUE),
         !grepl("dummy", Parent_Vendor, ignore.case = TRUE),
         MetricShipDate <= SOT_Data_Pulled) 
```

<br>

#### Summary Statistics

Let's also create summary statistics for the current week and write it to csv for EDA purposes.

``` r
# Create/write Metadata for Week subset ----
SOT_Master_Summary_curr_week <-
  SOT_Master %>% filter(ShipCancelWeek == EOW) %>% summary() %>% as.data.frame()

OTS_Master_Summary_curr_week <-
  OTS_Master %>% filter(Week == EOW) %>% summary() %>% as.data.frame()

write_csv(
  as.data.frame(SOT_Master_Summary_curr_week),
  path = paste(
    SOT_OTS_directory,
    paste('SOT_Master_Metadata_curr_week', EOW, '.csv', sep = ""),
    sep = '/'))

write_csv(
  as.data.frame(OTS_Master_Summary_curr_week),
  path = paste(
    SOT_OTS_directory,
    paste('OTS_Master_Metadata_curr_week', EOW, '.csv', sep = ""),
    sep = '/'))
```

<br>

#### Building the Output Tables

<br> We need to build 4 tables for output to the presentation layer. We need both a Category and Vendor view (for OTS and SOT), and need to create some new summary columns.

``` r
# Create Output Tables ----

# 1) OTS by Category Summary
OTS_by_Category <- OTS_Master %>%
  filter(!grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed=FALSE)) %>%
  group_by(ReportingBrand, Category, Month_Number,Week, DC_NAME) %>%
  summarise(TotalUnits= sum(Units), 
            OnTimeUnits = sum(Units[Lateness == "OnTime"]),
            LateUnits = sum(Units[Lateness == "Late"]),
            WtDaysLate = sum(Units[Lateness == "Late"] * Days_Late[Lateness ==
            "Late"]),
            DaysLate5 = sum(Units[Days_Late > 5 &
            Lateness == "Late"]),
            UnitsArriveLessThanNeg5 = sum(Units[(Lateness == "OnTime" |
            Lateness == "Late") & (Days_Late <= -5)]),
            UnitsArriveLessThanNeg3 = sum(Units[(Lateness == "OnTime" |
            Lateness == "Late") & (Days_Late <= -3)]),
            UnitsArriveLessThan0 = sum(Units[(Lateness == "OnTime" |
            Lateness == "Late") & (Days_Late <= 0)]),
            UnitsArriveLessThan3 = sum(Units[(Lateness == "OnTime" |
            Lateness == "Late") & (Days_Late <= 3)]),
            UnitsArriveLessThan5 = sum(Units[(Lateness == "OnTime" |
            Lateness == "Late") & (Days_Late <= 5)])) %>% 
  droplevels()

# 2) OTS by Vendor Summary
OTS_by_Vendor <- OTS_Master %>%
  filter(!grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed = FALSE)) %>%
  group_by(Vendor_Rank, Parent_Vendor, Month_Number, Week) %>%
  summarise(
  TotalUnits = sum(Units),
  OnTimeUnits = sum(Units[Lateness == "OnTime"]),
  LateUnits = sum(Units[Lateness == "Late"]),
  WtDaysLate = sum(Units[Lateness == "Late"] * Days_Late[Lateness == "Late"]),
  DaysLate5 = sum(Units[Days_Late > 5 &
  Lateness == "Late"]),
  UnitsArriveLessThanNeg5 = sum(Units[(Lateness == "OnTime" |
  Lateness == "Late") & (Days_Late <= -5)]),
  UnitsArriveLessThanNeg3 = sum(Units[(Lateness == "OnTime" |
  Lateness == "Late") & (Days_Late <= -3)]),
  UnitsArriveLessThan0 = sum(Units[(Lateness == "OnTime" |
  Lateness == "Late") & (Days_Late <= 0)]),
  UnitsArriveLessThan3 = sum(Units[(Lateness == "OnTime" |
  Lateness == "Late") & (Days_Late <= 3)]),
  UnitsArriveLessThan5 = sum(Units[(Lateness == "OnTime" |
  Lateness == "Late") & (Days_Late <= 5)])
  ) %>%
  droplevels()


# 3) SOT by Category Summary
SOT_by_Category <- SOT_Master %>%
  filter(!grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed = FALSE)) %>%
  group_by(ReportingBrand, Category, ShipCancelMonth, ShipCancelWeek) %>%
  summarise(
  TotalUnits = sum(Units),
  OnTimeUnits = sum(Units[Lateness == "OnTime"]),
  LateUnits = sum(Units[Lateness == "Late"]),
  WtDaysLate = sum(Units[Lateness == "Late"] * DAYS_LATE[Lateness ==
  "Late"]),
  DaysLate5 = sum(Units[DAYS_LATE > 5], na.rm = TRUE),
  UnitsArriveLessThanNeg5 = sum(Units[Lateness == "OnTime" &
  DAYS_LATE <= -5]),
  UnitsArriveLessThanNeg3 = sum(Units[Lateness == "OnTime" &
  DAYS_LATE <= -2]),
  UnitsArriveLessThan0 = sum(Units[Lateness == "OnTime" &
  DAYS_LATE <= 0]),
  UnitsArriveLessThan3 = sum(Units[(Lateness == "OnTime" |
  Lateness == "Late") & DAYS_LATE <= 2]),
  UnitsArriveLessThan5 = sum(Units[(Lateness == "OnTime" |
  Lateness == "Late") & DAYS_LATE <= 5])
  ) %>%
  droplevels()

# 4) SOT by Vendor Summary
SOT_by_Vendor <- SOT_Master %>%
  filter(!grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed = FALSE)) %>%
  group_by(Vendor_Rank, Parent_Vendor, ShipCancelMonth, ShipCancelWeek) %>%
  summarise(
  TotalUnits = sum(Units),
  OnTimeUnits = sum(Units[Lateness == "OnTime"]),
  LateUnits = sum(Units[Lateness == "Late"]),
  WtDaysLate = sum(Units[Lateness == "Late"] * DAYS_LATE[Lateness ==
  "Late"]),
  DaysLate5 = sum(Units[DAYS_LATE > 5], na.rm = TRUE),
  UnitsArriveLessThanNeg5 = sum(Units[Lateness == "OnTime" &
  DAYS_LATE <= -5]),
  UnitsArriveLessThanNeg3 = sum(Units[Lateness == "OnTime" &
  DAYS_LATE <= -2]),
  UnitsArriveLessThan0 = sum(Units[Lateness == "OnTime" &
  DAYS_LATE <= 0]),
  UnitsArriveLessThan3 = sum(Units[(Lateness == "OnTime" |
  Lateness == "Late") & DAYS_LATE <= 2]),
  UnitsArriveLessThan5 = sum(Units[(Lateness == "OnTime" |
  Lateness == "Late") & DAYS_LATE <= 5])
  ) %>%
  droplevels()
```

<br>

#### Output Files

<br>

Lastly, Let's output the data frames we created to csv so that we can use the presentation tool of our choice.

``` r
# Output Tables to .csv ----
write_csv(OTS_by_Category[, c(1:4, 6:10, 5, 11:15)],
          path = paste(SOT_OTS_directory,  'OTS_by_Category.csv', sep = '/'))

write_csv(OTS_by_Vendor,
          path = paste(SOT_OTS_directory,  'OTS_by_Vendor.csv', sep = '/'))

write_csv(SOT_by_Category,
          path = paste(SOT_OTS_directory,  'SOT_by_Category.csv', sep = '/'))
write_csv(SOT_by_Vendor,
          path = paste(SOT_OTS_directory,  'SOT_by_Vendor.csv', sep = '/'))

# YTD Masters
write_csv(SOT_Master, path = paste(
  SOT_OTS_directory,
  paste('SOT_Master_WK', EOW, '_YTD.csv', sep = ""),
  sep = '/'))

write_csv(OTS_Master, path = paste(
  SOT_OTS_directory,
  paste('OTS_Master_WK', EOW, '_YTD.csv', sep = ""),
  sep = '/'))

# 7 day Masters
write_csv(subset(SOT_Master, ShipCancelWeek == EOW), path = paste(
  SOT_OTS_directory,
  paste('SOT_Master_WK', EOW, '.csv', sep = ""),
  sep = '/'))

write_csv(subset(OTS_Master, Week == EOW), path = paste(
  SOT_OTS_directory,
  paste('OTS_Master_WK', EOW, '.csv', sep = ""),
  sep = '/'))
```

### LPvsOC.R

You will need to install a few more packages.

``` r
# Install any missing packages 
list.of.packages <- c("readxl", "xlsx", "plotly", "tidyr", "mosaic")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)


library(readxl)
library(xlsx)
```

    ## Loading required package: xlsxjars

``` r
library(plotly)
```

    ## 
    ## Attaching package: 'plotly'

    ## The following object is masked from 'package:mosaic':
    ## 
    ##     do

    ## The following object is masked from 'package:ggplot2':
    ## 
    ##     last_plot

    ## The following objects are masked from 'package:ggvis':
    ## 
    ##     add_data, hide_legend

    ## The following object is masked from 'package:formattable':
    ## 
    ##     style

    ## The following object is masked from 'package:stats':
    ## 
    ##     filter

    ## The following object is masked from 'package:graphics':
    ## 
    ##     layout

``` r
library(tidyr)
library(mosaic)
```

#### Read in Latest TTP file

The TTP file should be updated quarterly. A csv should be saved in ***~/Transportation\_Impact*** directory
