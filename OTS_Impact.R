library(readr)
library(dplyr)

# ### Get Weekly dashboard file from here: https://gapinc.app.box.com/folder/26906947114
# paste(SOT_OTS_directory, 
#       grep("Weekly", 
#            list.files(SOT_OTS_directory), 
#            value = TRUE), sep = .Platform$file.sep)
# 
# OTP_Logistics <- read.csv(paste(SOT_OTS_directory, 
#                                  grep("Weekly", 
#                                       list.files(SOT_OTS_directory), 
#                                       value = TRUE), sep = .Platform$file.sep))

source("Transportation_Data_Pull.R")

cat_vec <- c("Wovens", "Knits", "Denim and Woven Bottoms", "Sweaters", "IP", "Accessories", "Category Other", "3P & Lic")
brand_vec <- c("GAP NA", "BR NA", "ON NA", "GO NA", "BRFS NA", "GAP INTL", "BR INTL", "ON INTL", "GO INTL", "ATHLETA")
BMC_table <- read_csv("https://github.gapinc.com/raw/SRAA/Static_tables/master/BMC.csv")
logistics_reason <- read_csv("https://github.gapinc.com/raw/SRAA/Static_tables/master/Logistics_reason_map.csv")

dir.create((file.path(SOT_OTS_directory, "Impact_files/OTS_Impact")))

# rearrange factor levels to "OT" at end
Transportation_data_combine$`INDC+2` <- factor(Transportation_data_combine$`INDC+2`, 
                                               levels(Transportation_data_combine$`INDC+2`)[c(1:14, 16:22, 15)])
# Arrange dataframe accouding to custom factor levels (i.e. "OT" last).
Transportation_data_combine <- Transportation_data_combine %>% arrange(`INDC+2`)

OTP_Logistics_sub <- Transportation_data_combine %>% 
  select(`Purchase Order Number`, "Logistics_Impact"= `INDC+2`) %>% 
  # filter(grepl("Vendor", Logistics_Impact, ignore.case = TRUE)) %>%
  group_by(`Purchase Order Number`) %>%
  summarise("Logistics_Impact" = first(`Logistics_Impact`)) %>%
  droplevels()

# Transportation_data_combine$Forecast.Units...PO.DPO <- as.numeric(Transportation_data_combine$Forecast.Units...PO.DPO)
# 
# by_logistics_reason <- Transportation_data_combine %>% 
#   # filter(FiscalWeek == EOW) %>%
#   select(`Total Shipped Qty`,"Logistics_Impact"= `INDC+2`) %>% 
#   group_by(`Logistics_Impact`) %>%
#   summarise("Units" = sum(`Total Shipped Qty`)) %>%
#   mutate("Percentage" = Units / sum(Units)) %>%
#   arrange(desc(`Units`))
  
OTS_Master_Logistics_Impact <- OTS_Master %>% 
  left_join(OTP_Logistics_sub, by = c("DEST_PO_ID" = "Purchase Order Number")) %>% 
  left_join(logistics_reason, by = c("Logistics_Impact" = "Logistics_Impact"))

OTS_Master_Logistics_Impact %>% 
  filter(Week == EOW) %>% 
  write_csv(paste(SOT_OTS_directory, "Impact_files", "OTS_Impact", paste("OTS_Master_wk_", EOW, ".csv", sep = ""), sep = .Platform$file.sep))


by_logistics_reason <- OTS_Master_Logistics_Impact %>%
  filter(Week == EOW, Lateness == "Late") %>%
  group_by(Logistics_Impact) %>%
  summarise("Units" = sum(Units))
  
by_logistics_reason_Inc <- OTS_Master_Logistics_Impact %>%
  filter(Week == EOW, Lateness == "Late") %>%
  group_by(OTP) %>%
  summarise("Units" = sum(Units))

by_logistics_reason_Month <- OTS_Master_Logistics_Impact %>%
  filter(Month_Number == fis_month, Lateness == "Late") %>%
  group_by(OTS) %>%
  summarise("Units" = sum(Units))

# For Impact email comments ----
OTS_Impact_Comment_df <- OTS_Master_Logistics_Impact %>%
  filter(Week == EOW, Lateness == "Late") %>% 
  group_by(OTS) %>% 
  summarise("Units" = sum(Units))

OTS_Impact_Comment_df

# write_csv(by_logistics_reason, paste(SOT_OTS_directory, "Impact_files", "OTS_Impact", "by_logistics_reason.csv", sep = "\\"))

