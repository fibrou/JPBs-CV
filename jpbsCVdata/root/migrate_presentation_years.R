# ── migrate_presentation_years.R ──────────────────────────────────────────
# Adds a sortable `year` INTEGER column to all 5 presentation-type tables
# by extracting the most recent 4-digit year from each row's detail text.
#
# Strategy: take the MAX year mentioned in the detail string.
# For multi-venue entries like "Paris 2019; Stockholm 2020" → stores 2020.
# This represents the most recent presentation of each paper/talk.
#
# Tables modified:
#   academic_presentations  (detail column,  31 rows)
#   pedagogy_presentations  (detail column,   6 rows)
#   academic_discussions    (detail column,  20 rows)
#   conf_committees         (details column,  7 rows)
#   conf_chair              (details column, 10 rows)
# ─────────────────────────────────────────────────────────────────────────

library(DBI)
library(RSQLite)
library(dplyr)
library(stringr)
library(here)

db_path <- here("cv-app-test", "cv.db")
con     <- dbConnect(RSQLite::SQLite(), db_path)
cat("Connected:", db_path, "\n\n")

# ── Helper: extract most-recent year from a string ────────────────────────
extract_max_year <- function(text) {
  if (is.na(text) || text == "") return(NA_integer_)
  years <- as.integer(str_extract_all(text, "\\b(19\\d{2}|20[012]\\d)\\b")[[1]])
  if (length(years) == 0) return(NA_integer_)
  max(years)
}

# ── Tables and their text column names ────────────────────────────────────
tables <- list(
  list(tbl = "academic_presentations",  text_col = "detail"),
  list(tbl = "pedagogy_presentations",  text_col = "detail"),
  list(tbl = "academic_discussions",    text_col = "detail"),
  list(tbl = "conf_committees",         text_col = "details"),
  list(tbl = "conf_chair",              text_col = "details")
)

for (t in tables) {
  tbl      <- t$tbl
  text_col <- t$text_col
  cat(sprintf("── %s ──\n", tbl))
  
  # Add year column if missing
  existing <- dbListFields(con, tbl)
  if (!"year" %in% existing) {
    dbExecute(con, sprintf("ALTER TABLE \"%s\" ADD COLUMN year INTEGER", tbl))
    cat("  ✓ Added 'year' column\n")
  } else {
    cat("  ✓ 'year' column already exists\n")
  }
  
  # Read table, extract years, write back
  df <- dbReadTable(con, tbl)
  df$year <- vapply(df[[text_col]], extract_max_year, integer(1))
  
  # Update row by row using rowid
  # SQLite auto-creates rowid for every table
  dbExecute(con, sprintf("UPDATE \"%s\" SET year = NULL", tbl))  # reset first
  
  for (i in seq_len(nrow(df))) {
    if (!is.na(df$year[i])) {
      # Use the text column value as the WHERE anchor (titles are unique enough)
      title_col <- names(df)[1]  # first column is always the title/article/conference
      dbExecute(
        con,
        sprintf("UPDATE \"%s\" SET year = ? WHERE \"%s\" = ? AND \"%s\" = ?",
                tbl, title_col, text_col),
        params = list(df$year[i], df[[title_col]][i], df[[text_col]][i])
      )
    }
  }
  
  # Show results
  result <- dbGetQuery(con,
    sprintf("SELECT year, \"%s\" AS text_snippet FROM \"%s\" ORDER BY year DESC",
            text_col, tbl))
  result$text_snippet <- substr(result$text_snippet, 1, 65)
  print(result)
  cat("\n")
}

# ── Verification summary ──────────────────────────────────────────────────
cat("── Summary ──\n")
for (t in tables) {
  n_total <- dbGetQuery(con,
    sprintf("SELECT COUNT(*) AS n FROM \"%s\"", t$tbl))$n
  n_dated <- dbGetQuery(con,
    sprintf("SELECT COUNT(*) AS n FROM \"%s\" WHERE year IS NOT NULL", t$tbl))$n
  cat(sprintf("  %-30s %d / %d rows dated\n", t$tbl, n_dated, n_total))
}

dbDisconnect(con)
cat("\n── Done ──\n")
