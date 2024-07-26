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
    
    plot_ly(df_taxa.rank, labels = ~taxonRank, values = ~count, type = "pie",
            hoverinfo = "label+value", textinfo = "percent", marker = list(colors = tbia.color_6))
    
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
    selectInput("taxa.landtype.taxa.prop", "選擇棲地類型：", c("All", "is_terrestrial", "is_freshwater", "is_brackish", "is_marine"))
  })
  
  
  output$taxa.bar.unrecorded.taxa <- renderPlotly({
    
    if (input$taxa.landtype.taxa.prop == "All") {
      
      ## if habitat == "All"
      df_taxa.unrecorded.taxa.prop.groupAll <- 
        fread("www/data/processed/df_taxa.unrecorded.taxa.prop.groupAll.csv",
        sep = ",", colClasses = "character", encoding = "UTF-8", na.strings = c("", "NA", "N/A"))
      
      plot_data <- plot_ly(df_taxa.unrecorded.taxa.prop.groupAll, x = ~taxaSubGroup, type = 'bar', name = 'TaiCOL總物種數', y = ~taicol.count,
                           hoverinfo = 'text', text = ~paste0("TaiCOL總物種數：", taicol.count), textposition = "none") %>%
        add_trace(y = ~record.count, name = "入口網已記錄", marker = list(color = tbia.color_6[6]),
                  hoverinfo = 'text', text = ~paste0("TaiCOL總物種數: ", taicol.count, "<br>入口網已記錄物種數：", record.count), textposition = "none")
      
    } else {
      
      ## if habitat == one of the "is_*"
      df_counts_by_habitats <- 
        fread("www/data/processed/df_counts_by_habitats.csv",
              sep = ",", colClasses = "character", encoding = "UTF-8", na.strings = c("", "NA", "N/A"))
      
      ## select habitat
      selected_habitat <- input$taxa.landtype.taxa.prop
      df_subset <- df_counts_by_habitats[df_counts_by_habitats$habitat == selected_habitat, ]
      
      plot_data <- plot_ly(df_subset, x = ~taxaSubGroup, type = 'bar', name = 'TaiCOL總物種數', y = ~taicol.count,
                           hoverinfo = 'text', text = ~paste0("TaiCOL總物種數：", taicol.count), textposition = "none") %>%
        add_trace(y = ~record.count, name = '入口網已記錄', marker = list(color = tbia.color_6[6]),
                  hoverinfo = 'text', text = ~paste0("TaiCOL總物種數: ", taicol.count, "<br>入口網已記錄物種數：", record.count), textposition = "none")
      
    }
    
    # Customize layout and configuration for the plot
    plot_data <- plot_data %>%
      layout(xaxis = list(title = "物種類群", tickangle = 45), 
             yaxis = list(title = "物種數量", tickvals = seq(0, 12000, 500)),
             legend = list(x = 0, y = 1.1, orientation = "h")) %>%
        config(displayModeBar = FALSE)
    
    return(plot_data)

  })
  
  
  
  
  # Section: Taxon & basisOfRecord
  ## heatmap
  df_taxa.basisOfRecord <- fread("www/data/processed/df_taxa.basisOfRecord.csv",
                   sep = ",", colClasses = "character", encoding = "UTF-8", na.strings = c("", "NA", "N/A"))
  
  output$df_bof <- renderPlotly({
    
    plot_ly(
      data = df_taxa.basisOfRecord,
      x = ~basisOfRecord,
      y = ~taxaSubGroup,
      z = ~count_numeric,
      type = "heatmap",
      colorscale = "Viridis",
      colorbar = list(
        title = "Record count",
        tickvals = c(0, 1, 2, 3, 4, 5, 6, 7),
        ticktext = c("0", "1-10", "11-100", "101-1,000", "1,001-10,000", "10,001-100,000", "100,001-10,000,000", "10,000,000+")
      ),
      text = ~paste0(taxaSubGroup, "<br>",
                     basisOfRecord, "<br>",
                     "Record count: ", count),
      hoverinfo = "text") %>%
      config(displayModeBar = FALSE) %>%
      layout(xaxis = list(title = "物種類群"), 
             yaxis = list(title = "記錄類型", tickangle = 45),
             showlegend = FALSE) 
  
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
  
  
  ## download unrecorded species list
  output$downloadData <- downloadHandler(
    filename = function() {
      "TBIA_unrecorded_species.csv"  # Name of the file to be downloaded
    },
    
    content = function(file) {
      download_url <- "https://drive.google.com/uc?export=download&id=1UBRm61yq9EiYZn5ziXcMJbbIPabzPX1h"
      
      # Download the file from the URL and save it to the specified file path
      download.file(download_url, file)
    }
  )
  
  
  
  # Section: Temporal Gap
  ## load time data
  df_time <- reactive({
    fread("www/data/processed/df_time.csv",
          sep = ",", colClasses = "character", encoding = "UTF-8", na.strings = c("", "NA", "N/A")) %>%
      mutate(year = as.numeric(year), month = as.numeric(month), occCount = as.numeric(occCount))
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
    
    aggregated_data <- filtered_data() %>%
      group_by(year) %>%
      summarise(total_occCount = sum(occCount), .groups = 'drop') %>%
      mutate(hoverText = paste("Year:", year, "<br>Occurrence Count:", total_occCount))
    
    plot_ly(aggregated_data, x = ~year, y = ~total_occCount, type = "bar", marker = list(color = "#76A678"),
            text = ~hoverText, hoverinfo = "text", textposition = "none") %>%
      layout(xaxis = list(title = "Year"), yaxis = list(title = "Record count")) %>%
      config(displayModeBar = FALSE)
  })
  
  ## Render month bar chart
  output$time.monthBarChart <- renderPlotly({
    req(input$time.month)
    
    aggregated_data <- filtered_data() %>%
      group_by(month) %>%
      summarise(total_occCount = sum(occCount), .groups = 'drop') %>%
      mutate(hoverText = paste("Month:", month, "<br>Occurrence Count:", total_occCount))
    
    plot_ly(aggregated_data, x = ~month, y = ~total_occCount, type = "bar", marker = list(color = "#76A678"),
            text = ~hoverText, hoverinfo = "text", textposition = "none") %>%
      layout(xaxis = list(title = "Month"), yaxis = list(title = "Record count")) %>%
      config(displayModeBar = FALSE)
  })

  
  
  # Section : Spatial
  ## Load taxa table
  df_spatial_allOccCount_grid_table <- fread("www/data/processed/df_spatial_allOccCount_grid_table.csv",
                                             sep = ",", encoding = "UTF-8")
  
  output$df_spatial_allOccCount_grid_table <- renderDT({
    datatable(df_spatial_allOccCount_grid_table,
              options = list(searching = FALSE, lengthMenu = list(c(10, -1), c('10', 'All'))))
  })
  
  # Load map data
  df_map <- st_read("www/data/processed/df_map.shp")
  breaks <- c(1, 10, 100, 1000, 5000, 10000, 50000, 100000, max(df_map$occCount, na.rm = TRUE))
  pal_map <- colorBin(palette = "YlOrRd", domain = df_map$occCount, bins = breaks)
  
  df_taxa_map <- st_read("www/data/processed/df_taxa_map.shp")
  breaks <- c(1, 10, 100, 1000, 5000, 10000, 50000, 100000, max(df_map$occCount, na.rm = TRUE))
  pal_taxa <- colorBin(palette = "YlOrRd", domain = df_taxa_map$occCount, bins = breaks)
  
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
        addProviderTiles(providers$Esri.OceanBasemap, group = "Esri.OceanBasemap") %>%
        addLayersControl(
          baseGroups = c("OSM", "Esri.WorldPhysical", "Esri.OceanBasemap"),
          options = layersControlOptions(collapsed = TRUE)) %>%
        addResetMapButton() %>%
        addPolygons(
          data = df_map,
          fillColor = ~pal_map(occCount),
          weight = 1,
          opacity = 0.6,
          color = 'orange',
          fillOpacity = 0.6,
          popup = ~paste("Number of records:", occCount)) %>%
        addLegend(
          data = df_map,
          values = ~occCount,
          pal = pal_map,
          opacity = 0.6,
          title = "Record count",
          position = "bottomright",
          labFormat = labelFormat(digits = 0, big.mark = ","))

      } else {

        leaflet() %>%
          addTiles() %>%
          setView(lng = 120.5, lat = 22.5, zoom = 7) %>%
          addProviderTiles(providers$Esri.WorldPhysical, group = "Esri.WorldPhysical") %>%
          addProviderTiles(providers$Esri.OceanBasemap, group = "Esri.OceanBasemap") %>%
          addLayersControl(
            baseGroups = c("OSM", "Esri.WorldPhysical", "Esri.OceanBasemap"),
            options = layersControlOptions(collapsed = TRUE)) %>%
          addResetMapButton() %>%
          addPolygons(
            data = df_taxa_map_selected(),
            fillColor = ~pal_taxa(occCount),
            weight = 1,
            opacity = 0.4,
            color = 'mediumvioletred',
            fillOpacity = 0.6,
            popup = ~paste("Number of records:", occCount)) %>%
          addLegend(
            data = df_map,
            values = ~occCount,
            pal = pal_map,
            opacity = 0.6,
            title = "Record count",
            position = "bottomright",
            labFormat = labelFormat(digits = 0, big.mark = ","))

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
  gapCountdf <- fread("www/data/processed/df_gapCount_table.csv", sep = ",", encoding = "UTF-8")
  
  gapCountdf_sorted <- gapCountdf[order(factor(gapCountdf$priority, levels = c("建議優先填補", "建議填補", "資料筆數高於平均值"))), ]
  
  gapCountdf_sorted <- gapCountdf_sorted %>%
    rename("優先填補等級" = "priority", "地型分類" = "landType", "網格數" = "gridCount")
  
  output$gapCount <- renderDT({
    datatable(gapCountdf_sorted, options = list(searching = FALSE, paging = FALSE))
  })
  
  
  ## gapMap
  ## grid layer
  df_gapCount_table_shp <- st_read("www/data/processed/df_gapCount_table.shp")
  breaks <- c(0, 1, 10, 100, 1000, 5000, 10000, 50000, 100000, max(df_gapCount_table_shp$occCount, na.rm = TRUE))
  
  pal <- colorBin(palette = "YlOrRd", domain = df_gapCount_table_shp$occCount, bins = breaks)
  
  output$gapMap <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = 120, lat = 23, zoom = 7) %>%
      addProviderTiles(providers$Esri.WorldPhysical, group = "Esri.WorldPhysical") %>%
      addProviderTiles(providers$Esri.OceanBasemap, group = "Esri.OceanBasemap") %>%
      addLayersControl(
        baseGroups = c("OSM", "Esri.WorldPhysical", "Esri.OceanBasemap"),
        options = layersControlOptions(collapsed = TRUE)) %>%
      addResetMapButton() %>%
      addPolygons(
        data = df_gapCount_table_shp,
        fillColor = ~pal(occCount),
        weight = 1,
        opacity = 0.6,
        color = 'orange',
        fillOpacity = 0.5,
        popup = ~paste("<strong>資料筆數:</strong>", occCount, "<br>",
                       "<strong>地型分類:</strong>", landType, "<br>",
                       "<strong>優先填補等級:</strong>", priority)) %>%
      addLegend(
        data = df_gapCount_table_shp,
        pal = pal,
        values = ~occCount,
        opacity = 0.5,
        title = "資料筆數",
        position = "bottomright")
  })


})