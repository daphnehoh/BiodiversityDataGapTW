library(shiny)
library(tidyverse)
library(leaflet)
library(leaflet.providers)
library(leaflet.extras)
library(rvest)
library(DT)
library(sp)
library(sf)
library(data.table)
library(plotly)

options(shiny.developer.mode = TRUE)

#####################
# SUPPORT FUNCTIONS #
#####################

# # function to retrieve a park image from the park wiki page
# park_image <- function (park_Name){
#   
#   #bug1_fix#
#   park_WikiUrl <- gsub(" ","_",paste0("https://en.wikipedia.org/wiki/",park_Name))
#   #bug1_fix#
#   park_Img <- read_html(park_WikiUrl)
#   park_Img <- park_Img %>% html_nodes("img")
#   
#   list_park_Img <- (grepl("This is a featured article", park_Img) | grepl("Question_book-new.svg.png", park_Img) | grepl("Listen to this article", park_Img) | grepl("This is a good article", park_Img))
#   park_Img <- park_Img[min(which(list_park_Img == FALSE))]
#   
#   park_Img <- gsub("\"","'",park_Img)
#   park_Img <- gsub("//upload.wikimedia.org","https://upload.wikimedia.org",park_Img)
#   park_Img <- sub("<img","<img style = 'max-width:100%; max-height:200px; margin: 10px 0px 0px 0px; border-radius: 5%; border: 1px solid black;'",park_Img)
#   
#   return(park_Img)
#   
# }
#   
# # function that build the park card html pop up
# park_card <- function (park_Name, park_Code, park_State, park_Acres, park_Latitude, park_Longitude) {
#   
#   card_content <- paste0("<style>div.leaflet-popup-content {width:auto !important;}</style>",
#                     "<link rel='stylesheet' href='https://use.fontawesome.com/releases/v5.7.1/css/all.css' integrity='sha384-fnmOCqbTlWIlj8LyTjo7mOUStjsKC4pOpQbqyi7RrhN7udi9RwhKkMHpvLbHG9Sr' crossorigin='anonymous'>",
#                     "<table style='width:100%;'>",
#                     "<tr>",
#                     "<th><b><h2 style='text-align: left;'>",park_Name,"</h2></b></th>",
#                     "<th><img style = 'border:1px solid black;' src='https://www.crwflags.com/art/states/",park_State,".gif' alt='flag' title='Flag of ",state.name[match(park_State,state.abb)]," ' width=80></th>",
#                     "</tr>",
#                     "</table>",
#                     "<div class='flip-card'>",
#                       "<div class='flip-card-inner'>",
#                         "<div class='flip-card-front'>",
#                           "<table style='width:100%;'>",
#                             "<tr>",
#                               "<td colspan='2'>",park_image(park_Name),"</td>",
#                             "</tr>",
#                             "<tr>",
#                               "<td style='padding: 5px;'><h4><b>Code: </b>",park_Code,"</h4></td>",
#                               "<td style='padding: 5px;'><h4><b>Acres: </b>",format(park_Acres, big.mark = ' '),"</h4></td>",
#                             "</tr>",
#                             "<tr>",
#                               "<td style='padding: 5px;'><h4><b>Latitude: </b>",park_Latitude,"</h4></td>",
#                               "<td style='padding: 5px;'><h4><b>Longitude: </b>",park_Longitude,"</h4></td>",
#                             "</tr>",
#                           "</table>",
#                         "</div>",
#                         "<div class='flip-card-back'>",
#                           "<h3>Media links</h3> ",
#                           "<hr>",
#                           "<table style='width:80%;'>",
#                             "<tr>",
#                               "<td style='text-align: left; padding-left: 25px;'><h4>Official page:</h4></td>",
#                               "<td><a style='color:white;' href='https://www.nps.gov/",park_Code,"/index.htm' target='_blank'><i class='fas fa-globe fa-2x'></i></a></td>",
#                             "</tr>",
#                             "<tr>",
#                               "<td style='text-align: left; padding-left: 25px;'><h4>Wikipedia page:<h4></td>",
#                               "<td><a style='color:white' href='https://en.wikipedia.org/wiki/",park_Name,"' target='_blank'><i class='fab fa-wikipedia-w fa-2x'></i></td></p>",
#                             "</tr>",        
#                             "<tr>",
#                               "<td style='text-align: left; padding-left: 25px;'><h4>Pictures:<h4></td>",
#                               "<td><a style='color:white' href='https://www.google.com/search?tbm=isch&q=",park_Name,"&tbs=isz:m' target='_blank'><i class='fas fa-images fa-2x'></i></a></td>",
#                             "</tr>",
#                             "<tr>",
#                               "<td style='text-align: left; padding-left: 25px;'><h4>Youtube videos:<h4></td>",
#                               "<td><a style='color:white' href='https://www.youtube.com/results?search_query=",park_Name,"' target='_blank'><i class='fab fa-youtube fa-2x'></i></td>",
#                             "</tr>",
#                           "</table>",
#                         "</div>",
#                       "</div>",
#                     "</div>"
#   )
#   
#   return(card_content)
#   
# }
# 
# ##################
# # DATA WRANGLING #
# ##################
# 
# # preprocessed parks file:
# #   3 records were multi states parks, only was was attributed
# #     DEVA,Death Valley National Park,CA/NV,4740912,36.24,-116.82  --> CA
# #     GRSM,Great Smoky Mountains National Park,TN/NC,521490,35.68,-83.53 --> TN
# #     YELL,Yellowstone National Park,WY/MT/ID,2219791,44.6,-110.5 --> WY
# #   added (U.S.) suffix to Glacier National Park record for wiki disambigaution
# 
# parks <- read.csv("www/parks.csv")
# species <- read.csv("www/species.csv")
# 
# # tidy & enrich dataframes
# levels(species$Park.Name)[levels(species$Park.Name)=='Glacier National Park'] <- 'Glacier National Park (U.S.)'
# parks$Acres <- as.numeric(parks$Acres)
# parks$Latitude <- as.numeric(parks$Latitude)
# parks$Longitude <- as.numeric(parks$Longitude)
# 
# parks <- parks %>%
#   mutate(
#     ParkRegion = state.region[match(parks$State,state.abb)]
#   )
# 
# parks$ParkGroup <- ""
# parks$ParkGroup[1:28] <- "First Group"
# parks$ParkGroup[29:56] <- "Second Group"
# 
# species <- species %>%
#   mutate(
#     ParkRegion = parks$ParkRegion[match(substr(species$Species.ID,1,4),parks[,c("ParkCode")])]
#   )
# 
# species <- species %>%
#   mutate(
#     ParkGroup = parks$ParkGroup[match(substr(species$Species.ID,1,4),parks[,c("ParkCode")])]
#   )
# 
# species <- species %>%
#   mutate(
#     ParkState = parks$State[match(species$Park.Name,parks$ParkName)]
#   )
# 
# # support structures
# parksNames <- sort(as.character(unique(species[,c("Park.Name")])))
# speciesCategories <- sort(as.character(unique(species[,c("Category")])))
# speciesCategoriesByState <- species %>% group_by(Category, ParkState) %>% tally(sort=TRUE)
# states <- states(cb=T)
# speciesStates <- sort(as.character(unique(speciesCategoriesByState$ParkState[complete.cases(speciesCategoriesByState)]))) 

