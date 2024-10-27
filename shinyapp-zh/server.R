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
  
  
  ## Taxa & record count table
  df_allOccCount_grid_table <- fread("www/data/processed/df_spatial_allOccCount_grid_table.csv",
                                             sep = ",", encoding = "UTF-8")
  
  output$df_allOccCount_grid_table <- renderDT({
    datatable(df_allOccCount_grid_table,
              options = list(searching = FALSE, lengthMenu = list(c(15, -1), c('15', 'All'))))
  })
  
  
  ## Taxa & basisOfRecord heatmap
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
      showscale = FALSE,
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
      layout(xaxis = list(title = "紀錄類型"), 
             yaxis = list(title = "物種類群", tickangle = 45)) 
    
  })
  
  
  ## The unrecorded taxa bar chart and their habitat
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
        add_trace(y = ~record.count, name = "入口網已紀錄", marker = list(color = tbia.color_6[6]),
                  hoverinfo = 'text', text = ~paste0("TaiCOL總物種數: ", taicol.count, "<br>入口網已紀錄物種數：", record.count), textposition = "none")
      
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
        add_trace(y = ~record.count, name = '入口網已紀錄', marker = list(color = tbia.color_6[6]),
                  hoverinfo = 'text', text = ~paste0("TaiCOL總物種數: ", taicol.count, "<br>入口網已紀錄物種數：", record.count), textposition = "none")
      
    }
    
    ### Customize layout and configuration for the plot
    plot_data <- plot_data %>%
      layout(xaxis = list(title = "物種類群", tickangle = 45), 
             yaxis = list(title = "物種數量", tickvals = seq(0, 12000, 500)),
             legend = list(x = 0, y = 1.1, orientation = "h")) %>%
        config(displayModeBar = FALSE)
    
    return(plot_data)

  })
  
  
  
  # Section: Species Tree
  ## collapsible tree
  df_tree <- fread("www/data/processed/df_tree.csv",
                   sep = ",", colClasses = "character", encoding = "UTF-8", na.strings = c("", "NA", "N/A"))
  
  output$taxa.treeSubGroup <- renderUI({
    selectInput("taxa.treeSubGroup", "選擇物種類群：", sort(unique(df_tree$taxaSubGroup)))
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

  
  
  # Section: Spatial
  # Load map data
  df_map <- st_read("www/data/processed/df_map.shp")
  df_taxa_map <- st_read("www/data/processed/df_taxa_map.shp")
  
  # Define color palettes and breaks
  breaks <- c(1, 10, 100, 1000, 5000, 10000, 50000, 100000, max(df_map$occCount, na.rm = TRUE))
  pal_map <- colorBin(palette = "YlOrRd", domain = df_map$occCount, bins = breaks)
  pal_taxa <- colorBin(palette = "YlOrRd", domain = df_taxa_map$occCount, bins = breaks)
  
  # Reactive expression for selected taxa map data
  df_taxa_map_selected <- reactive({
    req(input$spatial.taxaSubGroup)
    df_taxa_map %>% filter(tSG %in% input$spatial.taxaSubGroup)
  })
  
  # Reactive expression for sum of selected occCount
  df_taxa_map_summarized <- reactive({
    df_taxa_map_selected() %>%
      group_by(geometry) %>%
      summarize(occCount = sum(occCount, na.rm = TRUE)) %>%
      ungroup()
  })
  
  # Render the spatial map based on selection
  output$spatialMap <- renderLeaflet({
    base_map <- leaflet() %>%
      addTiles() %>%
      setView(lng = 120.5, lat = 22.5, zoom = 7) %>%
      addProviderTiles(providers$Esri.WorldPhysical, group = "Esri.WorldPhysical") %>%
      addProviderTiles(providers$Esri.OceanBasemap, group = "Esri.OceanBasemap") %>%
      addLayersControl(
        baseGroups = c("OSM", "Esri.WorldPhysical", "Esri.OceanBasemap"),
        options = layersControlOptions(collapsed = TRUE)
      ) %>%
      addResetMapButton()
    
    if (input$showAll) {
      base_map %>%
        addPolygons(
          data = df_map,
          fillColor = ~pal_map(occCount),
          weight = 1,
          opacity = 0.4,
          color = 'orange',
          fillOpacity = 0.4,
          popup = ~paste("Number of records:", occCount)
        ) %>%
        addLegend(
          data = df_map,
          values = ~occCount,
          pal = pal_map,
          opacity = 0.4,
          title = "Record count",
          position = "bottomright",
          labFormat = labelFormat(digits = 0, big.mark = ",")
        )
    } else {
      base_map %>%
        addPolygons(
          data = df_taxa_map_summarized(),
          fillColor = ~pal_taxa(occCount),
          weight = 1,
          opacity = 0.2,
          color = 'mediumvioletred',
          fillOpacity = 0.4,
          popup = ~paste("Number of selected records:", occCount)
        ) %>%
        addLegend(
          data = df_taxa_map_summarized(),
          values = ~occCount,
          pal = pal_taxa,
          opacity = 0.2,
          title = "Record count",
          position = "bottomright",
          labFormat = labelFormat(digits = 0, big.mark = ",")
        )
    }
  })
  
  # Update selectizeInput choices based on df_spatial_allOccCount_grid_table
  observe({
    updateSelectizeInput(session, 'spatial.taxaSubGroup', choices = unique(df_allOccCount_grid_table$taxaSubGroup), server = TRUE)
  })
  
  # Update checkbox based on selection
  observeEvent(input$spatial.taxaSubGroup, {
    updateCheckboxInput(session, "showAll", value = is.null(input$spatial.taxaSubGroup) || length(input$spatial.taxaSubGroup) == 0)
  })

  
  
  # Section: Fill gap
  ## gapCount table
  gapCountdf <- fread("www/data/processed/df_gapCount_table.csv", sep = ",", encoding = "UTF-8")
  
  gapCountdf_sorted <- gapCountdf[order(factor(gapCountdf$priority, levels = c("建議優先填補", "建議填補", "資料筆數高於平均值"))), ]
  
  gapCountdf_sorted <- gapCountdf_sorted %>%
    rename("優先填補等級" = "priority", "棲地類型" = "landType", "網格數" = "gridCount")
  
  output$gapCount <- renderDT({
    datatable(gapCountdf_sorted, options = list(searching = FALSE, paging = FALSE))
  })
  
  
  ## gapMap
  ## grid layer
  # Update selectizeInput choices based on the data
  df_gapCount_table_shp <- st_read("www/data/processed/df_gapCount_table.shp")
  
  # Dynamically generate the dropdown menu
  output$gap.priority <- renderUI({
    selectInput(
      inputId = "priority",
      label = "選擇優先填補等級:",
      choices = unique(df_gapCount_table_shp$priority),
      selected = unique(df_gapCount_table_shp$priority)[1]  # Default selection
    )
  })
  
  df_gap_map_selected <- reactive({
    req(input$priority)
    filtered <- df_gapCount_table_shp %>%
      filter(priority == input$priority)
    if (nrow(filtered) == 0) return(df_gapCount_table_shp)  # Fallback to full dataset if filter results in empty set
    filtered
  })
  
  breaks <- reactive({
    c(0, 1, 10, 100, 1000, 5000, 10000, 50000, 100000, max(df_gapCount_table_shp$occCount, na.rm = TRUE))
  })
  
  pal <- reactive({
    colorBin(palette = "YlOrRd", domain = df_gapCount_table_shp$occCount, bins = breaks())
  })
  
  output$gapMap <- renderLeaflet({
    req(df_gap_map_selected())
    
    leaflet() %>%
      addTiles() %>%
      setView(lng = 120, lat = 23, zoom = 7) %>%
      addProviderTiles(providers$Esri.WorldPhysical, group = "Esri.WorldPhysical") %>%
      addProviderTiles(providers$Esri.OceanBasemap, group = "Esri.OceanBasemap") %>%
      addLayersControl(
        baseGroups = c("OSM", "Esri.WorldPhysical", "Esri.OceanBasemap"),
        options = layersControlOptions(collapsed = TRUE)
      ) %>%
      addResetMapButton() %>%
      addPolygons(
        data = df_gap_map_selected(),
        fillColor = ~pal()(occCount),
        weight = 0.5,
        opacity = 0.6,
        color = 'orange',
        fillOpacity = 0.5,
        popup = ~paste("<strong>資料筆數:</strong>", occCount, "<br>",
                       "<strong>棲地類型:</strong>", landType, "<br>",
                       "<strong>優先填補等級:</strong>", priority)
      ) %>%
      addLegend(
        data = df_gap_map_selected(),
        pal = pal(),
        values = ~occCount,
        opacity = 0.5,
        title = "資料筆數",
        position = "bottomright"
      )
  })
  
  
})