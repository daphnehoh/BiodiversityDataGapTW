library(shiny)
library(ggplot2)

## ui
ui <- fluidPage(
  
  titlePanel("Baby Name Explorer"),
  
  sidebarLayout(
    sidebarPanel(textInput('name', 'Enter name', 'David')),
    sidebarPanel(selectInput('animal', 'label', choices = c('Dog',"Cat")),
    mainPanel(plotOutput('trend')),
    sidebarPanel(textOutput('answer'))
  )
  
)

## server
server <- function(input, output, session){
  
  output$trend <- renderPlot({
    
    data_name <- subset(babynames, name == input$name)
    ggplot(data_name) +
      geom_line(aes, x = year, y = prop, color = sex)
    
  })
  
  output$answer <- renderText({
    paste("I prefer", input$animal)
    })
  
}

shinyApp(ui = ui, server = server)




##### eg 1
ui <- fluidPage(
  titlePanel("What's in a Name?"),

  selectInput('sex', 'Select Sex', choices = c("F", "M")),
  sliderInput("year", "Number of observations:", min = 1900, max = 2010, value = 1900),
  
  plotOutput('plot_top_10_names')
)

server <- function(input, output, session){

  output$plot_top_10_names <- renderPlot({
    top_10_names <- babynames %>% 
      filter(sex == input$sex) %>% 
      filter(year == input$year) %>% 
      slice_max(prop, n = 10)
    
    # Plot top 10 names by sex and year
    ggplot(top_10_names, aes(x = name, y = prop)) +
      geom_col(fill = "#263e63")
  })
}


### Outputs
tableOutput()
dataTableOutput()
imageOutput()
plotOutput

### other packages derived from htmlwidgets
# interactive tables
DToutput()
renderDT()
# leaflet
# plotly

##### eg 2 table
ui <- fluidPage(
  titlePanel("What's in a Name?"),
  # Add select input named "sex" to choose between "M" and "F"
  selectInput('sex', 'Select Sex', choices = c("F", "M")),
  # Add slider input named "year" to select year between 1900 and 2010
  sliderInput('year', 'Select Year', min = 1900, max = 2010, value = 1900),
  # CODE BELOW: Add table output named "table_top_10_names"
  tableOutput('table_top_10_names')
)

server <- function(input, output, session){
  # Function to create a data frame of top 10 names by sex and year 
  top_10_names <- function(){
    babynames %>% 
      filter(sex == input$sex) %>% 
      filter(year == input$year) %>% 
      slice_max(prop, n = 10)
  }
  # CODE BELOW: Render a table output named "table_top_10_names"
  output$table_top_10_names <- renderTable({
    top_10_names()
  })
  
}

shinyApp(ui = ui, server = server)

#### eg 3 DT
ui <- fluidPage(
  titlePanel("What's in a Name?"),
  # Add select input named "sex" to choose between "M" and "F"
  selectInput('sex', 'Select Sex', choices = c("M", "F")),
  # Add slider input named "year" to select year between 1900 and 2010
  sliderInput('year', 'Select Year', min = 1900, max = 2010, value = 1900),
  # Add plot output to display top 10 most popular names
  DT::DTOutput('table_top_10_names')
)

server <- function(input, output, session){
  top_10_names <- function(){
    babynames %>% 
      filter(sex == input$sex) %>% 
      filter(year == input$year) %>% 
      slice_max(prop, n = 10)
  }
  # MODIFY CODE BELOW: Render a DT output named "table_top_10_names"
  output$table_top_10_names <- DT::renderDT({
    DT::datatable(top_10_names())
  })
}

shinyApp(ui = ui, server = server)

#### eg 4 plotly
ui <- fluidPage(
  selectInput('name', 'Select Name', top_trendy_names$name),
  # CODE BELOW: Add a plotly output named 'plot_trendy_names'
  plotly::plotlyOutput('plot_trendy_names')
  
)

server <- function(input, output, session){
  # Function to plot trends in a name
  plot_trends <- function(){
    babynames %>% 
      filter(name == input$name) %>% 
      ggplot(aes(x = year, y = n)) +
      geom_col()
  }
  # CODE BELOW: Render a plotly output named 'plot_trendy_names'
  output$plot_trendy_names <- plotly::renderPlotly({
    plot_trends()
    
  })
}

shinyApp(ui = ui, server = server)

#### eg 4 plotly in panels
ui <- fluidPage(
  # MODIFY CODE BLOCK BELOW: Wrap in a sidebarLayout
  sidebarLayout(
    # MODIFY CODE BELOW: Wrap in a sidebarPanel
    sidebarPanel(
      selectInput('name', 'Select Name', top_trendy_names$name)
    ),
    # MODIFY CODE BELOW: Wrap in a mainPanel
    mainPanel(
      plotly::plotlyOutput('plot_trendy_names'),
      DT::DTOutput('table_trendy_names')
    )
  )
)

server <- function(input, output, session){
  # Function to plot trends in a name
  plot_trends <- function(){
    babynames %>% 
      filter(name == input$name) %>% 
      ggplot(aes(x = year, y = n)) +
      geom_col()
  }
  output$plot_trendy_names <- plotly::renderPlotly({
    plot_trends()
  })
  
  output$table_trendy_names <- DT::renderDT({
    babynames %>% 
      filter(name == input$name)
  })
}

shinyApp(ui = ui, server = server)


#### eg 6 plotly with 2 panels on mainPanel
ui <- fluidPage(
  
  titlePanel('Top Trendy Names'),
  theme = shinythemes::shinytheme("cerulean"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput('name', 'Select Name', top_trendy_names$name)
    ),
    mainPanel(
      # MODIFY CODE BLOCK BELOW: Wrap in a tabsetPanel
      tabsetPanel(
        # MODIFY CODE BELOW: Wrap in a tabPanel providing an appropriate label
        tabPanel("Plot",
                 plotly::plotlyOutput('plot_trendy_names')
        ),
        # MODIFY CODE BELOW: Wrap in a tabPanel providing an appropriate label
        tabPanel("Table",
                 DT::DTOutput('table_trendy_names')
        )
      )
    )
  )
)

