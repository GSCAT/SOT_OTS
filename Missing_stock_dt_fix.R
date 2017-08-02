library(dplyr)

system.time(manual_clean_df <- OTS_Master %>% 
  filter(Lateness == "Late", is.na(StkdDte), Week == EOW) %>% 
  select(DEST_PO_ID, ReportingBrand, PLANNED_STOCKED_DATE, StkdDte, Week, Units) %>%
  group_by(DEST_PO_ID, ReportingBrand, PLANNED_STOCKED_DATE, StkdDte, Week) %>% 
  summarise("Sum of Late Units" = sum(Units, na.rm = T)) %>%
    filter(!`Sum of Late Units` == 0) %>% 
  arrange(ReportingBrand, desc(`Sum of Late Units`)))

write_csv(manual_clean_df, 
          path = paste(SOT_OTS_directory, 
                       "RAW_Files", 
                       paste('Missing_Stock_date_wk_', EOW, '.csv',sep = ""), sep = '/' ))