# write_csv(OTS_by_brand, paste(SOT_OTS_directory, "Impact_files", "OTS_Impact", "something.csv", sep = .Platform$file.sep))
# write_csv(by_logistics_reason, paste(SOT_OTS_directory, "Impact_files", "OTS_Impact", "by_logistics_reason.csv", sep = .Platform$file.sep))
  
# View(by_logistics_reason)

test <- OTS_Master_Logistics_Impact %>%   
  filter(grepl("Vendor", Logistics_Impact, ignore.case = TRUE)) %>% 
  group_by(`ReportingBrand`, `Week`) %>% 
  summarise(sum(Units))

# View(OTS_Master_Logistics_Impact %>%   filter(grepl("Vendor", Logistics_Impact, ignore.case = TRUE)) %>% group_by(`ReportingBrand`, `Week`) %>% summarise(sum(Units)))
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

##### by Brand
OTS_by_brand <- OTS_Master_Logistics_Impact %>% 
  filter(Week == EOW) %>% 
  group_by(ReportingBrand) %>% 
  summarise("Total_Units" = sum(Units),
            "OTS %" = sum(subset(Units, Lateness == "OnTime"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Brand RD/Hold" = sum(subset(Units, grepl("Brand", OTS, ignore.case = TRUE) & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Vendor" = sum(subset(Units, OTS == "Vendor" & Lateness == "Late"), na.rm = T)/ sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Int'l Transportation" = sum(subset(Units, OTS == "Origin"& Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Weather" = sum(subset(Units, OTS == "Extreme Weather" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Domestic Transportation" = sum(subset(Units, OTS == "Destination" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "DC Stocking" = sum(subset(Units, OTS == "OT" & Lateness == "Late" & SHIP_CANCEL_DATE == Contract_Ship_Cancel ), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Other" = sum(subset(Units, OTS %in% c("Other", NA, "OT") & Lateness == "Late" & SHIP_CANCEL_DATE != Contract_Ship_Cancel ), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T)) %>% 
  #"Other" = sum(subset(Units, !(Logistics_Impact %in% c("")))) %>%
  right_join(as.data.frame(brand_vec), by = c("ReportingBrand" = "brand_vec")) %>% 
  mutate("Total" = rowSums(select(.,"OTS %","Brand RD/Hold","Vendor","Int'l Transportation","Weather","Domestic Transportation",
                                  "DC Stocking","Other"))) %>% 
  mutate("OTS Variance from Target" = `OTS %` -.90) %>% 
  select(ReportingBrand, `Total_Units`,`OTS %`, `OTS Variance from Target`, `Brand RD/Hold`, `Vendor`,`Int'l Transportation`, `Weather`, `Domestic Transportation`, 
         `DC Stocking`, `Other`, `Total`)

# disagree <- OTS_Master_Logistics_Impact %>%
#   filter(Lateness == "Late" & is.na(OTS) & Logistics_Impact == "OT" & Week == EOW) %>%
#   group_by(ReportingBrand) %>%
#   summarise("Units" = sum(`Units`))

write_csv(OTS_by_brand, paste(SOT_OTS_directory, "Impact_files", "OTS_Impact", "OTS_by_brand.csv", sep = .Platform$file.sep))

# ##### by brand 2
# 
# OTS_by_brand2 <- OTS_Master_Logistics_Impact %>% 
#   filter(Week == EOW) %>% 
#   group_by(ReportingBrand) %>% 
#   summarise("OTS %" = sum(subset(Units, Lateness == "OnTime"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Brand RD/Hold" = sum(subset(Units, grepl("Brand", OTS, ignore.case = TRUE) & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Vendor" = sum(subset(Units, OTS == "Vendor" & Lateness == "Late"), na.rm = T)/ sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Int'l Transportation" = sum(subset(Units, OTS == "Origin"& Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Weather" = sum(subset(Units, OTS == "Extreme Weather" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Domestic Transportation" = sum(subset(Units, OTS == "Destination" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "DC Stocking" = sum(subset(Units, OTS == "OT" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Other" = sum(subset(Units, OTS %in% c("Other", NA) & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T)) %>% 
#   #"Other" = sum(subset(Units, !(Logistics_Impact %in% c("")))) %>%
#   right_join(as.data.frame(brand_vec), by = c("ReportingBrand" = "brand_vec")) %>% 
#   mutate("Total" = rowSums(.[2:9])) %>% 
#   mutate("OTS Variance from Target" = `OTS %` -.90) %>% 
#   select(c(1, 2, 11, 3:10))
# 
# write_csv(OTS_by_brand2, paste(SOT_OTS_directory, "Impact_files", "OTS_Impact", "OTS_by_brand2.csv", sep = .Platform$file.sep))

OTS_by_category <- OTS_Master_Logistics_Impact %>% 
  filter(Week == EOW) %>% 
  group_by(Category) %>% 
  summarise("Total_Units" = sum(Units),
            "OTS %" = sum(subset(Units, Lateness == "OnTime"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Brand RD/Hold" = sum(subset(Units, grepl("Brand", OTS, ignore.case = TRUE) & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Vendor" = sum(subset(Units, OTS == "Vendor" & Lateness == "Late"), na.rm = T)/ sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Int'l Transportation" = sum(subset(Units, OTS == "Origin"& Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Weather" = sum(subset(Units, OTS == "Extreme Weather" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Domestic Transportation" = sum(subset(Units, OTS == "Destination" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "DC Stocking" = sum(subset(Units, OTS == "OT" & Lateness == "Late" & SHIP_CANCEL_DATE == Contract_Ship_Cancel ), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Other" = sum(subset(Units, OTS %in% c("Other", NA, "OT") & Lateness == "Late" & SHIP_CANCEL_DATE != Contract_Ship_Cancel ), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T)) %>% 
  #"Other" = sum(subset(Units, !(Logistics_Impact %in% c("")))) %>%
  right_join(as.data.frame(cat_vec), by = c("Category" = "cat_vec")) %>% 
  mutate("Total" = rowSums(select(.,"OTS %","Brand RD/Hold","Vendor","Int'l Transportation","Weather","Domestic Transportation",
                                  "DC Stocking","Other"))) %>% 
  mutate("OTS Variance from Target" = `OTS %` -.90) %>% 
  select(Category, `Total_Units`,`OTS %`, `OTS Variance from Target`, `Brand RD/Hold`, `Vendor`,`Int'l Transportation`, `Weather`, `Domestic Transportation`, 
         `DC Stocking`, `Other`, `Total`)

# OTS_by_category_v2 <- OTS_Master_Logistics_Impact %>% 
#   filter(Week == EOW) %>% 
#   group_by(Category) %>% 
#   summarise("Total_Units" = sum(Units),
#             "OTS %" = sum(subset(Units, Lateness == "OnTime"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Brand RD/Hold" = sum(subset(Units, grepl("Brand", OTS, ignore.case = TRUE) & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Vendor" = sum(subset(Units, OTS == "Vendor" & Lateness == "Late"), na.rm = T)/ sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Int'l Transportation" = sum(subset(Units, OTS == "Origin"& Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Weather" = sum(subset(Units, OTS == "Extreme Weather" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Domestic Transportation" = sum(subset(Units, OTS == "Destination" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "DC Stocking" = sum(subset(Units, OTS == "OT" & Lateness == "Late" & SHIP_CANCEL_DATE == Contract_Ship_Cancel ), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Other" = sum(subset(Units, OTS %in% c("Other", NA, "OT") & Lateness == "Late" & SHIP_CANCEL_DATE != Contract_Ship_Cancel ), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T)) %>% 
#   #"Other" = sum(subset(Units, !(Logistics_Impact %in% c("")))) %>%
#   right_join(as.data.frame(cat_vec), by = c("Category" = "cat_vec")) %>% 
#   mutate("Total" = rowSums(select(.,"OTS %","Brand RD/Hold","Vendor","Int'l Transportation","Weather","Domestic Transportation",
#                                   "DC Stocking","Other"))) %>% 
#   mutate("OTS Variance from Target" = `OTS %` -.90) %>% 
#   select(Category, `Total_Units`,`OTS %`, `OTS Variance from Target`, `Brand RD/Hold`, `Vendor`,`Int'l Transportation`, `Weather`, `Domestic Transportation`, 
#          `DC Stocking`, `Other`, `Total`)

write_csv(OTS_by_category, paste(SOT_OTS_directory, "Impact_files", "OTS_Impact", "OTS_by_category.csv", sep = .Platform$file.sep))
# write_csv(OTS_by_category_v2, paste(SOT_OTS_directory, "Impact_files", "OTS_Impact", "OTS_by_category_v2.csv", sep = .Platform$file.sep))


OTS_by_GapInc <- OTS_Master_Logistics_Impact %>% 
  ungroup() %>% 
  filter(Week == EOW) %>% 
  summarise("Total_Units" = sum(Units),
            "OTS %" = sum(subset(Units, Lateness == "OnTime"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Brand RD/Hold" = sum(subset(Units, grepl("Brand", OTS, ignore.case = TRUE) & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Vendor" = sum(subset(Units, OTS == "Vendor" & Lateness == "Late"), na.rm = T)/ sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Int'l Transportation" = sum(subset(Units, OTS == "Origin"& Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Weather" = sum(subset(Units, OTS == "Extreme Weather" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Domestic Transportation" = sum(subset(Units, OTS == "Destination" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "DC Stocking" = sum(subset(Units, OTS == "OT" & Lateness == "Late" & SHIP_CANCEL_DATE == Contract_Ship_Cancel ), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Other" = sum(subset(Units, OTS %in% c("Other", NA, "OT") & Lateness == "Late" & SHIP_CANCEL_DATE != Contract_Ship_Cancel ), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Units" = sum(Units)) %>% 
  mutate("Total" = rowSums(select(.,"OTS %","Brand RD/Hold","Vendor","Int'l Transportation","Weather","Domestic Transportation",
                                  "DC Stocking","Other"))) %>% 
  mutate("OTS Variance from Target" = `OTS %` -.90) %>% 
  mutate("Entity" = "Gap Inc") %>% 
  select(c(Entity, `Units`, `OTS %`, 
           `OTS Variance from Target`, `Brand RD/Hold`, `Vendor`, 
           `Int'l Transportation`, `Weather`, `Domestic Transportation`, `DC Stocking`, 
           `Other`, `Total`))

write_csv(OTS_by_GapInc, paste(SOT_OTS_directory, "Impact_files", "OTS_Impact", "OTS_by_GapInc.csv", sep = .Platform$file.sep))
###### DC's

DC_vec <- c("BDC", "CFC", "CAO", "GUK", "EFC", "WFC", 
            "OFC", "CEO", "TDC", "SDC", "FDC", "PDC", 
            "ODC", "EAO", "SHD", "UK DC", "JPD")

OTS_by_DC <- OTS_Master_Logistics_Impact %>% 
  filter(Week == EOW) %>% 
  group_by(LOC_ABBR_NM) %>% 
  summarise("Total_Units" = sum(Units),
            "OTS %" = sum(subset(Units, Lateness == "OnTime"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Brand RD/Hold" = sum(subset(Units, grepl("Brand", OTS, ignore.case = TRUE) & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Vendor" = sum(subset(Units, OTS == "Vendor" & Lateness == "Late"), na.rm = T)/ sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Int'l Transportation" = sum(subset(Units, OTS == "Origin"& Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Weather" = sum(subset(Units, OTS == "Extreme Weather" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Domestic Transportation" = sum(subset(Units, OTS == "Destination" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "DC Stocking" = sum(subset(Units, OTS == "OT" & Lateness == "Late" & SHIP_CANCEL_DATE == Contract_Ship_Cancel ), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Other" = sum(subset(Units, OTS %in% c("Other", NA, "OT") & Lateness == "Late" & SHIP_CANCEL_DATE != Contract_Ship_Cancel ), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
            "Units" = sum(Units)) %>% 
  
  #"Other" = sum(subset(Units, !(Logistics_Impact %in% c("")))) %>%
  right_join(as.data.frame(DC_vec), by = c("LOC_ABBR_NM" = "DC_vec")) %>% 
  mutate("Total" = rowSums(select(.,"OTS %","Brand RD/Hold","Vendor","Int'l Transportation","Weather","Domestic Transportation",
                                  "DC Stocking","Other"))) %>% 
  mutate("OTS Variance from Target" = `OTS %` -.90) %>%
  mutate("Blank" = '') %>% 
  select(c(LOC_ABBR_NM,`Blank`, `Units`, `OTS %`, 
           `OTS Variance from Target`, `Brand RD/Hold`, `Vendor`, 
           `Int'l Transportation`, `Weather`, `Domestic Transportation`, `DC Stocking`, 
           `Other`, `Total`))

write_csv(OTS_by_DC, paste(SOT_OTS_directory, "Impact_files", "OTS_Impact", "OTS_by_DC.csv", sep = .Platform$file.sep))
write_csv(OTS_Master_Logistics_Impact, paste(SOT_OTS_directory, "Impact_files", "OTS_Impact", "OTS_Master_Logistics_Impact.csv", sep = .Platform$file.sep))

# Save Workspace ----
 rm(credentials)
s <- session_info()
save.image(paste(SOT_OTS_directory, paste("Week_", EOW, ".RData", sep = ""), sep=.Platform$file.sep))
# load(file = paste(SOT_OTS_directory, paste("Week_", EOW, ".RData", sep = ""), sep = .Platform$file.sep))


# ####### Vendor
# 
# vendor_OTS_df <- OTS_Master_Logistics_Impact %>% 
#   filter(Week <= EOW,  !grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed= FALSE)) %>% 
#   select(Category, Parent_Vendor, Units) %>% 
#   group_by(Category, Parent_Vendor) %>% 
#   summarise("Total Units" = sum(Units)) %>% 
#   top_n(15, `Total Units`) %>% 
#   arrange(Category, desc(`Total Units`))
# 
# OTS_by_parent_vendor <- OTS_Master_Logistics_Impact %>% 
#   filter(Week == EOW) %>% 
#   group_by(Parent_Vendor, Category) %>% 
#   summarise("OTS %" = sum(subset(Units, Lateness == "OnTime"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Brand RD/Hold" = sum(subset(Units, grepl("Brand", OTS, ignore.case = TRUE) & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Vendor" = sum(subset(Units, OTS == "Vendor" & Lateness == "Late"), na.rm = T)/ sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Int'l Transportation" = sum(subset(Units, OTS == "Origin"& Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Weather" = sum(subset(Units, OTS == "Extreme Weather" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Domestic Transportation" = sum(subset(Units, OTS == "Destination" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "DC Stocking" = sum(subset(Units, OTS == "OT" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Other" = sum(subset(Units, OTS %in% c("Other", NA) & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T)) %>% 
#   #"Other" = sum(subset(Units, !(Logistics_Impact %in% c("")))) %>%
#   right_join(vendor_OTS_df, by = c("Parent_Vendor" = "Parent_Vendor", "Category" = "Category")) %>%
#   ungroup() %>% 
#   mutate("Total" = rowSums(.[3:10])) %>% 
#   mutate("OTS Variance from Target" = `OTS %` -.90) %>%
#   mutate("Blank" = '') %>% 
#   group_by(Category) %>% 
#   right_join(as.data.frame(cat_vec), by = c("Category" = "cat_vec")) %>% 
#   select(c(Category, Parent_Vendor,`Blank`, `Units`, `OTS %`, 
#            `OTS Variance from Target`, `Brand RD/Hold`, `Vendor`, 
#            `Origin`, `Weather`, `Destination`, `DC Congestion`, 
#            `Other`, `Total`))
# 
# OTS_by_parent_vendor[is.na(OTS_by_parent_vendor)] <- "-"
# 
# write_csv(OTS_by_parent_vendor, paste(SOT_OTS_directory, "Impact_files", "OTS_Impact", "OTS_by_parent_vendor.csv", sep = .Platform$file.sep))
# 
# 
# 
# ####### Transfer point place
# 
# OTS_by_transfer_point <- OTS_Master_Logistics_Impact %>% 
#   filter(Week == EOW) %>% 
#   group_by(XFR_Point_Place) %>% 
#   summarise("OTS %" = sum(subset(Units, Lateness == "OnTime"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Brand RD/Hold" = sum(subset(Units, grepl("Brand", OTS, ignore.case = TRUE) & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Vendor" = sum(subset(Units, OTS == "Vendor" & Lateness == "Late"), na.rm = T)/ sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Int'l Transportation" = sum(subset(Units, OTS == "Origin"& Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Weather" = sum(subset(Units, OTS == "Extreme Weather" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Domestic Transportation" = sum(subset(Units, OTS == "Destination" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "DC Stocking" = sum(subset(Units, OTS == "OT" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Other" = sum(subset(Units, OTS %in% c("Other", NA) & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T)) %>% 
#   #"Other" = sum(subset(Units, !(Logistics_Impact %in% c("")))) %>%
#   # right_join(as.data.frame(DC_vec), by = c("LOC_ABBR_NM" = "DC_vec")) %>% 
#   mutate("Total" = rowSums(.[2:9])) %>% 
#   mutate("OTS Variance from Target" = `OTS %` -.90) %>%
#   mutate("Blank" = '') %>% 
#   select(c(XFR_Point_Place,`Blank`, `Units`, `OTS %`, 
#            `OTS Variance from Target`, `Brand RD/Hold`, `Vendor`, 
#            `Origin`, `Weather`, `Destination`, `DC Congestion`, 
#            `Other`, `Total`)) %>% 
#   arrange(desc(Units))
# 
# write_csv(OTS_by_transfer_point, paste(SOT_OTS_directory, "Impact_files", "OTS_Impact", "OTS_by_transfer_point.csv", sep = .Platform$file.sep))
# 
# 
# ##### Origin Country
# 
# OTS_by_origin_country <- OTS_Master_Logistics_Impact %>% 
#   filter(Week == EOW) %>% 
#   group_by(ORIGIN_COUNTRY_CODE) %>% 
#   summarise("OTS %" = sum(subset(Units, Lateness == "OnTime"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Brand RD/Hold" = sum(subset(Units, grepl("Brand", OTS, ignore.case = TRUE) & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Vendor" = sum(subset(Units, OTS == "Vendor" & Lateness == "Late"), na.rm = T)/ sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Int'l Transportation" = sum(subset(Units, OTS == "Origin"& Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Weather" = sum(subset(Units, OTS == "Extreme Weather" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Domestic Transportation" = sum(subset(Units, OTS == "Destination" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "DC Stocking" = sum(subset(Units, OTS == "OT" & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T),
#             "Other" = sum(subset(Units, OTS %in% c("Other", NA) & Lateness == "Late"), na.rm = T)/sum(subset(Units, Lateness != "Undetermined"), na.rm = T)) %>% 
#   #"Other" = sum(subset(Units, !(Logistics_Impact %in% c("")))) %>%
#   # right_join(as.data.frame(DC_vec), by = c("LOC_ABBR_NM" = "DC_vec")) %>% 
#   mutate("Total" = rowSums(.[2:9])) %>% 
#   mutate("OTS Variance from Target" = `OTS %` -.90) %>%
#   mutate("Blank" = '') %>% 
#   select(c(ORIGIN_COUNTRY_CODE,`Blank`, `Units`, `OTS %`, 
#            `OTS Variance from Target`, `Brand RD/Hold`, `Vendor`, 
#            `Origin`, `Weather`, `Destination`, `DC Congestion`, 
#            `Other`, `Total`)) %>% 
#   arrange(desc(Units))
# 
# write_csv(OTS_by_origin_country, paste(SOT_OTS_directory, "Impact_files", "OTS_Impact", "OTS_by_origin_country.csv", sep = .Platform$file.sep))
# 
# ##### Parking lot ----
# 
# 
# edge_cases <- OTS_Master_Logistics_Impact %>% filter(Week == EOW, Lateness == "Late", is.na(OTS))
# write_csv(edge_cases, "edge_cases.csv")
# 
# #### Parking lot ----
# Trans_output <- SOT_Master_FOB %>%
#   filter(ShipCancelWeek == EOW,  !grepl("FRANCHISE", ReportingBrand, ignore.case = TRUE, fixed= FALSE)) %>% 
#   group_by(ReportingBrand) %>% 
#   summarise("SOT %" = (sum(subset(Units, Lateness == "OnTime"), na.rm = TRUE))/sum(subset(Units, Lateness != "Unmeasured")),
#             "Transport_Impact" = (sum(subset(Units, `Probable Failure` == "Transportation")))/sum(subset(Units, Lateness != "Unmeasured")),
#             "Air_Vendor_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD == "A" )))/sum(subset(Units, Lateness != "Unmeasured")),
#             "Vendor_non_Air_Impact" = (sum(subset(Units, `Probable Failure` == "Vendor" & SHIP_MODE_CD != "A" )))/sum(subset(Units, Lateness != "Unmeasured")),
#             "Unmeasured_Impact" = 1 - sum(`Transport_Impact` + `Air_Vendor_Impact` + `Vendor_non_Air_Impact` + `SOT %`),
#             "Total_Impact" = sum(`Transport_Impact` + `Air_Vendor_Impact` + `Vendor_non_Air_Impact` + `Unmeasured_Impact` + `SOT %`)) %>% 
#   right_join(as.data.frame(brand_vec), by = c("ReportingBrand" = "brand_vec")) %>% 
#   mutate("SOT Variance from Target" = `SOT %` -.95) %>% 
#   select(ReportingBrand, `SOT %`, `SOT Variance from Target`, `Transport_Impact`, `Air_Vendor_Impact`, `Vendor_non_Air_Impact`, `Unmeasured_Impact`,  `Total_Impact`)
