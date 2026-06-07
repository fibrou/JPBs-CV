library(shiny)
library(DBI)
library(RSQLite)
library(dplyr)
library(here)

DB_PATH <- here("cv-app-test", "cv.db")

get_con <- function() dbConnect(SQLite(), DB_PATH)

# ── helpers ───────────────────────────────────────────────────────────────────

read_tbl <- function(tbl) {
  con <- get_con(); on.exit(dbDisconnect(con))
  dbReadTable(con, tbl)
}

delete_row <- function(tbl, id) {
  con <- get_con(); on.exit(dbDisconnect(con))
  dbExecute(con, sprintf("DELETE FROM \"%s\" WHERE rowid = ?", tbl), params = list(id))
}

upsert_row <- function(tbl, values, rowid = NULL) {
  con <- get_con(); on.exit(dbDisconnect(con))
  cols <- names(values)
  if (is.null(rowid)) {
    sql <- sprintf('INSERT INTO "%s" (%s) VALUES (%s)',
                   tbl,
                   paste(sprintf('"%s"', cols), collapse = ","),
                   paste(rep("?", length(cols)), collapse = ","))
    dbExecute(con, sql, params = unname(values))
  } else {
    sets <- paste(sprintf('"%s" = ?', cols), collapse = ", ")
    sql  <- sprintf('UPDATE "%s" SET %s WHERE rowid = ?', tbl, sets)
    dbExecute(con, sql, params = c(unname(values), list(rowid)))
  }
}

# ── section module ────────────────────────────────────────────────────────────

section_ui <- function(id, label) {
  ns <- NS(id)
  tagList(
    h3(label),
    fluidRow(column(12, DT::dataTableOutput(ns("tbl")))),
    hr(),
    h4(textOutput(ns("form_title"))),
    uiOutput(ns("form_fields")),
    fluidRow(
      column(2, actionButton(ns("save"),   "Save",        class = "btn-primary")),
      column(2, actionButton(ns("cancel"), "Cancel")),
      column(2, actionButton(ns("add"),    "Add New Row", class = "btn-success")),
      column(2, actionButton(ns("delete"), "Delete Selected", class = "btn-danger"))
    ),
    tags$br()
  )
}

section_server <- function(id, tbl_name, col_defs) {
  moduleServer(id, function(input, output, session) {
    ns      <- session$ns
    rv      <- reactiveValues(data = NULL, editing_rowid = NULL)

    refresh <- function() {
      con <- get_con(); on.exit(dbDisconnect(con))
      rv$data <- dbGetQuery(con, sprintf('SELECT rowid, * FROM "%s"', tbl_name))
    }
    refresh()

    output$tbl <- DT::renderDataTable({
      req(rv$data)
      # Hide the rowid column from display but keep it for selection
      display <- rv$data[, -1, drop = FALSE]
      DT::datatable(display, selection = "single", rownames = FALSE,
                    options = list(pageLength = 10, scrollX = TRUE))
    })

    output$form_title <- renderText({
      if (is.null(rv$editing_rowid)) "" else
        if (rv$editing_rowid == 0L) "New Row" else paste("Editing row")
    })

    output$form_fields <- renderUI({
      req(!is.null(rv$editing_rowid))
      row_data <- if (rv$editing_rowid > 0L) {
        rv$data[rv$data$rowid == rv$editing_rowid, , drop = FALSE]
      } else NULL

      lapply(names(col_defs), function(col) {
        val <- if (!is.null(row_data) && col %in% names(row_data))
          as.character(row_data[[col]][1]) else ""
        val <- if (is.na(val)) "" else val
        if (nchar(val) > 80) {
          textAreaInput(ns(col), label = col_defs[[col]], value = val, rows = 3)
        } else {
          textInput(ns(col), label = col_defs[[col]], value = val)
        }
      })
    })

    observeEvent(input$tbl_rows_selected, {
      sel <- input$tbl_rows_selected
      if (length(sel) == 1) rv$editing_rowid <- rv$data$rowid[sel]
    })

    observeEvent(input$add,    { rv$editing_rowid <- 0L })
    observeEvent(input$cancel, { rv$editing_rowid <- NULL })

    observeEvent(input$save, {
      req(!is.null(rv$editing_rowid))
      values <- lapply(names(col_defs), function(col) {
        v <- input[[col]]
        if (is.null(v) || trimws(v) == "") NA_character_ else trimws(v)
      })
      names(values) <- names(col_defs)
      rid <- if (rv$editing_rowid == 0L) NULL else rv$editing_rowid
      upsert_row(tbl_name, values, rid)
      rv$editing_rowid <- NULL
      refresh()
    })

    observeEvent(input$delete, {
      sel <- input$tbl_rows_selected
      if (length(sel) != 1) {
        showNotification("Select a row first.", type = "warning")
        return()
      }
      rid <- rv$data$rowid[sel]
      showModal(modalDialog(
        title  = "Delete row?",
        "This cannot be undone.",
        footer = tagList(
          actionButton(ns("confirm_delete"), "Yes, delete", class = "btn-danger"),
          modalButton("Cancel")
        )
      ))
    })

    observeEvent(input$confirm_delete, {
      sel <- input$tbl_rows_selected
      if (length(sel) == 1) {
        delete_row(tbl_name, rv$data$rowid[sel])
        rv$editing_rowid <- NULL
        refresh()
      }
      removeModal()
    })
  })
}

