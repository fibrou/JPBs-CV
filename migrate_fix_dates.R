# ── migrate_fix_dates.R ────────────────────────────────────────────────────
# Fixes all date-handling inconsistencies identified in the schema audit.
# Run ONCE from RStudio console, from the project root.
# Safe to re-run: all operations are idempotent.
#
# Issues addressed:
#   1. publications.year       → character → integer
#   2. academic_leadership     → begYear/endYear character → integer
#   3. academic_committees     → begYear/endYear character → integer
#   4. dissertation_committees → "Current" → "Present" (vocabulary fix)
#   5. papers_in_progress      → adds year column (optional, NULL by default)
# ─────────────────────────────────────────────────────────────────────────

library(DBI)
library(RSQLite)
library(dplyr)
library(here)

db_path <- here("cv-app-test", "cv.db")
con <- dbConnect(RSQLite::SQLite(), db_path)
cat("Connected to:", db_path, "\n\n")

# Helper: show before/after for a table's date columns
show_sample <- function(tbl, cols) {
  q <- sprintf('SELECT %s FROM "%s" LIMIT 3', paste(cols, collapse=", "), tbl)
  print(dbGetQuery(con, q))
}

# ── Fix 1: publications.year → integer ────────────────────────────────────
cat("── Fix 1: publications.year (character → integer) ──\n")
cat("Before:\n"); show_sample("publications", "year")

# SQLite doesn't support ALTER COLUMN TYPE — rebuild the column via UPDATE
# Since SQLite stores integers as integers regardless of declared type,
# we just need to ensure the values are numeric (UPDATE forces type coercion)
dbExecute(con, "UPDATE publications SET year = CAST(year AS INTEGER) WHERE year IS NOT NULL")

cat("After:\n"); show_sample("publications", "year")
cat("✓ Done\n\n")


# ── Fix 2: academic_leadership.begYear/endYear → integer ──────────────────
cat("── Fix 2: academic_leadership (character → integer) ──\n")
cat("Before:\n"); show_sample("academic_leadership", "begYear, endYear")

dbExecute(con, "UPDATE academic_leadership SET begYear = CAST(begYear AS INTEGER) WHERE begYear IS NOT NULL")
dbExecute(con, "UPDATE academic_leadership SET endYear = CAST(endYear AS INTEGER) WHERE endYear IS NOT NULL")

cat("After:\n"); show_sample("academic_leadership", "begYear, endYear")
cat("✓ Done\n\n")


# ── Fix 3: academic_committees.begYear/endYear → integer ──────────────────
cat("── Fix 3: academic_committees (character → integer) ──\n")
cat("Before:\n"); show_sample("academic_committees", "begYear, endYear")

dbExecute(con, "UPDATE academic_committees SET begYear = CAST(begYear AS INTEGER) WHERE begYear IS NOT NULL")
dbExecute(con, "UPDATE academic_committees SET endYear = CAST(endYear AS INTEGER) WHERE endYear IS NOT NULL")

cat("After:\n"); show_sample("academic_committees", "begYear, endYear")
cat("✓ Done\n\n")


# ── Fix 4: dissertation_committees — "Current" → "Present" ────────────────
cat("── Fix 4: dissertation_committees — standardize 'Current' → 'Present' ──\n")
affected <- dbGetQuery(con,
  "SELECT student, year FROM dissertation_committees WHERE year = 'Current'")
cat("Rows affected:\n"); print(affected)

dbExecute(con,
  "UPDATE dissertation_committees SET year = 'Present' WHERE year = 'Current'")
cat("✓ Done\n\n")


# ── Fix 5: papers_in_progress — add year column (optional) ────────────────
cat("── Fix 5: papers_in_progress — add year column ──\n")
pip_cols <- dbListFields(con, "papers_in_progress")

if (!"year" %in% pip_cols) {
  dbExecute(con, "ALTER TABLE papers_in_progress ADD COLUMN year INTEGER")
  cat("✓ Added 'year' column (NULL for all rows — populate manually)\n\n")
  cat("To set a year for a paper, run:\n")
  cat("  dbExecute(con, \"UPDATE papers_in_progress SET year = 2025 WHERE articleTitle LIKE '%Multimodal%'\")\n\n")
} else {
  cat("✓ 'year' column already exists\n\n")
}


# ── Note on biz_experiences and student_mentoring ─────────────────────────
cat("── Note: biz_experiences + student_mentoring ──\n")
cat("These tables store years as CHARACTER with 'Present' as a string value.\n")
cat("This is a structural pattern (not a bug) — handled in R at render time.\n")
cat("No db change needed. The website's load_cv_data_db.R handles these correctly.\n\n")


# ── Verification ──────────────────────────────────────────────────────────
cat("── Final verification ──\n")

pubs_year_type <- dbGetQuery(con,
  "SELECT typeof(year) AS type, COUNT(*) AS n FROM publications GROUP BY typeof(year)")
cat("publications.year types:\n"); print(pubs_year_type)

al_types <- dbGetQuery(con,
  "SELECT typeof(begYear) AS beg_type, typeof(endYear) AS end_type,
          COUNT(*) AS n FROM academic_leadership GROUP BY 1,2")
cat("academic_leadership year types:\n"); print(al_types)

pip_check <- dbGetQuery(con,
  "SELECT articleTitle, year FROM papers_in_progress")
cat("papers_in_progress (with year column):\n"); print(pip_check)

dbDisconnect(con)
cat("\n── Done ──\n")
cat("Run quarto render after this to pick up the type fixes.\n")
