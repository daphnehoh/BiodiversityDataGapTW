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
                    
                    # language icon
                    tags$li(class = "dropdown",
                            tags$a(href = "https://biodivdatagap-en.tbiadata.tw", 
                                   icon("globe"), class = "nav-link", target = "_blank")),
                    
                    # github icon
                    tags$li(class = "dropdown",
                            tags$a(href = "https://github.com/daphnehoh/BiodiversityDataGapTW", 
                                   icon("github"), class = "nav-link", target = "_blank"))
                    ),
    
    # sidebar
    dashboardSidebar(width = 300,
      sidebarMenu(
        HTML(paste0(
          "<br>",
          "<a href='https://tbiadata.tw' target='_blank'>
          <img style='display: block; margin-left: auto; margin-right: auto;' src='TBIA_logo_white.png' width='270'></a>",
          "<br>"
        )),
        menuItem(HTML("&nbsp;首頁"), tabName = "home", icon = icon("home")),
        menuItem(HTML("&nbsp;説明"), tabName = "descriptions", icon = icon("pencil")),
        menuItem(HTML("&nbsp;物種類群資料概況"), tabName = "taxa", icon = icon("tree")),
        menuItem(HTML("&nbsp;物種樹"), tabName = "tree", icon = icon("tree")),
        menuItem(HTML("&nbsp;時間資料概況"), tabName = "time", icon = icon("clock")),
        menuItem(HTML("&nbsp;空間資料概況"), tabName = "map", icon = icon("map-location-dot")),
        menuItem(HTML("&nbsp;一起填補空缺！"), tabName = "fillgap", icon = icon("map-marked-alt")),
        menuItem(HTML("&nbsp;Call for Data"), tabName = "callfordata", icon = icon("phone")),
        menuItem(HTML("&nbsp;發布與參考"), tabName = "releases", icon = icon("tasks")),
        
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
          "<div style='text-align: center; font-size: small;'>Last update: 2024-10-27</div>")
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
        
        # Section: Home # --------------------------------------------------------------------
        tabItem(tabName = "home", 
                includeMarkdown("www/home.md")
                ),
        
        
        
        # Section: Descriptions # --------------------------------------------------------------------
        tabItem(tabName = "descriptions", 
                fluidRow(
                  HTML("<h3>&nbsp;&nbsp;資料説明</h3>"),
                  br(),
                  valueBox(value = paste("22,510,389"), subtitle = "所有 TBIA 資料 (ver20241026)", icon = icon("database"), color = "red"),
                  valueBox(value = paste("21,031,819"), subtitle = "已清理的 TBIA 資料", icon = icon("broom"), color = "orange")),
                includeMarkdown("www/descriptions.md")
                ),
        
        
        
        # Section: Taxonomic Gap # --------------------------------------------------------------------
        tabItem(tabName = "taxa",
                includeMarkdown("www/taxa.md"),
                HTML("<hr style='border-color: darkgreen; border-width: 1px; border-style: solid;'>"),
                HTML("<h4><b>TaiCOL 裡的 TBIA 紀錄：</b></h4>"),
                
                fluidRow(
                  column(6,
                         div(HTML("<b>對到最高林奈階層的紀錄 %</b>"), style = "margin-bottom: 10px;"),
                         plotlyOutput("taxa.pie.taxonRank", height = 400)),
                  column(6,
                         div(HTML("<b>入口網曾與未曾紀錄的 TaiCOL 種（包含種下）階層 % 數</b>"), style = "margin-bottom: 10px;"),
                         plotlyOutput("taxa.pie.TaiCOL", height = 400))),
                
                br(),
                HTML("<hr style='border-color: darkgreen; border-width: 1px; border-style: solid;'>"),
                
                fluidRow(
                  column(4,
                         div(HTML("<b>物種類群與紀錄筆數：</b>"), style = "margin-bottom: 10px;"),
                         br(),
                         div(DTOutput("df_allOccCount_grid_table"), style = "width: 100%;")),
                  
                  column(8,
                         div(HTML("<b>物種類群與資料類型：</b>"), style = "margin-bottom: 10px;"),
                         HTML("此圖讓您檢視物種類群與資料類型的數量分布。顔色越淺表示資料數量越多。"),
                         br(),
                         plotlyOutput("df_bof", height = 800))
                  ),
                
                br(),
                HTML("<hr style='border-color: darkgreen; border-width: 1px; border-style: solid;'>"),
                
                HTML("<h4><b>物種類群在各棲地類型（比照 TaiCOL）的數量統計：</b></h4>"),
                HTML("備注：有些入口網的物種紀錄在 TaiCOL 還未收錄，所以會有 “入口網已紀錄物種數” 比 “TaiCOL總物種數” 還要多的情況。這情況目前僅限於兩棲類與蕨類。"),
                br(),
                HTML("長條圖可用鼠標選擇範圍放大，點擊兩下會回到預設模式。"),
                br(),
                br(),
                column(2, uiOutput("taxa.landtype.taxa.prop"), br()),
                br(),
                column(12,
                       div(HTML("<b>TBIA 裡已紀錄與未紀錄物種（不包含種下）</b>"), style = "margin-bottom: 10px;"),
                       plotlyOutput("taxa.bar.unrecorded.taxa", height = 500))
        ),
      
        
        
        # Section: Species Tree # --------------------------------------------------------------------
        tabItem(tabName = "tree",
                includeMarkdown("www/tree.md"),
                HTML("<hr style='border-color: darkgreen; border-width: 1px; border-style: solid;'>"),
                column(3, uiOutput("taxa.treeSubGroup")),
                column(2, downloadButton("downloadData", "下載入口網未曾紀錄物種名錄")),
                column(12, 
                       box(width = 12, style = "overflow-y: scroll; height: 5000px;",
                       collapsibleTreeOutput('tree', height = '5000px')))
                ),
        
        
        
        # Section: Temporal Gap # --------------------------------------------------------------------
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
      
        
        
        # Section: Spatial Gap # --------------------------------------------------------------------
        tabItem(
          tabName = "map",
          includeMarkdown("www/spatial.md"),
          HTML("<hr style='border-color: darkgreen; border-width: 1px; border-style: solid;'>"),
          fluidRow(
            column(
              width = 4,
              box(
                width = 12,
                checkboxInput("showAll", HTML("<b>顯示所有紀錄</b>"), value = T),
                HTML("<b>或</b>"), br(), br(),
                selectizeInput(
                  inputId = "spatial.taxaSubGroup",
                  label = "選擇物種類群：",
                  choices = NULL,
                  multiple = T,
                  options = list(create = T)
                )))),
            fluidRow(
              column(
                width = 12,
                leafletOutput("spatialMap", height = 900))
            )
          ),

        
        
        # Section: Fill the Gap! # --------------------------------------------------------------------
        tabItem(tabName = "fillgap",
                includeMarkdown("www/fillgap.md"),
                HTML("<hr style='border-color: darkgreen; border-width: 1px; border-style: solid;'>"),
                fluidRow(valueBox(4387, "建議優先填補網格數", icon = icon("triangle-exclamation"), color = "maroon"),
                         valueBox(390, "建議填補網格數", icon = icon("star"), color = "purple"),
                         valueBox(1028, "資料筆數高於平均值網格數", icon = icon("thumbs-up"), "blue")),
                fluidRow(column(width = 4, uiOutput("gap.priority"))),
                fluidRow(column(width = 8, leafletOutput("gapMap", height = 650)),
                         column(width = 4, DTOutput("gapCount")))
                ),
        
        
        
        # Section: Call for data # --------------------------------------------------------------------
        tabItem(tabName = "callfordata", 
                includeMarkdown("www/callfordata.md")
        ),
        
        
        
        # Section: Releases & Ref # --------------------------------------------------------------------
        tabItem(tabName = "releases", 
                includeMarkdown("www/releases.md"),
                HTML("<hr style='border-color: darkgreen; border-width: 1px; border-style: solid;'>"),
                includeMarkdown("www/references.md"))
        
        
        ) # end tabItems
    
      ) # end dashboardBody
  
  ) # end dashboardPage

)) # end fluidPage