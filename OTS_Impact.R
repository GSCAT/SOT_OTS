library(readr)
library(dplyr)

OTP_Logistics <- read.csv(paste(SOT_OTS_directory, 
                                 grep("Weekly Dashboard", 
                                      list.files(SOT_OTS_directory), 
                                      value = TRUE), sep = .Platform$file.sep))

cat_vec <- c("Wovens", "Knits", "Denim and Woven Bottoms", "Sweaters", "IP", "Accessories", "Category Other", "3P & Lic")
brand_vec <- c("GAP NA", "BR NA", "ON NA", "GO NA", "BRFS NA", "GAP INTL", "BR INTL", "ON INTL", "GO INTL", "ATHLETA")
BMC_table <- read_csv("https://github.gapinc.com/raw/SRAA/Static_tables/master/BMC.csv")
logistics_reason <- read_csv("https://github.gapinc.com/raw/SRAA/Static_tables/master/Logistics_reason_map.csv")

OTP_Logistics_sub <- OTP_Logistics %>% 
  select(Destination.PO.DPO.NBR, "Logistics_Impact"= `INDC.2`) %>% 
  # filter(grepl("Vendor", Logistics_Impact, ignore.case = TRUE)) %>%
  group_by(Destination.PO.DPO.NBR) %>%
  summarise("Logistics_Impact" = first(`Logistics_Impact`)) %>%
  droplevels()
  

OTS_Master_Logistics_Impact <- OTS_Master %>% 
  left_join(OTP_Logistics_sub, by = c("DEST_PO_ID" = "Destination.PO.DPO.NBR")) %>% 
  left_join(logistics_reason, by = c("Logistics_Impact" = "Logistics_Impact"))

test <- OTS_Master_Logistics_Impact %>%   
  filter(grepl("Vendor", Logistics_Impact, ignore.case = TRUE)) %>% 
  group_by(`ReportingBrand`, `Week`) %>% 
  summarise(sum(Units))
View(OTS_Master_Logistics_Impact %>%   filter(grepl("Vendor", Logistics_Impact, ignore.case = TRUE)) %>% group_by(`ReportingBrand`, `Week`) %>% summarise(sum(Units)))
# 
# OTS_by_brand <- OTS_Master_Logistics_Impact %>% 
#   filter(Week <= EOW) %>% 
#   group_by(ReportingBrand) %>% 
#   summarise("OTS %" = sum(subset(Units, Lateness == "OnTime"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined")),
#             "Vendor" = sum(subset(Units, grepl("Vendor", Logistics_Impact, ignore.case = TRUE) & Lateness == "OnTime"))/sum(subset(Units, Lateness != "Undetermined")),
#             "Consolidator" = sum(subset(Units, Logistics_Impact == "Consolidator" & Lateness == "OnTime"))/ sum(subset(Units, Lateness != "Undetermined")),
#             "Vessel" = sum(subset(Units, Logistics_Impact == "Vessel"& Lateness == "OnTime"))/sum(subset(Units, Lateness != "Undetermined")),
#             "Weather" = sum(subset(Units, Logistics_Impact == "Extreme Weather" & Lateness == "OnTime"))/sum(subset(Units, Lateness != "Undetermined")),
#             "ITO" = sum(subset(Units, grepl("ITO", Logistics_Impact, ignore.case = TRUE) & Lateness == "OnTime"))/sum(subset(Units, Lateness != "Undetermined")),
#             "Customs" = sum(subset(Units, Logistics_Impact == "Customs" & Lateness == "OnTime"))) %>% 
#             #"Other" = sum(subset(Units, !(Logistics_Impact %in% c("")))) %>% 
#   right_join(as.data.frame(brand_vec), by = c("ReportingBrand" = "brand_vec"))

