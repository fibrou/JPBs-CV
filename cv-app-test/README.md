# CV App — Test Prototype

Nothing in your original project is touched. This folder is self-contained.

## Files

| File | Purpose |
|---|---|
| `cv.db` | SQLite database (created by seed script) |
| `app.R` | Shiny web app — 27 tabs, one per CV section |
| `scripts/seed_db.R` | One-time script: sources `jpbsCVdata/jpbsCVdata.r` and writes all tables to `cv.db` |

## Quick start (in RStudio)

### Step 1 — Install dependencies (once)

```r
install.packages(c("shiny", "DBI", "RSQLite", "DT", "dplyr", "here", "tibble"))
```

### Step 2 — Seed the database (once)

Open `cv-app-test/scripts/seed_db.R` and click **Source**.  
This reads your real data from `jpbsCVdata/jpbsCVdata.r` and writes it all to `cv.db`.

### Step 3 — Launch the app

Open `cv-app-test/app.R` and click **Run App**.

## How the app works

- **Click a row** in any table to load it into the edit form below the table
- **Edit fields** and click **Save** to update the database
- **Click "Add New Row"** to open a blank form, fill it in, then Save
- **Click "Delete Selected"** (after clicking a row) to remove it — a confirmation dialog appears

## Sections covered (27 tabs)

Admin Roles · Long-Term Employment · Short-Term/Visiting · Education · Certifications ·
Honors & Grants · Publications · Papers in Progress · Other Pubs/Monos ·
Academic Presentations · Pedagogy Presentations · Academic Discussions ·
Conference Committees · Conference Chair · Editorial · Ad Hoc Review ·
T&P Reviews · Professional Offices · Academic Leadership · Academic Committees ·
Dissertation Committees · Theses Supervision · Student Mentoring ·
Professional Training · Media · Business Experience · References
