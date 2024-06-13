library(shiny)
library(shinydashboard)
library(shinythemes)
library(collapsibleTree)
library(shinycssloaders)
library(leaflet)
library(DT)
library(tigris)
library(markdown)
library(plotly)



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
        menuItem(HTML("&nbsp;Home"), tabName = "home", icon = icon("home")),
        menuItem(HTML("&nbsp;Descriptions"), tabName = "descriptions", icon = icon("pencil")),
        menuItem(HTML("&nbsp;Taxonomic Gap"), tabName = "taxa", icon = icon("tree")),
        menuItem(HTML("&nbsp;Species Tree"), tabName = "tree", icon = icon("tree")),
        menuItem(HTML("&nbsp;Temporal Gap"), tabName = "time", icon = icon("clock")),
        menuItem(HTML("&nbsp;Spatial Gap"), tabName = "map", icon = icon("map-location-dot")),
        #menuItem(HTML("&nbsp;Basis of Record"), tabName = "bof", icon = icon("pencil")),
        menuItem(HTML("&nbsp;Fill the Gap!"), tabName = "fillgap", icon = icon("map-marked-alt")),
        menuItem(HTML("&nbsp;References"), tabName = "references", icon = icon("book-atlas")),
        menuItem(HTML("&nbsp;Releases"), tabName = "releases", icon = icon("tasks")),
        
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
      
      tags$style(HTML(".content-wrapper { height: 1500px; }")),
      
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
                fluidRow(
                  HTML("<h2>&nbsp;&nbsp;Data descriptions</h2>"),
                  br(),
                  valueBox(value = paste("21,793,791"), subtitle = "All TBIA records (ver20240605)", icon = icon("database"), color = "red"),
                  valueBox(value = paste("21,793,791"), subtitle = "Cleaned TBIA records", icon = icon("broom"), color = "orange")),
                includeMarkdown("www/descriptions.md"),
                ),
        
        
        
        # Section: Taxonomic Gap
        tabItem(tabName = "taxa",
                includeMarkdown("www/taxa.md"),
                HTML("<hr style='border-color: darkgreen; border-width: 1px; border-style: solid;'>"),
                HTML("<h4><b>Recorded TaiCOL taxa on TBIA:</b></h4>"),
                fluidRow(
                  column(6,
                         div(HTML("<b>% record matched to highest taxon rank</b>"), style = "margin-bottom: 10px;"),
                         plotlyOutput("taxa.pie.taxonRank", height = 400)),
                  column(6,
                         div(HTML("<b>% record with (infra)species rank matched to TaiCOL</b>"), style = "margin-bottom: 10px;"),
                         plotlyOutput("taxa.pie.TaiCOL", height = 400))
                ),
                br(),
                HTML("<h4><b>The XX% of the unrecorded TaiCOL taxa on TBIA:</b></h4>"),
                br(),
                column(2, 
                       uiOutput("taxa.landtype.taxa.prop"),
                       br(),
                       uiOutput("taxa.landtype.taxa.prop.count")),
                # download unrecorded taxa list here
                column(10, 
                       fluidRow(
                         column(12, 
                                div(HTML("<b>% of recorded & unrecorded taxa on TBIA</b>"), style = "margin-bottom: 10px;"),
                                plotlyOutput("taxa.bar.unrecorded.taxa", height = 400))
                       )
                )
        ),
        
        
        
        # Section: Species Tree
        tabItem(tabName = "tree",
                includeMarkdown("www/tree.md"),
                HTML("<hr style='border-color: darkgreen; border-width: 1px; border-style: solid;'>"),
                column(3, uiOutput("taxa.treeSubGroup")),
                column(3, uiOutput("taxa.treeHabitat")),
                column(12, style = "overflow-y: scroll; height: 750px;",
                       collapsibleTreeOutput('tree', height = '1000px'))
        ),
        
        
        
        # Section: Temporal Gap
        tabItem(tabName = "time",
                fluidRow(
                  column(4,
                         selectizeInput(
                           inputId = "time.taxaSubGroup",
                           label = "Select a taxa group:",
                           choices = NULL,
                           multiple = T,
                           options = list(create = TRUE)
                         ),
                         br(),
                         uiOutput("time.landType"),
                         br(),
                         sliderInput("time.year", "Select year:", min = 1980, max = 2024, value = c(1980, 2024), step = 1, sep = ""),
                         br(),
                         selectizeInput(
                           inputId = "time.month",
                           label = "Select month:",
                           choices = 1:12,
                           multiple = T,
                           options = list(create = TRUE)
                         )
                  ),
                  column(8,
                         fluidRow(
                           column(12, 
                                  box(width = 12, title = "Year", plotlyOutput("time.yearBarChart"))
                           ),
                           column(12, 
                                  box(width = 12, title = "Month", plotlyOutput("time.monthBarChart"))
                           )
                         )
                  )
                )
        ),
        
        
        
        # Section: Spatial Gap
        tabItem(
          tabName = "map",
          fluidRow(
            column(
              width = 4,
              box(
                width = 12,
                checkboxInput("showAll", HTML("<b>Show all records</b>"), value = T),
                HTML("<b>OR</b>"), br(), br(),
                selectizeInput(
                  inputId = "spatial.taxaSubGroup",
                  label = "Choose a taxa group:",
                  choices = NULL,
                  multiple = T,
                  options = list(create = T)
                ),
              ),
              box(
                title = "Taxa groups and record count",
                width = 12,
                DTOutput("spatial_top15taxa_table"), 
                style = "width: 100%;"
                )
              ),
            column(
              width = 8,
              leafletOutput("spatialMap", height = 900)
            )
          )
        ),

        
        
        
                  
        
        
  
        
        
        
        
        
        
        # tabItem(
        #   tabname = "taxa",
        #   includeMarkdown("www/home.md")
        #     # fluidRow(
        #     #   column(6,
        #     #          box(
        #     #            title = "Box 1",
        #     #            "This is the content of Box 1"
        #     #          )
        #     #   ),
        #     #   column(6,
        #     #          box(
        #     #            title = "Box 2",
        #     #            "This is the content of Box 2"
        #     #          )
        #     #   )
        #     # )
        # ),
        
        
        
        
        
      
        # # Section: Taxonomical Gap
        # tabItem(tabName = "table", dataTableOutput("speciesDataTable") %>% withSpinner(color = "green")
        #         ),
        # 
        # # Section: Temporal Gap
        # tabItem(tabName = "tree", 
        #       
        #   # collapsible species tree section
        #   includeMarkdown("www/tree.md"),
        #   column(3, uiOutput("parkSelectComboTree")),
        #   column(3, uiOutput("categorySelectComboTree")),
        #   collapsibleTreeOutput('tree', height='700px') %>% withSpinner(color = "green")
        #   
        # ),
        # 
        # # Section: Methodological Gap
        # tabItem(tabName = "charts",
        #   
        #   # ggplot2 species charts section
        #   includeMarkdown("www/charts.md"),
        #   fluidRow(column(3, uiOutput("categorySelectComboChart"))),
        #   column(6, plotOutput("ggplot2Group1") %>% withSpinner(color = "green")),
        #   column(6, plotOutput("ggplot2Group2") %>% withSpinner(color = "green"))
        #   
        # ), 
        # 
        
        
        
        # Section: Basis of Record
        tabItem(tabName = "bof",
                includeMarkdown("www/bof.md"),
                
                
        ),
        
        
        
        # Section: Fill the Gap!
        tabItem(tabName = "fillgap",
                includeMarkdown("www/fillgap.md"),
                fluidRow(valueBox(10 * 2, "Priority", icon = icon("triangle-exclamation"), color = "red"),
                         valueBox(10 * 2, "Intermediate", icon = icon("star"), color = "orange"),
                         valueBox(10 * 2, "Non-priority", icon = icon("thumbs-up"), "yellow")),
                fluidRow(column(width = 7, leafletOutput("gapMap", height = 650)),
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
