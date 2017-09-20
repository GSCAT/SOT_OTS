library(dplyr)

#### Generate file to put into SCI
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


#### Fix OTS Master file for missing stocked dates

TEST_OTS_Master <- OTS_Master %>%
  left_join(sub_DPO_list, by = "DEST_PO_ID")


manual_clean_df2 <- OTS_Master %>% 
  filter(Week == EOW) %>% 
  select(DEST_PO_ID, ReportingBrand, PLANNED_STOCKED_DATE, StkdDte, Week, Units) %>%
  group_by(DEST_PO_ID, ReportingBrand, PLANNED_STOCKED_DATE, StkdDte, Week) %>% 
  summarise("Sum of Total Unis" = sum(Units, na.rm = T)) %>%
  select(DEST_PO_ID, `Sum of OnTime Units`) %>% 
  # filter(!`Sum of Late Units` == 0) %>% 
  arrange(ReportingBrand, desc(`Sum of OnTime Units`))

combine_manual_clean <- left_join(manual_clean_df, manual_clean_df2, by = "DEST_PO_ID")
