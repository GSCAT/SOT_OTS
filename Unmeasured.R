library(ggthemes)

Unmeasured_by_brand <- SOT_Master_Unmeasured %>% 
  group_by(`ReportingBrand`, ShipCancelWeek) %>% 
  filter(ShipCancelWeek == EOW, `FISCAL_YEAR` == fis_yr) %>% 
  summarise("Unmeasured_Units" = sum(`Units`, na.rm = T)) %>% 
  right_join(as.data.frame(brand_vec), by = c("ReportingBrand" = "brand_vec"))

Unmeasured_by_Category <- SOT_Master_Unmeasured %>% 
  group_by(`Category`, ShipCancelWeek) %>% 
  filter(ShipCancelWeek == EOW, `FISCAL_YEAR` == fis_yr) %>% 
  summarise("Unmeasured_Units" = sum(`Units`, na.rm = T)) %>% 
  right_join(as.data.frame(cat_vec), by = c("Category" = "cat_vec")) %>% 
  ggplot(aes(Category, `Unmeasured_Units`)) + geom_point()+ theme(axis.text.x = element_text(angle = 90))

par(mfrow = c(2,2))

a <- SOT_Master_Unmeasured %>% 
  group_by(`Category`,ReportingBrand, ShipCancelWeek) %>% 
  filter(ShipCancelWeek == EOW, `FISCAL_YEAR` == fis_yr) %>% 
  summarise("Unmeasured_Units" = sum(`Units`, na.rm = T)) %>% 
  right_join(as.data.frame(cat_vec), by = c("Category" = "cat_vec")) %>% 
  ggplot(aes(ReportingBrand, `Unmeasured_Units`, fill = `Category`)) + 
  geom_bar(stat = "identity", position = "Stack") + 
  theme_classic() +
  #scale_fill_stata()
  scale_fill_tableau("colorblind10") +
  scale_y_continuous(labels = scales::comma) +
  theme(axis.text.x = element_text(angle = 90)) +
ggtitle("Unmeasured Units for Gap Inc", subtitle = paste("(by Brand and Category Week ", EOW, ")", sep = "") )


b <- SOT_Master_Unmeasured %>% 
  group_by(`Category`,ReportingBrand, ShipCancelWeek) %>% 
  filter(ShipCancelWeek <= EOW, `FISCAL_YEAR` == fis_yr) %>% 
  summarise("Unmeasured_Units" = sum(`Units`, na.rm = T)) %>% 
  right_join(as.data.frame(cat_vec), by = c("Category" = "cat_vec")) %>% 
  ggplot(aes(ShipCancelWeek, `Unmeasured_Units`, fill = `Category`)) + 
  geom_bar(stat = "identity", position = "Stack") + 
  theme_classic() +
  #scale_fill_stata()
  scale_fill_tableau("colorblind10") +
  scale_x_continuous(breaks = seq(2, 32, 2)) + 
  # scale_y_continuous(labels=function(n){format(n, scientific = FALSE)}) +
  scale_y_continuous(labels = scales::comma, breaks = seq(1, 3000000, 200000)) +
  theme(axis.text.x = element_text(angle = 90)) +
  ggtitle("Unmeasured Units for Gap Inc", subtitle = paste("(by Fiscal Week and Category through Week ", EOW,")", sep = ""  )) 

d <- SOT_Master_Unmeasured %>% 
  group_by(`Category`,ReportingBrand, ShipCancelWeek) %>% 
  filter(ShipCancelWeek <= EOW, `FISCAL_YEAR` == fis_yr) %>% 
  summarise("Unmeasured_Units" = sum(`Units`, na.rm = T)) %>% 
  right_join(as.data.frame(cat_vec), by = c("Category" = "cat_vec")) %>% 
  ggplot(aes(ShipCancelWeek, `Unmeasured_Units`, fill = `ReportingBrand`)) + 
  geom_bar(stat = "identity", position = "Stack") + 
  theme_classic() +
  #scale_fill_stata()
  scale_fill_tableau("colorblind10") +
  scale_x_continuous(breaks = seq(2, 32, 2)) + 
  scale_y_continuous(labels = scales::comma) +
  theme(axis.text.x = element_text(angle = 90)) +
  ggtitle("Unmeasured Units for Gap Inc", subtitle = paste("(by Fiscal Week and Brand through Week ", EOW, ")", sep = "") )

install.packages("gridExtra")
library(gridExtra)
grid.arrange(a,b,d, ncol=1, nrow = 3)

