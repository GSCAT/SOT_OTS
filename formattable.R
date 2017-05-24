library(formattable)
library(DT)
# library(plotly)

color.picker <- function(z){
  if(is.na(z)){return("black")}
  else if(z <= 20){return("red")}
  else if( z > 20 & z <= 80){return("darkorange")}
  else {return("darkgreen")}
}

bg.picker <- function(z){
  if(is.na(z)){return("black")}
  else if(z <= 20){return("pink")}
  else if( z > 20 & z <= 80){return("yellow")}
  else {return("lightgreen")}
}

sign_formatter <- formatter("span",
                            style = x ~ style(color = ifelse(x > 0, "DarkGreen",
                                                             ifelse(x < 0, "DarkRed", "black"))))

sign__bg_formatter <- formatter("span",
                                style = x ~ style(color = ifelse(x > 0, "DarkGreen",
                                                            ifelse(x < 0, "DarkRed", "black"))))


formatter(.tag = "span", style = function(x) style(display = "block", 
                                                   padding = "0 4px", 
                                                   `border-radius` = "4px", 
                                                   `background-color` = csscolor(gradient(as.numeric(x), ...))))

SOT_tile <-  formatter(.tag = "span", style = function(x) style(display = "block", 
                                                   padding = "0 4px", 
                                                   `border-radius` = "4px", 
                                                   `background-color` = ifelse(x > 0 , 
                                                                               csscolor(gradient(as.numeric(x), ...))))) 
                                                                            

sign_formatter(c(-1, 0, 1))

SOT_formatter <- formatter("span",
                            style = x ~ style("font-weight" = ifelse(x > .95, "bold", NA)))
                           
above_avg_bold <- formatter("span", 
                            style = x ~ style("font-weight" = ifelse(x > mean(x), "bold", NA)))

change_names <- function(x) {
  names(x) <- c("Brand", "Shipped On Time to Contract %", "% Variance from Target (95%)", "Transportation Impact", "Vendor Impact (Air)", "Vendor Impact (non-Air)", "Unmeasured Impact", "Total Impact")
}
# 
# change_units <- function(x){
#   
# }

names(Trans_output) <- change_names(Trans_output)

Trans_output$`Shipped On Time to Contract %` <- percent(Trans_output$`Shipped On Time to Contract %`, 1)
Trans_output$`% Variance from Target (95%)` <- percent(Trans_output$`% Variance from Target (95%)`, 1)
Trans_output$`Transportation Impact` <- percent(Trans_output$`Transportation Impact`, 1)
Trans_output$`Vendor Impact (Air)` <- percent(Trans_output$`Vendor Impact (Air)`, 1)
Trans_output$`Vendor Impact (non-Air)` <- percent(Trans_output$`Vendor Impact (non-Air)`, 1)
Trans_output$`Unmeasured Impact` <- percent(Trans_output$`Unmeasured Impact`, 1)
Trans_output$`Total Impact` <- percent(Trans_output$`Total Impact`, 1)


by_brand <- formattable(Trans_output, list( `Shipped On Time to Contract %` = SOT_formatter,
                                `% Variance from Target (95%)` = sign_formatter, 
                                `Transportation Impact` = color_tile("transparent", "lightpink"), 
                                `Vendor Impact (Air)` = color_tile("transparent", "lightpink"),
                                `Unmeasured Impact` = color_tile("transparent", "lightpink"),
                                `Vendor Impact (non-Air)` = color_tile("transparent", "lightpink")))

formattable(Trans_output)
