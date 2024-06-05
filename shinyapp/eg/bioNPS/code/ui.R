library(shiny)
library(shinydashboard)
library(shinythemes)
library(collapsibleTree)
library(shinycssloaders)
library(leaflet)
library(DT)
library(tigris)
library(markdown)



shinyUI(fluidPage(
  
  # load custom stylesheet
  includeCSS("www/style.css"),
  
  # load google analytics script
  #tags$head(includeScript("www/google-analytics-bioNPS.js")),
  
  # remove shiny "red" warning messages on GUI
  tags$style(type="text/css",
             ".shiny-output-error { visibility: hidden; }",
             ".shiny-output-error:before { visibility: hidden; }"
  ),
  
  # load page layout
  dashboardPage(
    
    skin = "green",
      
    # header
    dashboardHeader(title="Taiwan Biodiversity Data Gap", titleWidth = 290,
                    # github icon
                    tags$li(class = "dropdown",
                            tags$a(href = "https://github.com/daphnehoh/BiodiversityDataGapTW", 
                                   icon("github"), class = "nav-link", target = "_blank"))
                    ),
    
    # sidebar
    dashboardSidebar(width = 290,
      sidebarMenu(
        HTML(paste0(
          "<br>",
          "<a href='https://tbiadata.tw' target='_blank'><img style = 'display: block; margin-left: auto; margin-right: auto;' src='TBIA_logo.png' width = '250'></a>",
          "<br>",
          "<p style = 'text-align: center;'><small><a href='https://tbiadata.tw' target='_blank'>https://tbiadata.tw</a></small></p>",
          "<br>"
        )),
        menuItem("Home", tabName = "home", icon = icon("home")),
        menuItem("Descriptions", tabName = "descriptions", icon = icon("pencil")),
        menuItem("Spatial Gap", tabName = "map", icon = icon("map-location-dot")),
        menuItem("Taxonomical Gap", tabName = "table", icon = icon("tree")),
        menuItem("Temporal Gap", tabName = "tree", icon = icon("clock")),
        menuItem("tmpMethodological Gap", tabName = "charts", icon = icon("pencil")),
        menuItem("Fill the Gap!", tabName = "fillgap", icon = icon("map-marked-alt")),
        menuItem("References", tabName = "references", icon = icon("book-atlas")),
        menuItem("Releases", tabName = "releases", icon = icon("tasks")),
        
        HTML(paste0(
          "<br><br><br><br><br><br><br><br><br>",
          "<table style='margin-left:auto; margin-right:auto;'>",
            "<tr>",
              "<td style='padding: 5px;'><a href='mailto:tbianoti@gmail.com' target='_blank'><i class='fa-solid fa-envelope'></i></i></a></td>",
              "<td style='padding: 5px;'><a href='https://www.youtube.com/@tbia4945' target='_blank'><i class='fab fa-youtube fa-lg'></i></a></td>",
            "</tr>",
          "</table>",
          "<br>"),
        HTML(paste0(
         "<p style = 'text-align: center;'><large>&copy; <a href='https://tbiadata.tw/' target='_blank'>TBIA 臺灣生物多樣性資訊聯盟</a>",
          "<div style='text-align: center; font-size: small;'>Last update: 2024-05-27</div>")
        ))
      )
      
    ), # end dashboardSidebar
    
    
    # body
    dashboardBody(
      
      tags$script(HTML('
        $(document).on("change", "#taxaSubGroup", function(){
          
          // When the selectize input changes
          var selectedOptions = $("#taxaSubGroup").val();
          
          // Set the value of the checkbox based on whether there are selected options
          $("#showAll").prop("checked", selectedOptions == null || selectedOptions.length === 0);
        
        });
      ')),
      
      tabItems(
        
        # Section: Home
        tabItem(tabName = "home", 
                includeMarkdown("www/home.md")
                ),
        
        # Section: Descriptions
        tabItem(tabName = "descriptions", 
                fluidRow(valueBox(value = paste("21,793,791"), subtitle = "TBIA records", icon = icon("database"), color = "red")),
                includeMarkdown("www/descriptions.md"),
                ),
        
        # Section: Spatial Gap
        tabItem(
          tabName = "map",
          fluidRow(
            column(
              box(width = 12, leafletOutput("spatialMap", height = 900)),
              width = 9
            ),
            column(
              width = 3,
              box(
                width = 12,
                checkboxInput("showAll", HTML("<b>Show all records</b>"), value = T),
                HTML("<b>OR</b>"), br(), br(),
                selectizeInput(
                  inputId = "taxaSubGroup",
                  label = "Choose a taxa group:",
                  choices = NULL,
                  multiple = T,
                  options = list(create = T)
                ),
              ),
              box(
                width = 12,
                DTOutput("spatial_top15taxa_table"), 
                style = "width: 100%;"
                )
              )
            )
          ),


      
        # Section: Taxonomical Gap
        tabItem(tabName = "table", dataTableOutput("speciesDataTable") %>% withSpinner(color = "green")
                ),
        
        # Section: Temporal Gap
        tabItem(tabName = "tree", 
              
          # collapsible species tree section
          includeMarkdown("www/tree.md"),
          column(3, uiOutput("parkSelectComboTree")),
          column(3, uiOutput("categorySelectComboTree")),
          collapsibleTreeOutput('tree', height='700px') %>% withSpinner(color = "green")
          
        ),
      
        # Section: Methodological Gap
        tabItem(tabName = "charts",
          
          # ggplot2 species charts section
          includeMarkdown("www/charts.md"),
          fluidRow(column(3, uiOutput("categorySelectComboChart"))),
          column(6, plotOutput("ggplot2Group1") %>% withSpinner(color = "green")),
          column(6, plotOutput("ggplot2Group2") %>% withSpinner(color = "green"))
          
        ), 
        
        # Section: Fill the Gap!
        tabItem(tabName = "fillgap",
                includeMarkdown("www/fillgap.md"),
                fluidRow(#box(width = 12,
                             valueBox(10 * 2, "Priority", icon = icon("triangle-exclamation"), color = "red"),
                             valueBox(10 * 2, "Intermediate", icon = icon("star"), color = "orange"),
                             valueBox(10 * 2, "Non-priority", icon = icon("thumbs-up"), "yellow")),
                fluidRow(column(width = 7, leafletOutput("gapMap", height = 600)),
                         column(width = 5, DTOutput("gapCount"), title = "Priority level and grid count by land type"))
                ),
                

            
        # tabItem(tabName = "choropleth",
        #   
        #   # choropleth species map section
        #   includeMarkdown("www/choropleth.md"),
        #   fluidRow(
        #     column(3, uiOutput("statesSelectCombo")),
        #     column(3, uiOutput("categorySelectComboChoro"))
        #   ),
        #   fluidRow(
        #     column(3,tableOutput('stateCategoryList') %>% withSpinner(color = "green")),
        #     column(9,leafletOutput("choroplethCategoriesPerState") %>% withSpinner(color = "green"))
        #   )
        #   
        # ),
        
        # Section: References
        tabItem(tabName = "references", includeMarkdown("www/references.md") ),
        
        # Section: Releases
        tabItem(tabName = "releases", includeMarkdown("www/releases.md")) )
    
    
      ) # end dashboardBody
  
  )# end dashboardPage

))
