library(ggthemes)
library(plotly)
library(DT)
library(dplyr)
library(formattable)
library(ggplot2)

dir.create((file.path(SOT_OTS_directory, "Unmeasured")))

sign_formatter <- formatter("span",
                            style = x ~ style(color = ifelse(x > 0, "green",
                            ifelse(x < 0, "red", "black"))))

cat_vec <- c("Wovens", "Knits", "Denim and Woven Bottoms", "Sweaters", "IP", "Accessories", "Category Other", "3P & Lic")
brand_vec <- c("GAP NA", "BR NA", "ON NA", "GO NA", "BRFS NA", "GAP INTL", "BR INTL", "ON INTL", "GO INTL", "ATHLETA")

Unmeasured_by_brand <- SOT_Master_Unmeasured %>% 
  group_by(`ReportingBrand`, ShipCancelWeek) %>% 
  filter(ShipCancelWeek == EOW, `FISCAL_YEAR` == fis_yr) %>% 
  summarise("Unmeasured_Units" = floor(sum(`Units`, na.rm = T))) %>% 
  right_join(as.data.frame(brand_vec), by = c("ReportingBrand" = "brand_vec"))

Unmeasured_EOW <- SOT_Master_Unmeasured %>% 
  filter(ShipCancelWeek == EOW) %>% 
  group_by(ShipCancelWeek) %>% 
  summarise("Unmeasured_Units" = sum(Units)) %>% 
  mutate("ReportingBrand" = "Gap Inc") %>% 
  select(ReportingBrand, ShipCancelWeek, Unmeasured_Units)

Unmeasured_by_brand = rbind(as.data.frame(Unmeasured_EOW), as.data.frame(Unmeasured_by_brand))

write_csv(Unmeasured_by_brand, path = paste(SOT_OTS_directory, "Unmeasured", "Unmeasured_table.csv", sep = .Platform$file.sep))

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
  scale_x_continuous(breaks = seq(0, 33, 2)) + 
  scale_y_continuous(labels = scales::comma, breaks = seq(0, 10000000, 200000)) +
  theme(axis.text.x = element_text(angle = 90)) +
  ggtitle("Unmeasured Units for Gap Inc", subtitle = paste("(by Fiscal Week and Brand through Week ", "31", ")", sep = "") )

plot(d)
save(d, file = paste(SOT_OTS_directory, "RAW_Objects",  'by_Week_Brand_Plot_object.rda', sep = .Platform$file.sep))

# Don't run below here ----
# formattable(Unmeasured_by_brand, list(Unmeasured_Units = color_bar("lightblue")))
# 
# Unmeasured_by_Category <- SOT_Master_Unmeasured %>% 
#   group_by(`Category`, ShipCancelWeek) %>% 
#   filter(ShipCancelWeek == EOW, `FISCAL_YEAR` == fis_yr) %>% 
#   summarise("Unmeasured_Units" = sum(`Units`, na.rm = T)) %>% 
#   right_join(as.data.frame(cat_vec), by = c("Category" = "cat_vec")) %>% 
#   ggplot(aes(Category, `Unmeasured_Units`)) + geom_point()+ theme(axis.text.x = element_text(angle = 90))
# 
# par(mfrow = c(2,2))
# 
# a <- SOT_Master_Unmeasured %>% 
#   group_by(`Category`,ReportingBrand, ShipCancelWeek) %>% 
#   filter(ShipCancelWeek == EOW, `FISCAL_YEAR` == fis_yr) %>% 
#   summarise("Unmeasured_Units" = sum(`Units`, na.rm = T)) %>% 
#   right_join(as.data.frame(cat_vec), by = c("Category" = "cat_vec")) %>% 
#   ggplot(aes(ReportingBrand, `Unmeasured_Units`, fill = `Category`)) + 
#   geom_bar(stat = "identity", position = "Stack") + 
#   theme_classic() +
#   #scale_fill_stata()
#   scale_fill_tableau("colorblind10") +
#   scale_y_continuous(labels = scales::comma) +
#   theme(axis.text.x = element_text(angle = 90)) +
# ggtitle("Unmeasured Units for Gap Inc", subtitle = paste("(by Brand and Category Week ", EOW, ")", sep = "") )
# 
# plot(a)
# save(a, file = paste(SOT_OTS_directory, "RAW_Objects",  'Brand_Plot_object.rda', sep = .Platform$file.sep))
# 
# b <- SOT_Master_Unmeasured %>% 
#   group_by(`Category`,ReportingBrand, ShipCancelWeek) %>% 
#   filter(ShipCancelWeek <= EOW, `FISCAL_YEAR` == fis_yr) %>% 
#   summarise("Unmeasured_Units" = sum(`Units`, na.rm = T)) %>% 
#   right_join(as.data.frame(cat_vec), by = c("Category" = "cat_vec")) %>% 
#   ggplot(aes(ShipCancelWeek, `Unmeasured_Units`, fill = `Category`)) + 
#   geom_bar(stat = "identity", position = "Stack") + 
#   theme_classic() +
#   #scale_fill_stata()
#   scale_fill_tableau("colorblind10") +
#   scale_x_continuous(breaks = seq(2, 32, 2)) + 
#   # scale_y_continuous(labels=function(n){format(n, scientific = FALSE)}) +
#   scale_y_continuous(labels = scales::comma, breaks = seq(1, 10000000, 200000)) +
#   theme(axis.text.x = element_text(angle = 90)) +
#   ggtitle("Unmeasured Units for Gap Inc", subtitle = paste("(by Fiscal Week and Category through Week ", EOW,")", sep = ""  )) 
# 
# plot(b)
# save(b, file = paste(SOT_OTS_directory, "RAW_Objects",  'by_Week_Category_Plot_object.rda', sep = .Platform$file.sep))


# install.packages("gridExtra")
# library(gridExtra)
# grid.arrange(a,b,d, ncol=1, nrow = 3)
# 
# grid_3x1 <- grid.arrange(a,b,d, ncol=1, nrow = 3)
# library(plotly)
# 
# gga <- ggplotly(a, height = 1000, legendgroup = "1st")
# ggb <- ggplotly(b, height = 1000, legendgroup = "1st")
# ggd <- ggplotly(d, height = 1000, legendgroup = "2nd")



# grid_3x1_plotly <- grid.arrange(gga,ggb,ggd, ncol=1, nrow = 3)
# 
# p <- subplot(style(gga, showlegend = TRUE, legendgroup = "1st"),
#         style(ggb, showlegend = FALSE, legendgroup = "1st"), 
#         style(ggd, showlegend = TRUE, legendgroup = "1st"),
#         nrows = 3, margin = .05)
# 
# sign_formatter <- formatter("span",
#                             style = x ~ style(color = ifelse(x > 0, "green",
#                             ifelse(x < 0, "red", "black"))))
# 
# 
# formattable(Unmeasured_by_brand, list(Unmeasured_Units = color_bar("lightblue")))
# 
# as.datatable(formattable(Unmeasured_by_brand, list(Unmeasured_Units = color_bar("lightblue"))))
# htmlwidgets::saveWidget(subplot(gga, ggb, ggd, nrows = 2, margin = .05, shareY = TRUE, which_layout = 2),"ply.html")
