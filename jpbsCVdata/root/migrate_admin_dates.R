# ── migrate_admin_dates.R ──────────────────────────────────────────────────
# Adds begYear (INT) and endYear (INT) to the admin table.
# Populates from known institutional periods cross-referenced
# against lt_work and academic_leadership.
#
# NULL endYear = ongoing (no end date yet confirmed).
# ─────────────────────────────────────────────────────────────────────────

library(DBI)
library(RSQLite)
library(here)

db_path <- here("cv-app-test", "cv.db")
con     <- dbConnect(RSQLite::SQLite(), db_path)
cat("Connected:", db_path, "\n\n")

# ── Step 1: Add columns ───────────────────────────────────────────────────
cols <- dbListFields(con, "admin")

for (col in c("begYear", "endYear")) {
  if (!col %in% cols) {
    dbExecute(con, sprintf("ALTER TABLE admin ADD COLUMN %s INTEGER", col))
    cat(sprintf("✓ Added '%s' to admin\n", col))
  } else {
    cat(sprintf("✓ '%s' already exists\n", col))
  }
}
cat("\n")

# ── Step 2: Populate dates by institution + title ─────────────────────────
updates <- list(

  # ── University of Oklahoma ─────────────────────────────────────────────
  list(
    inst  = "University of Oklahoma",
    title = "Director of Online MS Finance Program",
    beg   = 2021L, end = 2024L,
    note  = "Confirmed: lt_work Jan 2021 – Jul 2024"
  ),
  list(
    inst  = "University of Oklahoma",
    title = "Assistant Director of Finance Division",
    beg   = 2021L, end = 2024L,
    note  = "Confirmed: lt_work Jan 2021 – Jul 2024"
  ),
  list(
    inst  = "University of Oklahoma",
    title = "Co-Program Director for Global Business Experience in Arezzo Italy",
    beg   = 2022L, end = 2024L,
    note  = "Confirmed: summers 2022, 2023, 2024 during OU tenure"
  ),

  # ── Estonian Business School ───────────────────────────────────────────
  list(
    inst  = "Estonian Business School",
    title = "Finance Area Head",
    beg   = 2019L, end = 2020L,
    note  = "Confirmed: academic_leadership 2019–2020"
  ),

  # ── Rutgers University ─────────────────────────────────────────────────
  # "Multi-Year" consolidates: Coordinator 2003–05, 2007–08, 2010–11;
  #   Head, Accounting & Finance Area 2013–14.  Full span stored.
  list(
    inst  = "Rutgers University",
    title = "Multi-Year Finance Area Head",
    beg   = 2003L, end = 2014L,
    note  = "Multi-period: 2003–05, 2007–08, 2010–11, 2013–14. Full span stored."
  )

)

cat("Applying date updates...\n")
for (u in updates) {
  n <- dbExecute(con,
    "UPDATE admin SET begYear = ?, endYear = ? WHERE institution = ? AND title = ?",
    params = list(u$beg, u$end, u$inst, u$title)
  )
  cat(sprintf("  ✓  %-50s  %d–%d  (%d rows)\n",
              paste0(u$inst, " / ", substr(u$title, 1, 30)),
              u$beg, u$end, n))
}
cat("\n")

# ── Step 3: Verify ────────────────────────────────────────────────────────
cat("Verification — unique role/date combinations in admin:\n")
summary <- dbGetQuery(con, "
  SELECT institution, title, begYear, endYear, COUNT(*) AS bullet_rows
  FROM admin
  GROUP BY institution, title, begYear, endYear
  ORDER BY begYear DESC
")
print(summary)

undated <- dbGetQuery(con,
  "SELECT institution, title FROM admin WHERE begYear IS NULL")
if (nrow(undated) > 0) {
  cat("\n⚠ Rows with no dates (add manually if needed):\n")
  print(undated)
}

dbDisconnect(con)
cat("\n── Done ──\n")
