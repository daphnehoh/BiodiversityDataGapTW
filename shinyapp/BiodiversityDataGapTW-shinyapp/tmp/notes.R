# leaflet in DataCamp

leaflet(options = leafletOptions(
  # Set minZoom and dragging 
  minZoom = 12, dragging = T))  %>% 
  addProviderTiles("CartoDB")  %>% 
  
  # Set default zoom level 
  setView(lng = dc_hq$lon[2], lat = dc_hq$lat[2], zoom = 14) %>% 
  
  # Set max bounds of map 
  setMaxBounds(lng1 = dc_hq$lon[2] + .05, 
               lat1 = dc_hq$lat[2] + .05, 
               lng2 = dc_hq$lon[2] - .05, 
               lat2 = dc_hq$lat[2] - .05) 


# Customize the legend
m %>% 
  addLegend(pal = pal, 
            values = c("Public", "Private", "For-Profit"),
            # opacity of .5, title of Sector, and position of topright
            opacity = 0.5, title = "Sector", position = "topleft")



# Create data frame called private with only private colleges
private <- filter(ipeds, sector_label == "Private")  

# Add private colleges to `m3` as a new layer
m3 <- m3 %>% 
  addCircleMarkers(data = private, radius = 2, label = ~htmlEscape(name),
                   color = ~pal(sector_label), group = "Private") %>% 
  addLayersControl(overlayGroups = c("Public", "Private"))


# Putting altogether
m4 <- leaflet() %>% 
  addTiles(group = "OSM") %>% 
  addProviderTiles("CartoDB", group = "Carto") %>% 
  addProviderTiles("Esri", group = "Esri") %>% 
  addCircleMarkers(data = public, radius = 2, label = ~htmlEscape(name),
                   color = ~pal(sector_label),  group = "Public") %>% 
  addCircleMarkers(data = private, radius = 2, label = ~htmlEscape(name),
                   color = ~pal(sector_label), group = "Private")  %>% 
  addCircleMarkers(data = profit, radius = 2, label = ~htmlEscape(name),
                   color = ~pal(sector_label), group = "For-Profit")  %>% 
  addLayersControl(baseGroups = c("OSM", "Carto", "Esri"), 
                   overlayGroups = c("Public", "Private", "For-Profit")) %>% 
  setView(lat = 39.8282, lng = -98.5795, zoom = 4) 


# add search features (for magnifying glass search item)
m4_search <- m4  %>% 
  addSearchFeatures(
    targetGroups = c("Public", "Private", "For-Profit"), 
    # Set the search zoom level to 18
    options = searchFeaturesOptions(zoom = 18)) 


## cluster
ipeds %>% 
  leaflet() %>% 
  addTiles() %>% 
  # Sanitize any html in our labels
  addCircleMarkers(radius = 2, label = ~htmlEscape(name),
                   # Color code colleges by sector using the `pal` color palette
                   color = ~pal(sector_label),
                   # Cluster all colleges using `clusterOptions`
                   clusterOptions = markerClusterOptions()) 


# Glimpse the nc_income data
glimpse(nc_income)

# Summarize the nc_income data
summary(nc_income)

# Left join nc_income onto shp@data and store in shp_nc_income
shp_nc_income <- shp@data %>% 
  left_join(nc_income, by = c("GEOID10" = "zipcode"))

# Print the number of missing values of each variable in shp_nc_income
shp_nc_income  %>%
  summarize(across(everything(), ~sum(is.na(.x))))


# plotting polygons
shp %>%
  leaflet() %>%
  addTiles() %>%
  addPolygons(weight = 1,
              color = "grey",
              label = ~paste0("Total income: ", dollar(income)),
              highlight = hightlightOptions(weight = 3, color = "red", bringToFront = "T"))


# Coloring numeric Data
nc_pal <- colorNumeric(palette = "Blues",
                       domain = high_inc@data$mean_income)
# colorBin(), colorQuantile()
previewColors(pal = nc_pal,
              values = c(seq(100000, 600000, by = 100000)))


# summarize the mean income variable
summary(shp$mean_income)

# subset shp to include only zip codes in the top quartile of mean income
high_inc <- shp[!is.na(shp$mean_income) & shp$mean_income > 55917,]

# map the boundaries of the zip codes in the top quartile of mean income
high_inc %>%
  leaflet() %>%
  addTiles() %>%
  addPolygons()


# Use the log function to create a new version of nc_pal
nc_pal <- colorNumeric("YlGn", domain = log(high_inc@data$mean_income))

# comment out the map tile
high_inc %>%
  leaflet() %>%
  #addProviderTiles("CartoDB") %>%
  # apply the new nc_pal to the map
  addPolygons(weight = 1, color = ~nc_pal(log(mean_income)), fillOpacity = 1,
              label = ~paste0("Mean Income: ", dollar(mean_income)),
              highlightOptions = highlightOptions(weight = 5, color = "white", bringToFront = TRUE))



## saving map
saveWidgets(m, file="myMap.html")


## group
# plot zip codes with mean incomes >= $200k
wealthy_zips %>% 
  leaflet() %>% 
  addProviderTiles("CartoDB") %>% 
  # set color to green and create Wealth Zipcodes group
  addPolygons(weight = 1, fillOpacity = .7, color = "green",  group = "Wealthy Zipcodes", 
              label = ~paste0("Mean Income: ", dollar(mean_income)),
              highlightOptions = highlightOptions(weight = 5, color = "white", bringToFront = TRUE))


# combine different layer
# Add polygons using wealthy_zips
final_map <- m4 %>% 
  addPolygons(data = wealthy_zips, weight = 1, fillOpacity = .5, color = "Grey",  group = "Wealthy Zip Codes", 
              label = ~paste0("Mean Income: ", dollar(mean_income)),
              highlightOptions = highlightOptions(weight = 5, color = "white", bringToFront = TRUE)) %>% 
  # Update layer controls including "Wealthy Zip Codes"
  addLayersControl(baseGroups = c("OSM", "Carto", "Esri"), 
                   overlayGroups = c("Public", "Private", "For-Profit", "Wealthy Zip Codes"))     
