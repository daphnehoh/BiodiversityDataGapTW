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

# TBIA colour theme
tbia.color_6 <- c("#3E5145", "#76A678", "#E5C851", "#E2A45F", "#F8E3C4", "#C75454")


shinyServer(function(input, output, session) {
  
  
  # Section: Taxonomic Gap
  ## Pie stats
  ## % record matched to highest taxon rank
  output$taxa.pie.taxonRank <- renderPlotly({
    
    df_taxa.rank <- fread("www/data/processed/df_taxa.rank.csv",
                          sep = ",", colClasses = "character", encoding = "UTF-8", na.strings = c("", "NA", "N/A"))
    
    plot_ly(df_taxa.rank, labels = ~taxonRank, values = ~count, type = "pie", sort = F,
            hoverinfo = "label+value", textinfo = "percent", marker = list(colors = tbia.color_6)) %>%
      config(displayModeBar = FALSE)
    
  })
  
  ## % record species rank matched to TaiCOL
  output$taxa.pie.TaiCOL <- renderPlotly({
    
    df_taxa.rank.at.species <- fread("www/data/processed/df_taxa.rank.at.species.csv",
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
        fread("www/data/processed/df_taxa.unrecorded.taxa.prop.groupAll.csv",
        sep = ",", colClasses = "character", encoding = "UTF-8", na.strings = c("", "NA", "N/A"))
      
      plot_data <- plot_ly(df_taxa.unrecorded.taxa.prop.groupAll, x = ~taxaSubGroup, type = 'bar', name = 'Unrecorded', y = ~cum.total,
                           hoverinfo = 'text', text = ~paste0("Unrecorded species: ", cum.total), textposition = "none") %>%
        add_trace(y = ~record.count, name = "Recorded", marker = list(color = tbia.color_6[6]),
                  hoverinfo = 'text', text = ~paste0("Total species via TaiCOL: ", taicol.count, "<br>Recorded species: ", record.count), textposition = "none")
      
    } else {
      
      ## if habitat == one of the "is_*"
      df_counts_by_habitats <- 
        fread("www/data/processed/df_counts_by_habitats.csv",
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
  df_tree <- fread("www/data/processed/df_tree.csv",
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
    fread("www/data/processed/df_time.csv",
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
  df_spatial_allOccCount_grid_table <- fread("www/data/processed/df_spatial_allOccCount_grid_table.csv",
                                             sep = ",", colClasses = "character", encoding = "UTF-8", na.strings = c("", "NA", "N/A"))
  
  output$df_spatial_allOccCount_grid_table <- renderDT({
    datatable(df_spatial_allOccCount_grid_table,
              options = list(searching = FALSE, lengthMenu = list(c(10, -1), c('10', 'All'))))
  })
  
  # Load map data
  df_map <- st_read("www/data/processed/df_map.shp")
  pal_map <- colorNumeric(palette = "YlOrRd", domain = df_map$occCount)
  
  df_taxa_map <- st_read("www/data/processed/df_taxa_map.shp")
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
        addProviderTiles(providers$Esri.WorldPhysical, group = "Esri.WorldPhysical") %>%
        #addProviderTiles(providers$Esri.TopoMap, group = "Esri.TopoMap") %>%
        addProviderTiles(providers$Esri.OceanBasemap, group = "Esri.OceanBasemap") %>%
        addLayersControl(
          baseGroups = c("OSM", "Esri.WorldPhysical", "Esri.OceanBasemap"),
          #baseGroups = c("OSM", "Esri.WorldPhysical", "Esri.TopoMap", "Esri.OceanBasemap"),
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
          addProviderTiles(providers$Esri.WorldPhysical, group = "Esri.WorldPhysical") %>%
          #addProviderTiles(providers$Esri.TopoMap, group = "Esri.TopoMap") %>%
          addProviderTiles(providers$Esri.OceanBasemap, group = "Esri.OceanBasemap") %>%
          addLayersControl(
            baseGroups = c("OSM", "Esri.WorldPhysical", "Esri.OceanBasemap"),
            #baseGroups = c("OSM", "Esri.WorldPhysical", "Esri.TopoMap", "Esri.OceanBasemap"),
            options = layersControlOptions(collapsed = TRUE)) %>%
          addResetMapButton() %>%
          addPolygons(
            data = df_taxa_map_selected(),
            fillColor = ~pal_taxa(occCount),
            weight = 1,
            opacity = 0.6,
            color = 'purple',
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
  gapCountdf <- fread("www/data/processed/df_gapCount_table.csv",
                      sep = ",", encoding = "UTF-8", na.strings = c("", "NA", "N/A")) %>% na.omit()
  
  gapCountdf_sorted <- gapCountdf[order(factor(gapCountdf$priority, levels = c("Priority", "Intermediate", "Non-priority"))), ]
  
  output$gapCount <- renderDT({
    datatable(gapCountdf_sorted, options = list(searching = FALSE, paging = FALSE))
  })
  
  
  ## gapMap
  ## grid layer
  occ.grid5km_sf <- st_read("www/data/layers/5km/0_05degree_tw_landocean_grid.shp")
  pal <- colorNumeric(palette = "YlOrRd", domain = occ.grid5km_sf$allOccC)
  
  output$gapMap <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = 120, lat = 23, zoom = 7) %>%
      addProviderTiles(providers$Esri.WorldPhysical, group = "Esri.WorldPhysical") %>%
      #addProviderTiles(providers$Esri.TopoMap, group = "Esri.TopoMap") %>%
      addProviderTiles(providers$Esri.OceanBasemap, group = "Esri.OceanBasemap") %>%
      addLayersControl(
        baseGroups = c("OSM", "Esri.WorldPhysical", "Esri.OceanBasemap"),
        #baseGroups = c("OSM", "Esri.WorldPhysical", "Esri.TopoMap", "Esri.OceanBasemap"),
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