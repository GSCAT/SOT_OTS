library(shiny)
library(plotly)
library(dplyr)
library(tidyr)

## Load YTD SOT and OTS Master objects
load("C:\\Users\\wenlu\\Documents\\SOTC-OTS\\Week 53\\Clean_Files\\SOT_Master_clean_object.rtf")
load("C:\\Users\\wenlu\\Documents\\SOTC-OTS\\Week 53\\Clean_Files\\OTS_Master_clean_object.rtf")

fis_yr <- 2017L
brand_vec <- c("GAP NA", "BR NA", "ON NA", "GO NA", "BRFS NA", "GAP INTL", "BR INTL", "ON INTL", "GO INTL", "ATHLETA")

# SOT by brand weekly trend  
SOT_viz_by_brand <- SOT_Master %>%
  filter(FISCAL_YEAR == fis_yr) %>%
  group_by(ReportingBrand, ShipCancelMonth, ShipCancelWeek) %>%
  summarise(TotalUnits= sum(Units), 
            OnTime = sum(Units[Lateness=="OnTime"]), 
            Late = sum(Units[Lateness=="Late"])) %>% 
  ungroup() %>% 
  mutate(SOT = round(OnTime/TotalUnits*100,2)) %>%
  gather("Lateness", "Units", OnTime:Late) %>% 
  droplevels() %>% 
  arrange(ShipCancelWeek)

SOT_viz_by_brand$Lateness <- as.factor((SOT_viz_by_brand$Lateness))
SOT_viz_by_brand$Lateness <- factor(SOT_viz_by_brand$Lateness, levels = rev(levels(SOT_viz_by_brand$Lateness)))

OTS_viz_by_brand <- OTS_Master %>%
  group_by(ReportingBrand, Month_Number,Week) %>%
  summarise(TotalUnits= sum(Units), 
            OnTime = sum(Units[Lateness=="OnTime"], na.rm = T), 
            Late = sum(Units[Lateness=="Late"])) %>% 
  ungroup() %>% 
  mutate(OTS = round(OnTime/TotalUnits*100,2)) %>%
  select(ReportingBrand, Month_Number,Week, OTS, TotalUnits, OnTime, Late) %>% 
  gather("Lateness", "Units", OnTime:Late) %>% 
  droplevels() %>% 
  arrange(Week)

OTS_viz_by_brand$Lateness <- as.factor(OTS_viz_by_brand$Lateness)
OTS_viz_by_brand$Lateness <- factor(OTS_viz_by_brand$Lateness, levels = rev(levels(OTS_viz_by_brand$Lateness)))

ui <- fluidPage(
  headerPanel("SOTC-OTS Weekly Trend"),
  selectInput('brand', 'Select A Brand', choices = brand_vec, selected = "ATHLETA"),
  tabPanel("tabPanel",
           fluidRow(
             column(width = 6, plotlyOutput("plotSOT")),
             column(width = 6, plotlyOutput("plotOTS"))
           ))
)

server <- function(input, output) {
  
  dtSOT <- reactive({
    subset(SOT_viz_by_brand,ReportingBrand == input$brand)
  })
  
  dtOTS <- reactive({
    subset(OTS_viz_by_brand,ReportingBrand == input$brand)
  })
  
  output$plotSOT <- renderPlotly({
    plot_ly(dtSOT()) %>% 
      add_trace(x = ~ShipCancelWeek, y = ~Units, color = ~Lateness, type = 'bar', colors = 'Paired') %>%
      add_trace(x = ~ShipCancelWeek, y = ~SOT, type = 'scatter', mode = 'lines', name = 'SOT (%)', yaxis = 'y2',
                line = list(color = '#1f78b4', width = 2)) %>% 
      layout(barmode = 'stack',
             yaxis  = list(side = 'left', showgrid = FALSE, zeroline = FALSE),
             yaxis2  = list(side = 'right',overlaying = "y"),
             title = paste(input$brand, 'Weekly SOT'))
  })
  output$plotOTS <- renderPlotly({
    plot_ly(dtOTS()) %>% 
      add_trace(x = ~Week, y = ~Units, color = ~Lateness, type = 'bar', colors = 'Paired') %>%
      add_trace(x = ~Week, y = ~OTS, type = 'scatter', mode = 'lines', name = 'OTS (%)', yaxis = 'y2',
                line = list(color = '#1f78b4', width = 2)) %>% 
      layout(barmode = 'stack',
             xaxis = list(title = 'Planned Stock Week'),
             yaxis  = list(side = 'left', showgrid = FALSE, zeroline = FALSE),
             yaxis2  = list(side = 'right',overlaying = "y"),
             title = paste(input$brand,'Weekly OTS'))
  })
  
  
}

shinyApp(ui, server)