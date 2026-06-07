# JPBs-CV Website — Maintenance Guide

**Site URL:** https://fibrou.github.io/JPBs-CV/  
**Project folder:** `C:\Users\bfcgl\Dropbox\Vita\jpbQuartoWebStuff\JPBs-CV`  
**Data source:** `cv-app-test/cv.db` (SQLite — single source of truth for everything)

---

## Every Update: The Golden Rule

> Edit the **database** first. Then render. Then push. Never edit the HTML directly.

---

## Standard Update Workflow

- Open RStudio → **File → Recent Projects → JPBs-CV**
- Make your data changes (see sections below for specifics)
- **Pause Dropbox** (system tray → right-click → Pause syncing → 30 minutes)
- In the RStudio **Terminal**, run:
  ```bash
  quarto render
  git add docs/
  git commit -m "Brief description of what changed"
  git push
  ```
- **Resume Dropbox** when the push completes
- Wait 1–2 minutes, then check **https://fibrou.github.io/JPBs-CV/**

---

## Editing CV Content (Shiny App)

- In the RStudio **Console**, run:
  ```r
  shiny::runApp("app.R")
  ```
- Make your edits in the Shiny interface
- Close the Shiny app when done
- Follow the Standard Update Workflow above to push to the site

---

## Editing Publications Metadata (DOIs, Citations)

- In the RStudio **Console**, run:
  ```r
  shiny::runApp("publications_editor.R")
  ```
- Find the publication you want to update
- Edit the DOI, journal name, vol/issue/pages, or citation count
- Click **Save** on that card
- Close the app and follow the Standard Update Workflow

---

## Refreshing Citation Counts from CrossRef

- Do this a few times a year to keep counts current
- In the RStudio **Console**, run:
  ```r
  source("fetch_citations.R")
  ```
- Follow the Standard Update Workflow to push updated counts

---

## Updating Working Paper Abstracts

- Open `cv-app-test/cv.db` via the Shiny app, or run directly in the Console:
  ```r
  library(DBI); library(RSQLite); library(here)
  con <- dbConnect(RSQLite::SQLite(), here("cv-app-test", "cv.db"))
  dbExecute(con,
    "UPDATE papers_in_progress SET abstract = 'Your new abstract text here'
     WHERE articleTitle LIKE '%keyword from title%'")
  dbDisconnect(con)
  ```
- Follow the Standard Update Workflow

---

## Updating the Google Scholar Metrics on the About Page

- Scholar metrics are hardcoded in `index.qmd` (they don't change often)
- Open `index.qmd` in RStudio
- Find the "By the Numbers" section and update these four values:
  - Total citations (currently **1,109**)
  - Citations since 2021 (currently **267**)
  - h-index all-time (currently **15**)
  - h-index since 2021 (currently **7**)
- Also update the matching values in `research.qmd` in the Scholar metrics bar
- Follow the Standard Update Workflow

---

## Adding a New Publication

- Open the Shiny app (`shiny::runApp("app.R")`) and add via the publications tab, **or** run directly:
  ```r
  library(DBI); library(RSQLite); library(here)
  con <- dbConnect(RSQLite::SQLite(), here("cv-app-test", "cv.db"))
  dbExecute(con,
    "INSERT INTO publications (articleTitle, authors, journal, year)
     VALUES ('Title here', 'Author list', 'Journal name, vX nY, pp-pp', 2026)")
  dbDisconnect(con)
  ```
- Then run `publications_editor.R` to add the DOI for the new entry
- Follow the Standard Update Workflow

---

## Adding a New Working Paper

- In the RStudio Console:
  ```r
  library(DBI); library(RSQLite); library(here)
  con <- dbConnect(RSQLite::SQLite(), here("cv-app-test", "cv.db"))
  dbExecute(con,
    "INSERT INTO papers_in_progress (articleTitle, authors, status, abstract)
     VALUES ('Paper title', 'with Co-Author Name', 'In Progress',
             'Abstract text here')")
  dbDisconnect(con)
  ```
- Follow the Standard Update Workflow

---

## Troubleshooting

**Render fails with "file in use" error**
- Pause Dropbox before rendering
- Close any open browser tabs showing the local preview
- Stop `quarto preview` with Ctrl+C before running `quarto render`

**Page looks the same after pushing**
- GitHub Pages can take 1–3 minutes to update — wait and hard-refresh (Ctrl+Shift+R)

**R session crashes during render**
- Restart R: **Session → Restart R**
- Re-run `quarto render` — the database is safe, nothing is lost

**git push asks for authentication**
- A browser window will open — sign in to GitHub and it will complete automatically

---

## Files You Should Know

| File | Purpose |
|------|---------|
| `index.qmd` | About / landing page |
| `research.qmd` | Publications page with timeline chart |
| `papers.qmd` | Working papers with abstracts |
| `cv.qmd` | CV page with embedded PDF viewer |
| `custom-cv.scss` | All colors, fonts, and styling |
| `_quarto.yml` | Site navigation and configuration |
| `app.R` | Shiny CV editor |
| `publications_editor.R` | Standalone DOI / metadata editor |
| `fetch_citations.R` | Refreshes CrossRef citation counts |
| `cv-app-test/cv.db` | The database — **back this up regularly** |
| `jpbDataDrivenCV.pdf` | The PDF CV linked from the website |

---

## Backing Up the Database

- Copy `cv-app-test/cv.db` to a safe location periodically
- Dropbox syncing provides one layer of backup automatically
- For extra safety, keep a dated copy:
  ```r
  file.copy("cv-app-test/cv.db",
            paste0("cv-app-test/cv_backup_", Sys.Date(), ".db"))
  ```

---

*Last updated: June 2026*
