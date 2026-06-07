# ── load_cv_data_db.R ──────────────────────────────────────────────────────
# SQLite data loader for the Quarto website (Path B).
# Drop-in replacement for the Excel-based load_cv_data.r.
# Reads from cv-app-test/cv.db via DBI + RSQLite.
#
# Usage (in any .qmd setup chunk):
#   source(here("jpbsCVdata", "load_cv_data_db.R"))
#   cv <- load_cv_data_db()
#   publications <- cv$publications
# ─────────────────────────────────────────────────────────────────────────

library(DBI)
library(RSQLite)
library(here)

load_cv_data_db <- function(db_path = NULL) {
  
  if (is.null(db_path)) {
    db_path <- here("cv-app-test", "cv.db")
  }
  
  if (!file.exists(db_path)) {
    stop(
      "cv.db not found at: ", db_path,
      "\n  Check that cv-app-test/cv.db exists in the project root.",
      "\n  Project root (here): ", here()
    )
  }
  
  con <- dbConnect(RSQLite::SQLite(), db_path)
  on.exit(dbDisconnect(con), add = TRUE)
  
  # ── Core CV tables ────────────────────────────────────────────────────────
  list(
    # Positions & employment
    work                 = dbReadTable(con, "work"),
    lt_work              = dbReadTable(con, "lt_work"),
    st_work              = dbReadTable(con, "st_work"),
    biz_experiences      = dbReadTable(con, "biz_experiences"),
    academic_leadership  = dbReadTable(con, "academic_leadership"),
    
    # Administrative service
    admin                = dbReadTable(con, "admin"),
    
    # Education
    education            = dbReadTable(con, "education"),
    certifications       = dbReadTable(con, "certifications"),
    
    # Research output
    publications         = dbReadTable(con, "publications"),
    papers_in_progress   = dbReadTable(con, "papers_in_progress"),
    other_pubs           = dbReadTable(con, "other_pubs_monos"),
    
    # Presentations & discussions
    academic_presentations  = dbReadTable(con, "academic_presentations"),
    academic_discussions    = dbReadTable(con, "academic_discussions"),
    pedagogy_presentations  = dbReadTable(con, "pedagogy_presentations"),
    
    # Honors & grants
    honors               = dbReadTable(con, "honors"),
    honors_grants        = dbReadTable(con, "honors_grants"),
    
    # Service
    service_committees   = dbReadTable(con, "academic_committees"),
    conf_chair           = dbReadTable(con, "conf_chair"),
    conf_committees      = dbReadTable(con, "conf_committees"),
    professional_offices = dbReadTable(con, "professional_offices"),
    ad_hoc_review        = dbReadTable(con, "ad_hoc_review"),
    editor               = dbReadTable(con, "editor"),
    t_and_p              = dbReadTable(con, "t_and_p"),
    
    # Mentoring
    dissertation_committees = dbReadTable(con, "dissertation_committees"),
    theses_supervision      = dbReadTable(con, "theses_supervision"),
    student_mentoring       = dbReadTable(con, "student_mentoring"),
    
    # Professional development & skills
    prof_training        = dbReadTable(con, "prof_training"),
    skills               = dbReadTable(con, "skills"),
    
    # Media & outreach
    media_interviews     = dbReadTable(con, "media_interviews"),
    
    # References
    references           = dbReadTable(con, "references")
  )
}

# ── Convenience: format date ranges ─────────────────────────────────────────
format_date_range <- function(start, end, current_label = "Present") {
  dplyr::case_when(
    is.na(start) | start == ""                                  ~ "",
    is.na(end)   | end   == "" | tolower(end) == "present"      ~ paste0(start, "\u2013", current_label),
    TRUE                                                         ~ paste0(start, "\u2013", end)
  )
}
