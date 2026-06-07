# ── migrate_publications_structured.R (v2) ───────────────────────────────
library(DBI)
library(RSQLite)
library(dplyr)
library(stringr)
library(purrr)
library(here)

db_path <- here("cv-app-test", "cv.db")
con     <- dbConnect(RSQLite::SQLite(), db_path)
cat("Connected:", db_path, "\n\n")

# ── Step 1: Add new columns ───────────────────────────────────────────────
existing <- dbListFields(con, "publications")
new_cols  <- c("journal_name", "vol_issue_pages", "doi", "link_url",
               "doi_flag", "citations")

for (col in new_cols) {
  col_type <- if (col == "citations") "INTEGER" else "TEXT"
  if (!col %in% existing) {
    dbExecute(con, sprintf("ALTER TABLE publications ADD COLUMN %s %s", col, col_type))
    cat(sprintf("✓ Added '%s' (%s)\n", col, col_type))
  } else {
    cat(sprintf("✓ '%s' already exists\n", col))
  }
}
cat("\n")

# ── Step 2: Parsing function ──────────────────────────────────────────────
parse_journal_field <- function(s) {
  doi      <- NA_character_
  link_url <- NA_character_

  s <- str_replace(s,
    "https?://dx\\.doi\\.org/https://doi\\.org/",
    "https://doi.org/")

  m_doi <- str_match(s, "https?://(?:dx\\.)?doi\\.org/(10\\.[^\\s,]+)")
  if (!is.na(m_doi[,2])) {
    doi <- str_remove(m_doi[,2], "[.,;)]+$")
    s   <- str_remove(s, "\\.?\\s*Available\\s+at\\s+https?://(?:dx\\.)?doi\\.org/[^\\s,]+")
    s   <- str_remove(s, ",?\\s*https?://(?:dx\\.)?doi\\.org/[^\\s,]+")
  } else {
    m_url <- str_match(s, "Available\\s+at\\s+(https?://[^\\s]+)")
    if (!is.na(m_url[,2])) {
      link_url <- str_remove(m_url[,2], "[.,;)]+$")
      s <- str_remove(s, ",?\\s*\\.?\\s*Available\\s+at\\s+https?://[^\\s]+")
    }
  }

  s <- str_trim(s) |> str_remove("[.,]+$") |> str_trim()

  m_vol <- str_match(s, ",\\s*(v\\d+.*)$")
  if (!is.na(m_vol[,2])) {
    vol_issue_pages <- str_trim(m_vol[,2])
    journal_name    <- str_trim(str_remove(s, ",\\s*v\\d+.*$"))
  } else {
    vol_issue_pages <- NA_character_
    journal_name    <- str_trim(s)
  }

  list(journal_name    = journal_name,
       vol_issue_pages = vol_issue_pages,
       doi             = doi,
       link_url        = link_url)
}

# ── Step 3: Parse all rows ────────────────────────────────────────────────
pubs <- dbReadTable(con, "publications")
cat("Parsing", nrow(pubs), "publications...\n\n")

results <- map_dfr(seq_len(nrow(pubs)), function(i) {
  parsed <- parse_journal_field(pubs$journal[i])
  tibble(
    row             = i,
    articleTitle    = substr(pubs$articleTitle[i], 1, 55),
    year            = pubs$year[i],
    journal_name    = parsed$journal_name,
    vol_issue_pages = parsed$vol_issue_pages,
    doi             = parsed$doi,
    link_url        = parsed$link_url
  )
})

# Initialize doi_flag BEFORE any assignments
results$doi_flag <- NA_character_

# ── Step 4: Apply known corrections ──────────────────────────────────────
idx <- which(str_detect(pubs$journal, "Annals of Actuarial"))
if (length(idx) > 0) {
  results$doi[idx]      <- "10.1017/S1748499517000264"
  results$doi_flag[idx] <- "DOI corrected: trailing '2018' removed"
}

idx <- which(str_detect(pubs$journal, "Consumer Affairs"))
if (length(idx) > 0) {
  results$doi[idx]      <- "10.1111/j.1745-6606.2008.00105.x"
  results$doi_flag[idx] <- "DOI corrected: typos fixed"
}

idx <- which(str_detect(pubs$journal, "Nordic Journal"))
if (length(idx) > 0) {
  results$doi_flag[idx] <- "DOI not in source data — look up at doi.org"
}

idx <- which(str_detect(pubs$journal, "Interaction and Coordination"))
if (length(idx) > 0) {
  results$doi_flag[idx] <- "DOI not in source data — look up at doi.org"
}

idx <- which(str_detect(pubs$journal, "jstor"))
if (length(idx) > 0) {
  results$doi_flag[idx] <- "JSTOR link in link_url; check if DOI exists"
}

# ── Step 5: Write to database ─────────────────────────────────────────────
cat("Writing to database...\n")
for (i in seq_len(nrow(results))) {
  dbExecute(con, "
    UPDATE publications
    SET journal_name    = ?,
        vol_issue_pages = ?,
        doi             = ?,
        link_url        = ?,
        doi_flag        = ?
    WHERE articleTitle = ?",
    params = list(
      results$journal_name[i],
      results$vol_issue_pages[i],
      results$doi[i],
      results$link_url[i],
      results$doi_flag[i],
      pubs$articleTitle[i]
    )
  )
}

# ── Step 6: Verification ──────────────────────────────────────────────────
cat("\n── Results ──\n\n")
check <- dbGetQuery(con, "
  SELECT year, journal_name,
         CASE WHEN doi IS NOT NULL AND doi != '' THEN 'YES' ELSE '---' END AS has_doi,
         COALESCE(doi_flag, '') AS flag
  FROM publications
  ORDER BY CAST(year AS INTEGER) DESC")
print(check, row.names = FALSE)

n_doi     <- sum(!is.na(results$doi) & results$doi != "")
n_flagged <- sum(!is.na(results$doi_flag))
cat(sprintf("\n  %d / %d publications have a DOI\n", n_doi, nrow(pubs)))
cat(sprintf("  %d rows flagged for review\n", n_flagged))

dbDisconnect(con)
cat("\n── Done ──\n")