server <- function(input, output, session){
  # Function to plot trends in a name
  plot_trends <- function(){
    babynames %>% 
      filter(name == input$name) %>% 
      ggplot(aes(x = year, y = n)) +
      geom_col()
  }
  output$plot_trendy_names <- plotly::renderPlotly({
    plot_trends()
  })
  
  output$table_trendy_names <- DT::renderDT({
    babynames %>% 
      filter(name == input$name)
  })
}

shinyApp(ui = ui, server = server)


##### eg 7
ui <- fluidPage(
  selectInput('greeting', 'Hello', choices = c("Hello","Bonjour")),
  textInput('name', 'Enter name', 'Kaelen'),
  sidebarPanel(textOutput('answer'))
)

server <- function(input, output, session) {
  output$answer <- renderText({
    paste(input$greeting, ",", input$name)
  })
}

shinyApp(ui = ui, server = server)

#### eg 8 checkboxGroupInput
ui <- fluidPage(
  titlePanel("Sleeping habits in America"), 
  checkboxInput("checkboxlabel",
                "Display year", value = TRUE),
  # Add a group of checkboxes
  checkboxGroupInput("days", "Choose types of days:",
                     choiceNames = list("All", "Nonholiday", "Weekends and holidays"),
                     choiceValues = list("All days", "Nonholiday weekdays", "Weekend days and holidays"),
                     # "All days" checkbox is initially selected
                     selected = "All days"))
server <- function(input, output, session) {
}

shinyApp(ui, server)


