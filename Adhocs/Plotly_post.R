library(plotly)

SOT_Master_Unmeasured <- SOT_Master %>% 
  filter(SOT_Master$ShipCancelWeek <= EOW,
         SOT_Master$FISCAL_YEAR == fis_yr,
         !grepl("Liberty Distribution Company", Parent_Vendor, ignore.case = TRUE),
         !grepl("dummy", Parent_Vendor, ignore.case = TRUE),
         Lateness == "Unmeasured")

write_csv(SOT_Master_Unmeasured, path = paste(SOT_OTS_directory,  paste('SOT_Master_Unmeasured_WK', EOW, '_YTD.csv',sep = ""), sep = '/' ))


SOT_Master_Unmeasured_sum <- SOT_Master %>% 
  filter(SOT_Master$ShipCancelWeek <= EOW,
         SOT_Master$FISCAL_YEAR == fis_yr,
         !grepl("Liberty Distribution Company", Parent_Vendor, ignore.case = TRUE),
         !grepl("dummy", Parent_Vendor, ignore.case = TRUE)) %>% 
         # Lateness == "Unmeasured") %>%
  group_by(ReportingBrand, Lateness, Category) %>% 
  summarise("Units" = sum(Units, na.rm=TRUE),
            "Average Days Late" = mean(DAYS_LATE, na.rm = TRUE))

write_csv(SOT_Master_Unmeasured_sum, path = paste(SOT_OTS_directory,  paste('SOT_Master_Unmeasured_WK', EOW, '_YTD.csv',sep = ""), sep = '/' ))

SOT_Unmeasured_CB <- SOT_Master_Unmeasured_sum

candy_bars <- c("Almond Joy", "Bar None", "Butterfinger", "Butterfinger Crisp",  "Baby Ruth", "Galaxy", "Galaxy Ripple", "Gardina", "Goya", "Goobers", "Oh Henry", "Old Faithful", "Orion", "Pay Day")
length(candy_bars)

nuts <- c("Pastachios", "Almonds", "Other", "Deeknuts and Walnuts", "Palm Nuts", "Kola Nuts", "Soybeans", "Walnuts")

levels(SOT_Unmeasured_CB$ReportingBrand) <- candy_bars
levels(SOT_Unmeasured_CB$Category) <-  nuts

Sys.setenv("plotly_username"="kwbonds")
Sys.setenv("plotly_api_key"="d1raaglrx7")

p <- SOT_Unmeasured_CB %>%  plot_ly(x= ~ReportingBrand, y= ~Units) 

p 
p <- add_markers(p, color= ~Category, size = ~I(`Average Days Late`))


plotly_POST(p)
