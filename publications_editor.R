# ── publications_editor.R ─────────────────────────────────────────────────
# Standalone Shiny app: edit publications metadata in cv.db.
# Run with: shiny::runApp("publications_editor.R")
# Or from RStudio: open file → click "Run App"
#
# Lets you fix/add: doi, link_url, vol_issue_pages, journal_name, citations
# Shows doi_flag warnings prominently so you know which rows need attention.
# ─────────────────────────────────────────────────────────────────────────

library(shiny)
library(DBI)
library(RSQLite)
library(dplyr)
library(here)

DB_PATH <- here("cv-app-test", "cv.db")

# ── Helpers ───────────────────────────────────────────────────────────────
get_pubs <- function() {
  con <- dbConnect(RSQLite::SQLite(), DB_PATH)
  on.exit(dbDisconnect(con))
  dbGetQuery(con, "
    SELECT rowid,
           CAST(year AS INTEGER)   AS year,
           articleTitle,
           authors,
           journal_name,
           vol_issue_pages,
           doi,
           link_url,
           citations,
           doi_flag
    FROM publications
    ORDER BY CAST(year AS INTEGER) DESC
  ")
}

save_row <- function(rowid, journal_name, vol_issue_pages,
                     doi, link_url, citations) {
  con <- dbConnect(RSQLite::SQLite(), DB_PATH)
  on.exit(dbDisconnect(con))
  dbExecute(con, "
    UPDATE publications
    SET journal_name    = ?,
        vol_issue_pages = ?,
        doi             = ?,
        link_url        = ?,
        citations       = ?,
        doi_flag        = CASE WHEN ? != '' THEN NULL ELSE doi_flag END
    WHERE rowid = ?",
    params = list(
      journal_name,
      vol_issue_pages,
      doi,
      link_url,
      if (is.na(citations) || citations == "") NA_integer_ else as.integer(citations),
      doi,   # if doi is now non-empty, clear the flag
      rowid
    )
  )
}

# ── UI ────────────────────────────────────────────────────────────────────
ui <- fluidPage(
  
  tags$head(tags$style(HTML("
    body { font-family: 'Segoe UI', sans-serif; background: #f8f9fa; }
    .pub-card { background: white; border-radius: 8px; padding: 20px;
                margin-bottom: 16px; border-left: 4px solid #900000;
                box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
    .pub-card.flagged { border-left-color: #c0392b; background: #fff5f5; }
    .pub-title { font-weight: 600; font-size: 1.05rem; color: #222; margin-bottom: 4px; }
    .pub-authors { color: #666; font-size: 0.9rem; margin-bottom: 8px; }
    .flag-banner { background: #fce8e8; color: #900000; padding: 8px 12px;
                   border-radius: 4px; margin-bottom: 10px;
                   font-size: 0.88rem; font-weight: 500; }
    .save-btn { background: #900000 !important; color: white !important;
                border: none !important; }
    .save-btn:hover { background: #6b0000 !important; }
    h2 { color: #900000; }
    .stats-bar { background: white; padding: 12px 20px; border-radius: 8px;
                 margin-bottom: 20px; display: flex; gap: 30px;
                 box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
    .stat-item { text-align: center; }
    .stat-num { font-size: 1.5rem; font-weight: bold; color: #900000; }
    .stat-label { font-size: 0.8rem; color: #666; }
  "))),
  
  titlePanel("Publications Editor — cv.db"),
  
  fluidRow(
    column(12,
      
      # Stats bar
      uiOutput("stats_bar"),
      
      # Filter controls
      wellPanel(
        fluidRow(
          column(4,
            selectInput("filter_flag", "Show:",
              choices = c("All publications" = "all",
                          "Flagged (need review)" = "flagged",
                          "Missing DOI" = "missing_doi",
                          "Has DOI" = "has_doi"))
          ),
          column(4, 
            textInput("search", "Search title:", placeholder = "Type to filter...")
          ),
          column(4,
            br(),
            actionButton("refresh", "↺ Refresh", class = "btn-secondary"),
            tags$span(" ", style = "display:inline-block;width:8px;"),
            downloadButton("export_csv", "Export CSV")
          )
        )
      ),
      
      # Publication cards (rendered dynamically)
      uiOutput("pub_cards")
    )
  )
)

# ── Server ────────────────────────────────────────────────────────────────
server <- function(input, output, session) {
  
  # Reactive data
  pubs_data <- reactiveVal(get_pubs())
  
  observeEvent(input$refresh, {
    pubs_data(get_pubs())
    showNotification("Data refreshed from cv.db", type = "message", duration = 2)
  })
  
  # Filtered view
  filtered_pubs <- reactive({
    df <- pubs_data()
    
    # Search filter
    if (!is.null(input$search) && nchar(trimws(input$search)) > 0) {
      srch <- tolower(trimws(input$search))
      df <- df[grepl(srch, tolower(df$articleTitle)), ]
    }
    
    # Flag filter
    switch(input$filter_flag,
      "flagged"     = df[!is.na(df$doi_flag) & df$doi_flag != "", ],
      "missing_doi" = df[is.na(df$doi) | df$doi == "", ],
      "has_doi"     = df[!is.na(df$doi) & df$doi != "", ],
      df  # "all"
    )
  })
  
  # Stats bar
  output$stats_bar <- renderUI({
    df <- pubs_data()
    n_total   <- nrow(df)
    n_doi     <- sum(!is.na(df$doi) & df$doi != "")
    n_flagged <- sum(!is.na(df$doi_flag) & df$doi_flag != "")
    n_cites   <- sum(!is.na(df$citations))
    
    div(class = "stats-bar",
      div(class = "stat-item",
          div(class = "stat-num", n_total),
          div(class = "stat-label", "Total Publications")),
      div(class = "stat-item",
          div(class = "stat-num", n_doi),
          div(class = "stat-label", "Have DOI")),
      div(class = "stat-item",
          div(class = "stat-num", style = if(n_flagged > 0) "color:#c0392b;" else "",
              n_flagged),
          div(class = "stat-label", "Need Review")),
      div(class = "stat-item",
          div(class = "stat-num", n_cites),
          div(class = "stat-label", "Have Citation Count"))
    )
  })
  
  # Dynamic publication cards
  output$pub_cards <- renderUI({
    df <- filtered_pubs()
    
    if (nrow(df) == 0) {
      return(p("No publications match the current filter.", style = "color:#666;"))
    }
    
    cards <- lapply(seq_len(nrow(df)), function(i) {
      pub     <- df[i, ]
      rid     <- pub$rowid
      id_safe <- paste0("pub_", rid)
      flagged <- !is.na(pub$doi_flag) && pub$doi_flag != ""
      
      div(class = paste0("pub-card", if (flagged) " flagged" else ""),
        
        div(class = "pub-title",
            sprintf("[%s] %s", pub$year, pub$articleTitle)),
        div(class = "pub-authors", pub$authors),
        
        # Flag warning
        if (flagged) div(class = "flag-banner",
                         paste0("⚠ ", pub$doi_flag)),
        
        fluidRow(
          column(4,
            textInput(paste0(id_safe, "_journal"),
                      "Journal name",
                      value = pub$journal_name %||% "")
          ),
          column(3,
            textInput(paste0(id_safe, "_vip"),
                      "Vol / Issue / Pages",
                      value = pub$vol_issue_pages %||% "")
          ),
          column(3,
            textInput(paste0(id_safe, "_doi"),
                      "DOI (no URL prefix)",
                      value = pub$doi %||% "",
                      placeholder = "10.xxxx/...")
          ),
          column(2,
            numericInput(paste0(id_safe, "_cites"),
                         "Citations",
                         value = pub$citations %||% NA,
                         min = 0)
          )
        ),
        
        fluidRow(
          column(6,
            textInput(paste0(id_safe, "_url"),
                      "Non-DOI URL (JSTOR, etc.)",
                      value = pub$link_url %||% "")
          ),
          column(6,
            br(),
            if (!is.na(pub$doi) && pub$doi != "") {
              tags$a(href = paste0("https://doi.org/", pub$doi),
                     target = "_blank",
                     class = "btn btn-sm btn-outline-secondary",
                     "Test DOI link →")
            },
            tags$span(" ", style = "display:inline-block;width:8px;"),
            actionButton(paste0(id_safe, "_save"),
                         "Save",
                         class = "btn-sm save-btn")
          )
        ),
        
        hr(style = "margin: 8px 0 0 0;")
      )
    })
    
    do.call(tagList, cards)
  })
  
  # Dynamic save observers — one per possible rowid
  # We use a factory pattern to avoid closure issues
  observe({
    df <- pubs_data()
    lapply(df$rowid, function(rid) {
      id_safe <- paste0("pub_", rid)
      btn_id  <- paste0(id_safe, "_save")
      
      observeEvent(input[[btn_id]], {
        
        journal_name    <- input[[paste0(id_safe, "_journal")]]
        vol_issue_pages <- input[[paste0(id_safe, "_vip")]]
        doi             <- trimws(input[[paste0(id_safe, "_doi")]])
        link_url        <- input[[paste0(id_safe, "_url")]]
        citations       <- input[[paste0(id_safe, "_cites")]]
        
        tryCatch({
          save_row(rid, journal_name, vol_issue_pages,
                   doi, link_url, citations)
          pubs_data(get_pubs())  # refresh
          showNotification(
            paste0("Saved: ", substr(
              df$articleTitle[df$rowid == rid], 1, 50)),
            type = "message", duration = 3)
        }, error = function(e) {
          showNotification(paste0("Error: ", e$message),
                           type = "error", duration = 5)
        })
        
      }, ignoreInit = TRUE)
    })
  })
  
  # CSV export
  output$export_csv <- downloadHandler(
    filename = function() paste0("publications_", Sys.Date(), ".csv"),
    content  = function(file) {
      write.csv(pubs_data()[, c("year","articleTitle","authors",
                                "journal_name","vol_issue_pages",
                                "doi","link_url","citations","doi_flag")],
                file, row.names = FALSE)
    }
  )
}

# Null coalescing operator
`%||%` <- function(a, b) if (!is.null(a) && !is.na(a) && a != "") a else b

shinyApp(ui, server)