#### eg 9 plot or table
ui <- fluidPage(
  titlePanel("Sleeping habits in America"), 
  # Place a selectInput with two choices, "Plot" and "Table"
  selectInput("choice", "Choose an output",
              choices = c("Plot", "Table")),
  # Place plot and table outputs called "plot" and "table"
  plotOutput("plot"), tableOutput("table")
)

server <- function(input, output) {
  # Add renderPlot
  output$plot <- renderPlot({
    if(input$choice == "Plot") p
  })
  # Add renderTable
  output$table <- renderTable({
    if(input$choice == "Table") sleep
  }) }

shinyApp(ui, server)


#### eg 10 put icons in choices
ui <- fluidPage(
  titlePanel("Sleeping habits in America"), 
  fluidRow(
    # Place two plots here, called "histogram" and "barchart"
    mainPanel(plotOutput("histogram"), plotOutput("barchart")), 
    inputPanel(sliderInput("binwidth", 
                           label = "Bin width", 
                           min = 0.1, max = 2, 
                           step = 0.01, value=0.25),
               checkboxGroupInput("days", "Choose types of days:",
                                  # Replace the list elements with icons called "calendar", "briefcase" and "gift"
                                  choiceNames = list(icon("calendar"), icon("briefcase"), icon("gift")), 
                                  choiceValues = list("All days", 
                                                      "Nonholiday weekdays", 
                                                      "Weekend days and holidays"))), 
    "In general, across the different age groups, Americans seem to get adequate daily rest." ))

server <- function(input, output, session) {
  # Define the histogram and barchart
  output$histogram <- renderPlot({
    ggplot(sleep, aes(x=`Avg hrs per day sleeping`)) + 
      geom_histogram(binwidth = input$binwidth, col='white') + 
      theme_classic()
  })
  output$barchart <- renderPlot({
    filter(sleep, `Type of Days` %in% input$days) %>%
      group_by(`Type of Days`, `Age Group`) %>%
      summarize(`Median hours` = median(`Avg hrs per day sleeping`)) %>%
      ggplot(aes(x = `Median hours`, y = `Age Group`, fill = `Type of Days`)) +
      geom_col(position = 'dodge') + theme_classic()
  })
}

# Use shinyApp() to render the shinyApp
shinyApp(ui, server)



#### eg 11 infoBox
body <- dashboardBody(tabItems(
  tabItem(tabName = "matchtab", 
          fluidRow(selectInput("match", "Match number", choices = 1:nrow(soccer)),
                   infoBoxOutput("daytime"), infoBoxOutput("venue"), infoBoxOutput("grp")),
          fluidRow(valueBoxOutput("team1", width = 3), valueBoxOutput("score1", width = 3), 
                   valueBoxOutput("team2", width = 3), valueBoxOutput("score2", width = 3)),
          fluidRow(plotOutput("histogram"))),
  tabItem(tabName = "statstab", 
          tabBox(tabPanel("Goals", plotOutput("goals", height = "700px")),
                 tabPanel("Yellow cards", plotOutput("yellow", height = "700px")),
                 tabPanel("Red cards", plotOutput("red"))))
))

ui <- dashboardPage(header, sidebar, body)

server <- function(input, output) {
  # Fill in outputs in first to third rows of the first page
  output$daytime <- renderInfoBox(infoBox("Day and time", 
                                          daytime_fn(input$match), 
                                          icon = icon("calendar"), 
                                          color = "green"))
  output$venue <- renderInfoBox(infoBox("Venue", 
                                        venue_fn(input$match), 
                                        icon = icon("map"), 
                                        color = "green"))
  output$group <- renderInfoBox(infoBox("Group", 
                                        grp_fn(input$match), 
                                        color = "green"))
  output$team1 <- renderInfoBox(valueBox("Team 1", team1_fn(input$match), color = "blue"))
  output$score1 <- renderInfoBox(valueBoxOutput("# of goals", score1_fn(input$match), color = "blue"))
  output$team2 <- renderInfoBox(valueBox("Team 2", team2_fn(input$match), color = "red")) 
  output$score2 <- renderInfoBox(valueBox("# of goals", score2_fn(input$match), color = "red"))
  output$histogram <- renderPlot(plot_histogram(input$match))
  
  # Fill in outputs in the second page
  output$goals <- renderPlot(goals_plot)
  output$yellow <- renderPlot(yellow_plot)
  output$red <- renderPlot(red_plot)
}