# ── column definitions ────────────────────────────────────────────────────────

cols <- list(

  admin = list(
    institution = "Institution",
    title       = "Role / Title",
    detail      = "Detail"
  ),

  lt_work = list(
    institution = "Institution",
    startMonth  = "Start Month",
    startYear   = "Start Year",
    endMonth    = "End Month",
    endYear     = "End Year",
    where       = "Location",
    detail      = "Detail / Bullet"
  ),

  st_work = list(
    institution = "Institution",
    startMonth  = "Start Month",
    startYear   = "Start Year",
    endMonth    = "End Month",
    endYear     = "End Year",
    where       = "Location",
    detail      = "Detail"
  ),

  education = list(
    inst      = "Institution",
    degree    = "Degree",
    startYear = "Start Year",
    endYear   = "End Year",
    where     = "Location",
    detail    = "Detail"
  ),

  certifications = list(
    certBody       = "Certifying Body",
    accomplishment = "Certification Name",
    year           = "Year",
    where          = "Location",
    detail         = "Detail"
  ),

  honors_grants = list(
    honorGrant = "Honor / Grant",
    grantor    = "Grantor",
    where      = "Location",
    year       = "Year",
    detail     = "Detail"
  ),

  publications = list(
    articleTitle = "Title",
    authors      = "Co-Authors",
    journal      = "Journal / Citation",
    year         = "Year"
  ),

  papers_in_progress = list(
    articleTitle = "Title",
    authors      = "Co-Authors",
    status       = "Status"
  ),

  other_pubs_monos = list(
    title   = "Title",
    outlet  = "Outlet / Book",
    year    = "Year",
    authors = "Co-Authors"
  ),

  academic_presentations = list(
    articleTitle = "Title",
    authors      = "Co-Authors",
    detail       = "Conference / Location / Year"
  ),

  pedagogy_presentations = list(
    title  = "Title",
    detail = "Venue / Year"
  ),

  academic_discussions = list(
    articleTitle = "Paper Discussed",
    authors      = "Paper Authors",
    detail       = "Conference / Year"
  ),

  conf_committees = list(
    conference = "Conference / Track",
    role       = "Role",
    details    = "Year / Location"
  ),

  conf_chair = list(
    conference = "Session Chaired",
    details    = "Conference / Year"
  ),

  editor = list(
    role    = "Role",
    journal = "Journal",
    begYear = "Begin Year",
    endYear = "End Year"
  ),

  ad_hoc_review = list(
    outletName = "Outlet / Journal",
    outletType = "Type"
  ),

  t_and_p = list(
    task   = "Task / Action",
    school = "School",
    year   = "Year",
    role   = "Your Role"
  ),

  professional_offices = list(
    title   = "Title",
    group   = "Organization",
    begYear = "Begin Year",
    endYear = "End Year"
  ),

  academic_leadership = list(
    title   = "Title",
    school  = "School",
    begYear = "Begin Year",
    endYear = "End Year"
  ),

  academic_committees = list(
    committeeName = "Committee",
    institution   = "Institution",
    begYear       = "Begin Year",
    endYear       = "End Year"
  ),

  dissertation_committees = list(
    student   = "Student",
    dissTitle = "Dissertation Title",
    school    = "School",
    year      = "Year",
    role      = "Your Role"
  ),

  theses_supervision = list(
    student    = "Student",
    thesisTitle = "Thesis Title",
    school     = "School",
    year       = "Year",
    role       = "Your Role"
  ),

  student_mentoring = list(
    role     = "Your Role",
    activity = "Activity / Program",
    begYear  = "Begin Year",
    endYear  = "End Year",
    school   = "School"
  ),

  prof_training = list(
    role    = "Your Role",
    activity = "Program",
    group   = "Sponsor / Organization",
    begYear = "Begin Year",
    endYear = "End Year"
  ),

  media_interviews = list(
    modality = "Medium",
    topic    = "Topic",
    outlet   = "Outlet",
    year     = "Year"
  ),

  biz_experiences = list(
    title   = "Title",
    company = "Company",
    begYear = "Begin Year",
    endYear = "End Year"
  ),

  references = list(
    name    = "Name",
    title   = "Title / Position",
    details = "Contact Details"
  )
)

