# ── fetch_citations.R ─────────────────────────────────────────────────────
# Queries the CrossRef API for citation counts for every publication
# that has a DOI, writes results to publications.citations in cv.db.
#
# Run after migrate_publications_structured.R.
# Safe to re-run: overwrites existing counts with fresh data.
# Rate limit: CrossRef politely requests < 50 req/sec — this script
# stays well under that with Sys.sleep(0.2) between requests.
#
# CrossRef citation counts are "cited-by" counts from CrossRef member
# publishers — lower than Google Scholar but permanent and API-accessible.
# For full Google Scholar h-index/citations, see the note at the bottom.
# ─────────────────────────────────────────────────────────────────────────

library(DBI)
library(RSQLite)
library(httr2)
library(dplyr)
library(here)

db_path <- here("cv-app-test", "cv.db")
con     <- dbConnect(RSQLite::SQLite(), db_path)

pubs <- dbGetQuery(con,
  "SELECT articleTitle, doi, citations FROM publications
   WHERE doi IS NOT NULL AND doi != '' AND doi_flag IS NULL
   ORDER BY CAST(year AS INTEGER) DESC")

cat(sprintf("Fetching citation counts for %d publications with clean DOIs...\n\n",
            nrow(pubs)))

# CrossRef polite pool — add your email for faster responses
POLITE_EMAIL <- "john.broussard@rutgers.edu"

fetch_crossref_citations <- function(doi, email = POLITE_EMAIL) {
  tryCatch({
    resp <- request(paste0("https://api.crossref.org/works/", doi)) |>
      req_url_query(`mailto` = email) |>
      req_timeout(10) |>
      req_perform()
    
    data <- resp |> resp_body_json()
    
    # CrossRef returns "is-referenced-by-count"
    cites <- data$message$`is-referenced-by-count`
    if (!is.null(cites)) as.integer(cites) else NA_integer_
    
  }, error = function(e) {
    message("  Error fetching ", doi, ": ", conditionMessage(e))
    NA_integer_
  })
}

# ── Fetch ─────────────────────────────────────────────────────────────────
results <- vector("integer", nrow(pubs))

for (i in seq_len(nrow(pubs))) {
  doi    <- pubs$doi[i]
  title  <- substr(pubs$articleTitle[i], 1, 55)
  
  cites  <- fetch_crossref_citations(doi)
  results[i] <- ifelse(is.na(cites), -1L, cites)
  
  cat(sprintf("  [%2d] %-55s → %s citations\n",
              i, title,
              if (is.na(cites)) "API error" else as.character(cites)))
  
  Sys.sleep(0.2)  # polite rate limiting
}

# ── Write back ────────────────────────────────────────────────────────────
cat("\nWriting to database...\n")
for (i in seq_len(nrow(pubs))) {
  if (results[i] >= 0) {
    dbExecute(con,
      "UPDATE publications SET citations = ? WHERE articleTitle = ?",
      params = list(results[i], pubs$articleTitle[i]))
  }
}

# ── Summary ───────────────────────────────────────────────────────────────
summary_q <- dbGetQuery(con, "
  SELECT year, journal_name,
         COALESCE(CAST(citations AS TEXT), 'pending') AS citations
  FROM publications
  WHERE doi IS NOT NULL AND doi != ''
  ORDER BY CAST(year AS INTEGER) DESC")
cat("\n── Citation counts written ──\n")
print(summary_q, row.names = FALSE)

total <- sum(results[results >= 0])
cat(sprintf("\n  Total CrossRef citations across %d papers: %d\n",
            sum(results >= 0), total))
cat("  Note: CrossRef undercounts vs. Google Scholar (member publishers only).\n")

dbDisconnect(con)
cat("\n── Done ──\n\n")
cat("═══ To add Google Scholar total citations + h-index ════════════════════\n")
cat("1. Go to: https://scholar.google.com\n")
cat("2. Search your name, click your profile\n")
cat("3. Your Scholar profile URL contains your ID:\n")
cat("   scholar.google.com/citations?user=XXXXXXXXXX  ← that's your ID\n")
cat("4. Share that ID with Claude to:\n")
cat("   a) Display live citation totals on your About page\n")
cat("   b) Link directly to your Scholar profile\n")
cat("   c) Optionally: embed citation sparkline via the Scholar API\n")
