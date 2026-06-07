# ── migrate_publications_structured.R ────────────────────────────────────
# Splits the publications `journal` column (currently one messy string)
# into four clean columns plus a citations counter.
#
# New columns added:
#   journal_name    TEXT   — journal name only
#   vol_issue_pages TEXT   — "v107 n2, 259-283" style string
#   doi             TEXT   — "10.xxxx/..." (no URL prefix)
#   link_url        TEXT   — non-DOI URL (JSTOR, etc.)
#   doi_flag        TEXT   — review note for 2 known bad DOIs
#   citations       INTEGER — NULL until populated; see fetch_citations.R
#
# The original `journal` column is KEPT as `journal` (untouched) for
# backward compatibility with jpbDataDrivenCV.Rmd.
#
# Known issues flagged (2 bad DOIs, 2 missing DOIs needing lookup):
#   Row  5  Annals of Actuarial Science    → DOI has trailing "2018" appended
#   Row 11  Journal of Consumer Affairs    → DOI has typo "10.111" & "1745-66-6"
#   Row  3  Nordic Journal of Business     → DOI not in data; needs lookup
#   Row  4  J. of Economic Interaction...  → DOI not in data; needs lookup
# ─────────────────────────────────────────────────────────────────────────

library(DBI)
library(RSQLite)
library(dplyr)
library(stringr)
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
  
  doi <- NA_character_
  link_url <- NA_character_
  
  # Fix malformed double-prefix URL (JFSR entry)
  s <- str_replace(s, "https?://dx\\.doi\\.org/https://doi\\.org/",
                      "https://doi.org/")
  
  # Extract DOI
  m_doi <- str_match(s,
    "https?://(?:dx\\.)?doi\\.org/(10\\.[^\\s,]+)")
  if (!is.na(m_doi[,2])) {
    doi <- str_remove(m_doi[,2], "[.,;)]+$")
    # Remove the DOI URL from string
    s <- str_remove(s,
      "\\.?\\s*Available\\s+at\\s+https?://(?:dx\\.)?doi\\.org/[^\\s,]+")
    s <- str_remove(s,
      ",?\\s*https?://(?:dx\\.)?doi\\.org/[^\\s,]+")
  } else {
    # Non-DOI URL (JSTOR etc.)
    m_url <- str_match(s, "Available\\s+at\\s+(https?://[^\\s]+)")
    if (!is.na(m_url[,2])) {
      link_url <- str_remove(m_url[,2], "[.,;)]+$")
      s <- str_remove(s,
        ",?\\s*\\.?\\s*Available\\s+at\\s+https?://[^\\s]+")
    }
  }
  
  s <- str_trim(s) |> str_remove("[.,]+$") |> str_trim()
  
  # Extract vol/issue/pages (anchor on ", v{num}")
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

# ── Step 3: Manual overrides for known bad rows ───────────────────────────
# These two DOIs are malformed in the source data
doi_corrections <- list(
  list(
    title_like = "%Annals of Actuarial Science%",
    doi_fixed  = "10.1017/S1748499517000264",
    flag       = "DOI corrected: trailing '2018' removed"
  ),
  list(
    title_like = "%Consumer Affairs%",
    doi_fixed  = "10.1111/j.1745-6606.2008.00105.x",
    flag       = "DOI corrected: '10.111' → '10.1111'; '1745-66-6' → '1745-6606'"
  )
)

# These rows need DOI lookup — no DOI was ever entered
doi_missing_flags <- list(
  list(title_like = "%Nordic Journal of Business%",
       flag = "DOI not in source data — look up at https://doi.org"),
  list(title_like = "%Interaction and Coordination%",
       flag = "DOI not in source data — look up at https://doi.org"),
  list(title_like = "%Financial Management%v33%",
       flag = "JSTOR link stored in link_url; DOI may exist — check Financial Management journal")
)

# ── Step 4: Parse all rows ────────────────────────────────────────────────
pubs <- dbReadTable(con, "publications")
cat("Parsing", nrow(pubs), "publications...\n\n")

results <- purrr::map_dfr(seq_len(nrow(pubs)), function(i) {
  parsed <- parse_journal_field(pubs$journal[i])
  tibble(
    row        = i,
    articleTitle = substr(pubs$articleTitle[i], 1, 55),
    year       = pubs$year[i],
    journal_name    = parsed$journal_name,
    vol_issue_pages = parsed$vol_issue_pages,
    doi             = parsed$doi,
    link_url        = parsed$link_url
  )
})

# Apply corrections
for (corr in doi_corrections) {
  idx <- which(str_detect(pubs$journal, str_remove_all(corr$title_like, "%")))
  if (length(idx) > 0) {
    results$doi[idx]      <- corr$doi_fixed
    results$doi_flag[idx] <- corr$flag
  }
}

# Apply missing-DOI flags
results$doi_flag <- NA_character_
for (miss in doi_missing_flags) {
  idx <- which(str_detect(pubs$journal, str_remove_all(miss$title_like, "%")))
  if (length(idx) > 0) results$doi_flag[idx] <- miss$flag
}

# Apply DOI-correction flags
for (corr in doi_corrections) {
  idx <- which(str_detect(pubs$journal, str_remove_all(corr$title_like, "%")))
  if (length(idx) > 0) results$doi_flag[idx] <- corr$flag
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

# ── Step 6: Verification report ───────────────────────────────────────────
cat("\n── Publication parsing results ──\n\n")
verification <- dbGetQuery(con, "
  SELECT year, journal_name,
         CASE WHEN doi IS NOT NULL AND doi != '' THEN 'YES' ELSE '---' END AS has_doi,
         CASE WHEN doi_flag IS NOT NULL THEN doi_flag ELSE '' END AS flag
  FROM publications
  ORDER BY CAST(year AS INTEGER) DESC
")
print(verification, row.names = FALSE)

n_doi    <- dbGetQuery(con, "SELECT COUNT(*) AS n FROM publications WHERE doi IS NOT NULL AND doi != ''")$n
n_no_doi <- nrow(pubs) - n_doi
n_flagged <- dbGetQuery(con, "SELECT COUNT(*) AS n FROM publications WHERE doi_flag IS NOT NULL")$n
cat(sprintf("\n  %d / %d publications have a clean DOI\n", n_doi, nrow(pubs)))
cat(sprintf("  %d rows flagged for review\n", n_flagged))

dbDisconnect(con)
cat("\n── Done ──\n")
cat("Next: run fetch_citations.R to populate the citations column via CrossRef API.\n")
