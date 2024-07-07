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
  # tags$style(type="text/css",
  #            ".shiny-output-error { visibility: hidden; }",
  #            ".shiny-output-error:before { visibility: hidden; }"
  # ),
  # 
  # load page layout
  dashboardPage(
    
    skin = "green",
      
    # header
    dashboardHeader(title="Taiwan Biodiversity Data Gap", titleWidth = 300,
                    # github icon
                    tags$li(class = "dropdown",
                            tags$a(href = "https://github.com/daphnehoh/BiodiversityDataGapTW", 
                                   icon("github"), class = "nav-link", target = "_blank"))
                    ),
    
    # sidebar
    dashboardSidebar(width = 300,
      sidebarMenu(
        HTML(paste0(
          "<a href='https://portal.taibif.tw/' target='_blank'>
            <img style='display: block; margin-left: auto; margin-right: auto;' src='copilot3.jpg' width='300'></a>"
          #"<p style = 'text-align: center;'><small><a href='https://portal.taibif.tw/' target='_blank'>https://portal.taibif.tw/</a></small></p>",
        )),
        menuItem(HTML("&nbsp;首頁"), tabName = "home", icon = icon("home")),
        menuItem(HTML("&nbsp;説明"), tabName = "descriptions", icon = icon("pencil")),
        menuItem(HTML("&nbsp;物種類群資料概況"), tabName = "taxa", icon = icon("tree")),
        menuItem(HTML("&nbsp;物種樹"), tabName = "tree", icon = icon("tree")),
        menuItem(HTML("&nbsp;時間資料概況"), tabName = "time", icon = icon("clock")),
        menuItem(HTML("&nbsp;空間資料概況"), tabName = "map", icon = icon("map-location-dot")),
        menuItem(HTML("&nbsp;一起填補空缺！"), tabName = "fillgap", icon = icon("map-marked-alt")),
        menuItem(HTML("&nbsp;參考"), tabName = "references", icon = icon("book-atlas")),
        menuItem(HTML("&nbsp;發佈"), tabName = "releases", icon = icon("tasks")),
        
        HTML(paste0(
        "<br>",
        "<br>",
        "<div style='text-align: center;'>
          <div style='display: inline-block; margin: 10px;'>
            <a href='mailto:tbianoti@gmail.com' target='_blank'><i class='fa-solid fa-envelope'></i></a><br>
          </div>
          <div style='display: inline-block; margin: 10px;'>
            <a href='https://www.youtube.com/@tbia4945' target='_blank'><i class='fab fa-youtube fa-lg'></i></a><br>
          </div>
        </div>"),
        
        HTML(paste0(
         "<p style = 'text-align: center;'><large>&copy; <a href='https://tbiadata.tw/' target='_blank'>TBIA 臺灣生物多樣性資訊聯盟</a>",
          "<div style='text-align: center; font-size: small;'>Last update: 2024-07-08</div>")
        ))
      )
      
    ), # end dashboardSidebar
    
    
    # body
    dashboardBody(
      
      tags$style(HTML(".content-wrapper { overflow-y: hidden; }")),
      
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
                  HTML("<h3><b>&nbsp;&nbsp;資料説明</b></h3>"),
                  br(),
                  valueBox(value = paste("21,987,687"), subtitle = "所有 TBIA 資料 (ver20240704)", icon = icon("database"), color = "red"),
                  valueBox(value = paste("20,875,777"), subtitle = "已清理 TBIA 資料", icon = icon("broom"), color = "orange")),
                includeMarkdown("www/descriptions.md")
                ),
        
        
        
        # Section: Taxonomic Gap
        tabItem(tabName = "taxa",
                includeMarkdown("www/taxa.md"),
                HTML("<hr style='border-color: darkgreen; border-width: 1px; border-style: solid;'>"),
                HTML("<h4><b>TaiCOL 裏的 TBIA 記錄：</b></h4>"),
                fluidRow(
                  column(6,
                         div(HTML("<b>對到最高階層的記錄 %</b>"), style = "margin-bottom: 10px;"),
                         plotlyOutput("taxa.pie.taxonRank", height = 400)),
                  column(6,
                         div(HTML("<b>對到 TaiCOL 種階層（包含種下）的記錄 %</b>"), style = "margin-bottom: 10px;"),
                         plotlyOutput("taxa.pie.TaiCOL", height = 400))
                ),
                br(),
                HTML("<h4><b>比照 TaiCOL，TBIA 裏還未記錄的物種占了 XX%</b></h4>"),
                br(),
                column(2,
                       uiOutput("taxa.landtype.taxa.prop"), br()),
                br(),

                # download unrecorded taxa list here
              
                column(12, 
                       fluidRow(
                         column(12, 
                                div(HTML("<b>TBIA 裏已記錄與未記錄物種（不包含種下）</b>"), style = "margin-bottom: 10px;"),
                                plotlyOutput("taxa.bar.unrecorded.taxa", height = 500))
                       )
                )
        ),
        
        
        
        # Section: Species Tree
        tabItem(tabName = "tree",
                includeMarkdown("www/tree.md"),
                HTML("<hr style='border-color: darkgreen; border-width: 1px; border-style: solid;'>"),
                column(3, uiOutput("taxa.treeSubGroup")),
                column(12, 
                       box(width = 12, style = "overflow-y: scroll; height: 5000px;",
                       collapsibleTreeOutput('tree', height = '5000px')))
        ),
        
        
        
        # Section: Temporal Gap
        tabItem(
          tabName = "time",
          includeMarkdown("www/temporal.md"),
          HTML("<hr style='border-color: darkgreen; border-width: 1px; border-style: solid;'>"),
          fluidRow(
            column(3,
                   selectizeInput(
                     inputId = "time.taxaSubGroup",
                     label = "選擇物種類群：",
                     choices = NULL,
                     multiple = TRUE,
                     options = list(create = TRUE)
                   ),
                   br(),
                   sliderInput("time.year", "選擇年份區間：", min = 1900, max = 2024, value = c(1900, 2024), step = 1),
                   br(),
                   selectizeInput(
                     inputId = "time.month",
                     label = "選擇月份：",
                     choices = 1:12,
                     selected = 1:12,
                     multiple = TRUE,
                     options = list(create = TRUE)
                   )
            ),
            column(9,
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
          includeMarkdown("www/spatial.md"),
          HTML("<hr style='border-color: darkgreen; border-width: 1px; border-style: solid;'>"),
          fluidRow(
            column(
              width = 4,
              box(
                width = 12,
                checkboxInput("showAll", HTML("<b>顯示所有記錄</b>"), value = T),
                HTML("<b>或</b>"), br(), br(),
                selectizeInput(
                  inputId = "spatial.taxaSubGroup",
                  label = "選擇物種類群：",
                  choices = NULL,
                  multiple = T,
                  options = list(create = T)
                )
              ),
              box(
                title = "物種類群與記錄筆數",
                width = 12,
                DTOutput("df_spatial_allOccCount_grid_table"), 
                style = "width: 100%;"
                )
              ),
            column(
              width = 8,
              leafletOutput("spatialMap", height = 900)
            )
          )
        ),

        
        
        # Section: Fill the Gap!
        tabItem(tabName = "fillgap",
                includeMarkdown("www/fillgap.md"),
                HTML("<hr style='border-color: darkgreen; border-width: 1px; border-style: solid;'>"),
                fluidRow(valueBox(10 * 2, "優先填補", icon = icon("triangle-exclamation"), color = "red"),
                         valueBox(10 * 2, "中等", icon = icon("star"), color = "orange"),
                         valueBox(10 * 2, "不優先", icon = icon("thumbs-up"), "yellow")),
                fluidRow(column(width = 7, leafletOutput("gapMap", height = 650)),
                         column(width = 5, DTOutput("gapCount"), title = "Priority level and grid count by land type"))
                ),
                


        # Section: References
        tabItem(tabName = "references", 
                includeMarkdown("www/references.md")),
        
        
        
        # Section: Releases
        tabItem(tabName = "releases", 
                includeMarkdown("www/releases.md"))
        
        
        
        ) # end tabItems
    
      ) # end dashboardBody
  
  ) # end dashboardPage

)) # end fluidPage