################
# SERVER LOGIC #
################

# Occurrence table
# tbia <- fread("C:/Users/taibi/OneDrive/Desktop/Daphne/tmp/sample_n_100_taxaSubGroup_dQgood.csv",
#               sep = ",", colClasses = "character", encoding = "UTF-8")

tbia <- fread("/Users/daphne/Documents/GitHub/BiodiversityDataGapTW/shinyapp/BiodiversityDataGapTW-shinyapp/tmp/tmp/sample_n_100_taxaSubGroup_dQgood.csv",
              sep = ",", colClasses = "character", encoding = "UTF-8")

tbia.color_6 <- c("#3E5145", "#76A678", "#E5C851", "#E2A45F", "#F8E3C4", "#C75454")




shinyServer(function(input, output, session) {
  
  
  
  # Section: Taxonomic Gap
  ## Pie stats
  ## % record matched to highest taxon rank
  output$taxa.pie.taxonRank <- renderPlotly({
    
    df_taxa.rank <- fread("/Users/daphne/Documents/GitHub/BiodiversityDataGapTW/shinyapp/BiodiversityDataGapTW-shinyapp/www/data/df_taxa.rank.csv",
                          sep = ",", colClasses = "character", encoding = "UTF-8", na.strings = c("", "NA", "N/A"))
    
    plot_ly(df_taxa.rank, labels = ~taxonRank, values = ~count, type = "pie", sort = F,
            hoverinfo = "label+value", textinfo = "percent", marker = list(colors = tbia.color_6)) %>%
      config(displayModeBar = FALSE)
    
  })
  
  ## % record species rank matched to TaiCOL
  output$taxa.pie.TaiCOL <- renderPlotly({
    
    df_taxa.rank.at.species <- fread("/Users/daphne/Documents/GitHub/BiodiversityDataGapTW/shinyapp/BiodiversityDataGapTW-shinyapp/www/data/df_taxa.rank.at.species.csv",
                                     sep = ",", colClasses = "character", encoding = "UTF-8", na.strings = c("", "NA", "N/A"))
    
    plot_ly(df_taxa.rank.at.species, labels = ~category, values = ~count, type = "pie", sort = F,
            hoverinfo = "label+value", textinfo = "percent", marker = list(colors = tbia.color_6)) %>%
      config(displayModeBar = FALSE)
    
  })
  
  
  
  ## The unrecorded taxa
  output$taxa.landtype.taxa.prop <- renderUI({
    selectInput("taxa.landtype.taxa.prop", "Select habitat:", c("All", "is_terrestrial", "is_freshwater", "is_brackish", "is_marine"))
  })
  
  output$taxa.landtype.taxa.prop.count <- renderUI({
    selectInput("taxa.landtype.taxa.prop.count", "Select visualization:", c("Count", "Proportion"))
  })
  
  output$taxa.bar.unrecorded.taxa <- renderPlotly({
    
    if (input$taxa.landtype.taxa.prop == "All") {
      
      ## if habitat == "All"
      df_taxa.unrecorded.taxa.prop.groupAll <- 
        fread("/Users/daphne/Documents/GitHub/BiodiversityDataGapTW/shinyapp/BiodiversityDataGapTW-shinyapp/www/data/df_taxa.unrecorded.taxa.prop.groupAll.csv",
        sep = ",", colClasses = "character", encoding = "UTF-8", na.strings = c("", "NA", "N/A"))
      
      plot_data <- plot_ly(df_taxa.unrecorded.taxa.prop.groupAll, x = ~taxaSubGroup, type = 'bar', name = 'Unrecorded', y = ~cum.total,
                           hoverinfo = 'text', text = ~paste0("Unrecorded species: ", cum.total), textposition = "none") %>%
        add_trace(y = ~record.count, name = "Recorded", marker = list(color = tbia.color_6[6]),
                  hoverinfo = 'text', text = ~paste0("Total species via TaiCOL: ", taicol.count, "<br>Recorded species: ", record.count), textposition = "none")
      
    } else {
      
      ## if habitat == one of the "is_*"
      df_counts_by_habitats <- 
        fread("/Users/daphne/Documents/GitHub/BiodiversityDataGapTW/shinyapp/BiodiversityDataGapTW-shinyapp/www/data/df_counts_by_habitats.csv",
              sep = ",", colClasses = "character", encoding = "UTF-8", na.strings = c("", "NA", "N/A"))
      
      ## select habitat
      selected_habitat <- input$taxa.landtype.taxa.prop
      df_subset <- df_counts_by_habitats[df_counts_by_habitats$habitat == selected_habitat, ]
      
      plot_data <- plot_ly(df_subset, x = ~taxaSubGroup, type = 'bar', name = 'Unrecorded', y = ~cum.total,
                           hoverinfo = 'text', text = ~paste0("Unrecorded species: ", cum.total), textposition = "none") %>%
        add_trace(y = ~record.count, name = 'Recorded', marker = list(color = tbia.color_6[6]),
                  hoverinfo = 'text', text = ~paste0("Total species via TaiCOL: ", taicol.count, "<br>Recorded species: ", record.count), textposition = "none")
      
    }
    
    # Customize layout and configuration for the plot
    plot_data <- plot_data %>%
      layout(barmode = 'stack', 
             xaxis = list(title = "Taxa group", tickangle = 45), 
             yaxis = list(title = "Record count", tickvals = seq(0, 12000, 500)),
             legend = list(x = 0, y = 1.1, orientation = "h")) %>%
        config(displayModeBar = FALSE)
      
    # Return the plotly object
    return(plot_data)

  })
  
  
  
  # Section: Species Tree
  ## collapsible tree
  df_tree <- 
    fread("/Users/daphne/Documents/GitHub/BiodiversityDataGapTW/shinyapp/BiodiversityDataGapTW-shinyapp/www/data/df_tree.csv",
          sep = ",", colClasses = "character", encoding = "UTF-8", na.strings = c("", "NA", "N/A"))
  
  output$taxa.treeSubGroup <- renderUI({
    selectInput("taxa.treeSubGroup", "Select taxa group:", sort(unique(df_tree$taxaSubGroup)))
  })
  
  speciesTree <- reactive({
    req(input$taxa.treeSubGroup)
    filtered_data <- df_tree %>%
      filter(taxaSubGroup == input$taxa.treeSubGroup) %>%
      arrange(family, genus, recorded)
    return(filtered_data)
  })

  output$tree <- renderCollapsibleTree({
    collapsibleTree(
      speciesTree(),
      root = input$taxa.treeSubGroup,
      attribute = "taxaSubGroup",
      hierarchy = c("family", "genus", "recorded"))
  })
  
  
  
  # Section: Temporal Gap
  ## load time data
  df_time <- reactive({
    fread("/Users/daphne/Documents/GitHub/BiodiversityDataGapTW/shinyapp/BiodiversityDataGapTW-shinyapp/www/data/df_time.csv",
          sep = ",", colClasses = "character", encoding = "UTF-8", na.strings = c("", "NA", "N/A"))
  })

  ## Update taxaSubGroup choices
  observe({
    updateSelectizeInput(session, 'time.taxaSubGroup', choices = unique(df_time()$taxaSubGroup), server = TRUE)
  })
  
  ## Filtered data based on year range, month, and taxaSubGroup
  filtered_data <- reactive({
    req(input$time.year)
    data_filtered <- df_time() %>%
      filter(year >= input$time.year[1] & year <= input$time.year[2])
    
    if (!is.null(input$time.month)) {
      data_filtered <- data_filtered %>%
        filter(month %in% input$time.month)
    }
    
    if (!is.null(input$time.taxaSubGroup)) {
      data_filtered <- data_filtered %>%
        filter(taxaSubGroup %in% input$time.taxaSubGroup)
    }
    
    data_filtered
  })
  
  ## Render year bar chart
  output$time.yearBarChart <- renderPlotly({
    plot_ly(filtered_data(), x = ~year, type = "histogram", marker = list(color = "#76A678")) %>%
      layout(xaxis = list(title = "Year"), yaxis = list(title = "Record count")) %>%
      config(displayModeBar = FALSE)
  })
  
  ## Render month bar chart
  output$time.monthBarChart <- renderPlotly({
    req(input$time.month)
    plot_ly(filtered_data(), x = ~month, type = "histogram", marker = list(color = "#76A678")) %>%
      layout(xaxis = list(title = "Month"), yaxis = list(title = "Record count")) %>%
      config(displayModeBar = FALSE)
  })

  
  
  # Section : Spatial
  ## Load taxa table
  df_spatial_allOccCount_grid_table <- fread("/Users/daphne/Documents/GitHub/BiodiversityDataGapTW/shinyapp/BiodiversityDataGapTW-shinyapp/www/data/df_spatial_allOccCount_grid_table.csv",
                                             sep = ",", colClasses = "character", encoding = "UTF-8", na.strings = c("", "NA", "N/A"))
  
  output$df_spatial_allOccCount_grid_table <- renderDT({
    datatable(df_spatial_allOccCount_grid_table,
              options = list(searching = FALSE, lengthMenu = list(c(10, -1), c('10', 'All'))))
  })
  
  # Load map data
  df_map <- st_read("/Users/daphne/Documents/GitHub/BiodiversityDataGapTW/shinyapp/BiodiversityDataGapTW-shinyapp/www/data/df_map.shp")
  pal_map <- colorNumeric(palette = "YlOrRd", domain = df_map$occCount)
  
  df_taxa_map <- st_read("/Users/daphne/Documents/GitHub/BiodiversityDataGapTW/shinyapp/BiodiversityDataGapTW-shinyapp/www/data/df_taxa_map.shp")
  pal_taxa <- colorNumeric(palette = "YlOrRd", domain = df_taxa_map$occCount)
  
  ## show maps
  df_taxa_map_selected <- reactive({
    req(input$spatial.taxaSubGroup)  # Require input$spatial.taxaSubGroup to be available
    df_taxa_map %>%
      filter(tSG %in% input$spatial.taxaSubGroup)
  })

  # ## Render the spatialMap based on selection
  output$spatialMap <- renderLeaflet({
    if (input$showAll) {

      leaflet() %>%
        addTiles() %>%
        setView(lng = 120.5, lat = 22.5, zoom = 7) %>%
        addProviderTiles(providers$Stadia, group = "Stadia") %>%
        addProviderTiles(providers$Stadia.Outdoors, group = "Stadia.Outdoors") %>%
        addProviderTiles(providers$Esri.OceanBasemap, group = "Esri.OceanBasemap") %>%
        addLayersControl(
          baseGroups = c("OSM", "Stadia", "Stadia.Outdoors", "Esri.OceanBasemap"),
          options = layersControlOptions(collapsed = TRUE)) %>%
        addResetMapButton() %>%
        addPolygons(
          data = df_map,
          fillColor = ~pal_map(occCount),
          weight = 1,
          opacity = 0.5,
          color = 'orange',
          fillOpacity = 0.5,
          popup = ~paste("Number of records:", occCount)) %>%
        addLegend(
          data = df_map,
          pal = pal_map,
          values = ~occCount,
          opacity = 0.5,
          title = "Record count",
          position = "bottomright")

      } else {

        leaflet() %>%
          addTiles() %>%
          setView(lng = 120.5, lat = 22.5, zoom = 7) %>%
          addProviderTiles(providers$Stadia, group = "Stadia") %>%
          addProviderTiles(providers$Stadia.Outdoors, group = "Stadia.Outdoors") %>%
          addProviderTiles(providers$Esri.OceanBasemap, group = "Esri.OceanBasemap") %>%
          addLayersControl(
            baseGroups = c("OSM", "Stadia", "Stadia.Outdoors", "Esri.OceanBasemap"),
            options = layersControlOptions(collapsed = TRUE)) %>%
          addResetMapButton() %>%
          addPolygons(
            data = df_taxa_map_selected(),
            fillColor = ~pal_taxa(occCount),
            weight = 1,
            opacity = 0.3,
            color = 'blue',
            fillOpacity = 0.5,
            popup = ~paste("Number of records:", occCount)) %>%
          addLegend(
            data = df_map,
            pal = pal_map,
            values = ~occCount,
            opacity = 0.5,
            title = "Record count",
            position = "bottomright")

    }
  })

  # Update selectizeInput choices based on df_spatial_allOccCount_grid_table
  observe({
    updateSelectizeInput(session, 'spatial.taxaSubGroup', choices = unique(df_spatial_allOccCount_grid_table$taxaSubGroup), server = TRUE)
  })

  # Update checkbox based on selection
  observeEvent(input$spatial.taxaSubGroup, {
    if (is.null(input$spatial.taxaSubGroup) || length(input$spatial.taxaSubGroup) == 0) {
      updateCheckboxInput(session, "showAll", value = TRUE)
    } else {
      updateCheckboxInput(session, "showAll", value = FALSE)
    }
  })

  
  
  # Section: Fill gap
  ## gapCount table
  gapCountdf <- fread("/Users/daphne/Documents/GitHub/BiodiversityDataGapTW/shinyapp/BiodiversityDataGapTW-shinyapp/www/data/df_gapCount_table.csv",
                      sep = ",", encoding = "UTF-8", na.strings = c("", "NA", "N/A")) %>% na.omit()
  
  gapCountdf_sorted <- gapCountdf[order(factor(gapCountdf$priority, levels = c("high", "medium", "low"))), ]
  
  output$gapCount <- renderDT({
    datatable(gapCountdf_sorted, options = list(searching = FALSE, paging = FALSE))
  })
  
  
  ## gapMap
  ## grid layer
  occ.grid5km_sf <- st_read("/Users/daphne/Documents/GitHub/BiodiversityDataGapTW/shinyapp/BiodiversityDataGapTW-shinyapp/tmp/to_grid5km.shp")
  pal <- colorNumeric(palette = "YlOrRd", domain = occ.grid5km_sf$allOccC)
  
  output$gapMap <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = 120, lat = 23, zoom = 7) %>%
      addProviderTiles(providers$Stadia, group = "Stadia") %>%
      addProviderTiles(providers$Stadia.Outdoors, group = "Stadia.Outdoors") %>%
      addProviderTiles(providers$Esri.OceanBasemap, group = "Esri.OceanBasemap") %>%
      addLayersControl(
        baseGroups = c("OSM", "Stadia", "Stadia.Outdoors", "Esri.OceanBasemap"),
        options = layersControlOptions(collapsed = TRUE)) %>%
      addResetMapButton() %>%
      addPolygons(
        data = occ.grid5km_sf,
        fillColor = ~pal(nmbr_f_),
        weight = 1,
        opacity = 1,
        color = 'white',
        fillOpacity = 0.5,
        popup = ~paste("Number of records:", nmbr_f_)) %>%
      addLegend(
        data = occ.grid5km_sf,
        pal = pal,
        values = ~nmbr_f_,
        opacity = 0.5,
        title = "Record count",
        position = "bottomright")
  })


})