# Put the UI and server together
shinyApp(ui, server)


#### eg 12 leaflet
m_london <- leaflet(london_poly)%>%  
  addTiles(group="Default")%>%  
  addProviderTiles(providers$Stamen.Toner, group ="Toner")%>%  
  addProviderTiles(providers$Esri.NatGeoWorldMap, group ="Nat Geo")%>%  
  addPolygons(col="red", label=~Name,group ="Ward")%>%  
  addPolylines(loop_geo[,1], loop_geo[,2],group ="London loop")%>%  
  addPolylines(capital_geo[,1], capital_geo[,2], labelOptions = labelOptions(noHide =TRUE),color ="orange", group ="Capital ring",)%>%  
  addMarkers(data = listings_geo, clusterOptions = markerClusterOptions(), group ="Listings")%>%  
  addLayersControl(baseGroups =c("Default","Toner","Nat Geo"), overlayGroups =c("Ward","Listings","London loop","Capital loop"))




#### test code
library(leaflet)
library(dplyr)
library(data.table)
library(sf)
library(st)
library(leaflet.extras)



tbia <- fread("C:/Users/taibi/OneDrive/Desktop/Daphne/tmp/sample_n_100_taxaSubGroup_dQgood.csv",
              sep = ",", colClasses = "character", encoding = "UTF-8")


### get coords from tbia
df1 <- tbia[1:10, c("longitude", "latitude", "type", "taxaSubGroup")]
df1$longitude <- as.numeric(df1$longitude)
df1$latitude <- as.numeric(df1$latitude)
coords_sf <- st_as_sf(df1, coords = c("longitude", "latitude"), crs = 4326)

# coords_df <- coords_sf %>% 
#   mutate(lng = st_coordinates(.)[,1], lat = st_coordinates(.)[,2]) %>% 
#   as.data.frame()

### 5km grid
#grid5km_sf <- st_read("C:/Users/taibi/OneDrive/Desktop/Daphne/layers/TW_WGS84_land&ocean_grids/0_05degree_tw_landocean_grid.shp")

m <- 
  leaflet() %>%
  addTiles() %>%
  #addPolygons(data = grid5km_sf, color = "blue", fillOpacity = 0.05, opacity = 0.3, weight = 2) %>%
  addMarkers(data = coords_sf) %>%
  #setView(lng = 120, lat = 21) %>%
  addResetMapButton() %>%
  addLayersControl(
    baseGroups = unique(tbia$type),
    options = layersControlOptions(collapsed = TRUE))




### shp with occ fit into grid
occ.grid5km_sf <- st_read("C:/Users/taibi/OneDrive/Desktop/Daphne/to_grid5km.shp")

# Create a color palette
pal <- colorNumeric(
  palette = "YlOrRd",
  domain = occ.grid5km_sf$nmbr_f_
)

m <-
  leaflet() %>%
  addTiles() %>%
  setView(lng = 120, lat = 21, zoom = 7) %>%
  addResetMapButton() %>%
  addPolygons(
    data = occ.grid5km_sf,
    fillColor = ~pal(nmbr_f_),
    weight = 1,
    opacity = 1,
    color = 'white',
    fillOpacity = 0.5,
    popup = ~paste("Number of records:", nmbr_f_)
  ) %>%
  addLegend(
    data = occ.grid5km_sf,
    pal = pal,
    values = ~nmbr_f_,
    opacity = 0.5,
    title = "Record count",
    position = "bottomright"
  ) 

m