OTS_by_brand <- OTS_Master_Logistics_Impact %>% 
  filter(Week == EOW) %>% 
  group_by(ReportingBrand) %>% 
  summarise("OTS %" = sum(subset(Units, Lateness == "OnTime"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Brand RD/Hold" = sum(subset(Units, grepl("Brand", OTS, ignore.case = TRUE) & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Vendor" = sum(subset(Units, OTS == "Vendor" & Lateness == "Late"), na.rm = T)/ sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Origin" = sum(subset(Units, OTS == "Origin"& Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Weather" = sum(subset(Units, OTS == "Extreme Weather" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Destination" = sum(subset(Units, OTS == "Destination" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "DC Congestion" = sum(subset(Units, OTS == "OT" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Other" = sum(subset(Units, OTS %in% c("Other", NA) & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T)) %>% 
  #"Other" = sum(subset(Units, !(Logistics_Impact %in% c("")))) %>%
  right_join(as.data.frame(brand_vec), by = c("ReportingBrand" = "brand_vec")) %>% 
  mutate("Total" = rowSums(.[2:9])) %>% 
  mutate("OTS Variance from Target" = `OTS %` -.90) %>% 
  select(c(1, 2, 11, 3:10))

# disagree <- OTS_Master_Logistics_Impact %>%
#   filter(Lateness == "Late" & is.na(OTS) & Logistics_Impact == "OT" & Week == EOW) %>%
#   group_by(ReportingBrand) %>%
#   summarise("Units" = sum(`Units`))

  
write_csv(OTS_by_brand, paste(SOT_OTS_directory, "OTS_by_brand.csv", sep = .Platform$file.sep))

OTS_by_category <- OTS_Master_Logistics_Impact %>% 
  filter(Week == EOW) %>% 
  group_by(Category) %>% 
  summarise("OTS %" = sum(subset(Units, Lateness == "OnTime"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Brand RD/Hold" = sum(subset(Units, grepl("Brand", OTS, ignore.case = TRUE) & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Vendor" = sum(subset(Units, OTS == "Vendor" & Lateness == "Late"), na.rm = T)/ sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Origin" = sum(subset(Units, OTS == "Origin"& Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Weather" = sum(subset(Units, OTS == "Extreme Weather" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Destination" = sum(subset(Units, OTS == "Destination" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "DC Congestion" = sum(subset(Units, OTS == "OT" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Other" = sum(subset(Units, OTS %in% c("Other", NA) & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T)) %>% 
  #"Other" = sum(subset(Units, !(Logistics_Impact %in% c("")))) %>%
  right_join(as.data.frame(cat_vec), by = c("Category" = "cat_vec")) %>% 
  mutate("Total" = rowSums(.[2:9])) %>% 
  mutate("OTS Variance from Target" = `OTS %` -.90) %>% 
  select(c(1, 2, 11, 3:10))

write_csv(OTS_by_category, paste(SOT_OTS_directory, "OTS_by_category.csv", sep = .Platform$file.sep))


OTS_by_GapInc <- OTS_Master_Logistics_Impact %>% 
  filter(Week == EOW) %>% 
  ungroup() %>% 
  # group_by(Category) %>% 
  summarise("OTS %" = sum(subset(Units, Lateness == "OnTime"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Brand RD/Hold" = sum(subset(Units, grepl("Brand", OTS, ignore.case = TRUE) & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Vendor" = sum(subset(Units, OTS == "Vendor" & Lateness == "Late"), na.rm = T)/ sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Origin" = sum(subset(Units, OTS == "Origin"& Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Weather" = sum(subset(Units, OTS == "Extreme Weather" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Destination" = sum(subset(Units, OTS == "Destination" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "DC Congestion" = sum(subset(Units, OTS == "OT" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Other" = sum(subset(Units, OTS %in% c("Other", NA) & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T)) %>% 
  #"Other" = sum(subset(Units, !(Logistics_Impact %in% c("")))) %>%
  # right_join(as.data.frame(cat_vec), by = c("Category" = "cat_vec")) %>% 
  mutate("Total" = rowSums(.[1:8])) %>% 
  mutate("OTS Variance from Target" = `OTS %` -.90) %>% 
  mutate("Entity" = "Gap Inc") %>% 
  select(c(11, 1, 10, 2:9))


write_csv(OTS_by_GapInc, paste(SOT_OTS_directory, "OTS_by_GapInc.csv", sep = .Platform$file.sep))

edge_cases <- OTS_Master_Logistics_Impact %>% filter(Week == EOW, Lateness == "Late", is.na(OTS))
write_csv(edge_cases, "edge_cases.csv")

#### Parking lot ----
Trans_output <- SOT_Master_FOB %>%
  filter(ShipCancelWeek == EOW,  !grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed= FALSE)) %>% 
  group_by(ReportingBrand) %>% 
  summarise("SOT %" = (sum(subset(Units, Lateness == "OnTime"), na.rm = TRUE))/sum(subset(Units, Lateness != "Unmeasured")),
            "Transport_Impact" = (sum(subset(Units, `Probable Failure` == "Transportation")))/sum(subset(Units, Lateness != "Unmeasured")),
            "Air_Vendor_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD == "A" )))/sum(subset(Units, Lateness != "Unmeasured")),
            "Vendor_non_Air_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD != "A" )))/sum(subset(Units, Lateness != "Unmeasured")),
            "Unmeasured_Impact" = 1 - sum(`Transport_Impact` + `Air_Vendor_Impact` + `Vendor_non_Air_Impact` + `SOT %`),
            "Total_Impact" = sum(`Transport_Impact` + `Air_Vendor_Impact` + `Vendor_non_Air_Impact` + `Unmeasured_Impact` + `SOT %`)) %>% 
  right_join(as.data.frame(brand_vec), by = c("ReportingBrand" = "brand_vec")) %>% 
  mutate("SOT Variance from Target" = `SOT %` -.95) %>% 
  select(ReportingBrand, `SOT %`, `SOT Variance from Target`, `Transport_Impact`, `Air_Vendor_Impact`, `Vendor_non_Air_Impact`, `Unmeasured_Impact`,  `Total_Impact`)