# ── UI ────────────────────────────────────────────────────────────────────────

ui <- fluidPage(
  tags$head(tags$style(HTML("
    body { font-family: 'Segoe UI', sans-serif; font-size: 13px; }
    h3   { color: #990000; margin-top: 8px; }
  "))),
  titlePanel("CV Data Manager — JPB"),
  tabsetPanel(
    tabPanel("Admin Roles",             section_ui("admin",                  "Administrative Roles")),
    tabPanel("Long-Term Employment",    section_ui("lt_work",                "Long-Term Employment")),
    tabPanel("Short-Term Employment",   section_ui("st_work",                "Short-Term / Visiting Positions")),
    tabPanel("Education",               section_ui("education",              "Education")),
    tabPanel("Certifications",          section_ui("certifications",         "Certifications")),
    tabPanel("Honors & Grants",         section_ui("honors_grants",          "Honors & Grants")),
    tabPanel("Publications",            section_ui("publications",           "Publications")),
    tabPanel("Papers in Progress",      section_ui("papers_in_progress",     "Papers in Progress")),
    tabPanel("Other Pubs / Monos",      section_ui("other_pubs_monos",       "Other Publications & Monographs")),
    tabPanel("Academic Presentations",  section_ui("academic_presentations", "Academic Presentations")),
    tabPanel("Pedagogy Presentations",  section_ui("pedagogy_presentations", "Pedagogy Presentations")),
    tabPanel("Academic Discussions",    section_ui("academic_discussions",   "Academic Discussions")),
    tabPanel("Conf Committees",         section_ui("conf_committees",        "Conference Committees")),
    tabPanel("Conf Chair",              section_ui("conf_chair",             "Conference Session Chair")),
    tabPanel("Editorial",               section_ui("editor",                 "Editorial Roles")),
    tabPanel("Ad Hoc Review",           section_ui("ad_hoc_review",         "Ad Hoc Review")),
    tabPanel("T&P Reviews",             section_ui("t_and_p",                "Tenure & Promotion Reviews")),
    tabPanel("Professional Offices",    section_ui("professional_offices",   "Professional Offices")),
    tabPanel("Academic Leadership",     section_ui("academic_leadership",    "Academic Leadership")),
    tabPanel("Academic Committees",     section_ui("academic_committees",    "Academic Committees")),
    tabPanel("Dissertation Committees", section_ui("dissertation_committees","Dissertation Committees")),
    tabPanel("Theses Supervision",      section_ui("theses_supervision",     "Theses Supervision")),
    tabPanel("Student Mentoring",       section_ui("student_mentoring",      "Student Mentoring")),
    tabPanel("Prof Training",           section_ui("prof_training",          "Professional Training")),
    tabPanel("Media",                   section_ui("media_interviews",       "Media Interviews")),
    tabPanel("Business Experience",     section_ui("biz_experiences",        "Business Experience")),
    tabPanel("References",              section_ui("references",             "References"))
  )
)

# ── Server ────────────────────────────────────────────────────────────────────

server <- function(input, output, session) {
  for (tbl in names(cols)) {
    local({
      t <- tbl
      section_server(t, t, cols[[t]])
    })
  }
}

shinyApp(ui, server)
