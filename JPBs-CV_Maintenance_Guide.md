# JPBs-CV: Maintenance Guide

Site: https://fibrou.github.io/JPBs-CV/
Project folder: `~/jpbs-filing-cabinet/00-personal/vita/JPBs-CV`
Data: `cv-app-test/cv.db`, a SQLite database that holds every entry on the CV

## How it fits together

Everything on the CV lives in one database, `cv.db`. You change the content
through the Shiny editor, never by editing HTML or the PDF. Both outputs are
built from that database: the PDF CV (`jpbDataDrivenCV.Rmd` produces
`jpbDataDrivenCV.pdf`) and the four website pages (`index.qmd`,
`research.qmd`, `papers.qmd`, `cv.qmd`). Because both read the same data,
the PDF and the website always agree.

Publishing is one command, `./publish.sh`. It rebuilds the PDF and the site,
saves your changes to GitHub, and puts the new site live.

## The routine

1. Edit the content (see below for which tool to use).
2. In a terminal, from the project folder:

   ```bash
   ./publish.sh "Short note on what changed"
   ```

3. Give GitHub a minute or two, then reload the site.

To check the result before anything goes live, run `./publish.sh --local`
and then `quarto preview`. That rebuilds everything on your machine without
committing or pushing.

## Editing the CV content

Start the editor from R (in RStudio's Console, or with `R` in a terminal
from the project folder):

```r
shiny::runApp("app.R")
```

It has one tab per CV section. Its Render button builds the PDF on the spot
if you want to look at it straight away, but `./publish.sh` builds it again
anyway, so you can skip that.

For publication details (DOI, journal, volume, issue, pages, citation
count) use the separate editor:

```r
shiny::runApp("publications_editor.R")
```

New publications and working papers can be added in the main editor. Small
fixes such as rewriting one abstract can also be made directly:

```r
library(DBI); library(RSQLite); library(here)
con <- dbConnect(SQLite(), here("cv-app-test", "cv.db"))
dbExecute(con, "UPDATE papers_in_progress SET abstract = 'New text'
                WHERE articleTitle LIKE '%a word from the title%'")
dbDisconnect(con)
```

## Citation counts

CrossRef citation counts are stored in the database and refreshed by a
script. Running `./publish.sh --citations` refreshes them and then publishes.
Doing this a few times a year is enough.

Google Scholar numbers (total citations, h-index, i10-index) cannot be
fetched automatically because Scholar has no public API. They live in one
small file, `scholar_metrics.yml`. Copy the current figures from your Scholar
profile into it and publish; the About and Research pages both read it.

## When something goes wrong

**The PDF fails to build with a missing `.sty` file.** A LaTeX package is
missing. The template needs `sourcesans`, which this laptop's 2023 TeX Live
lacked; it was added to `~/texmf` in November 2026. On a new machine, the
quickest fix is installing TinyTeX in R (`tinytex::install_tinytex()`),
which fetches missing packages on its own.

**Git says `index.lock` exists.** Nextcloud syncs this folder, including
git's internal files, and once kept bringing back an old lock file.
`publish.sh` clears a stale lock automatically. By hand:
`rm .git/index.lock`, but only when no git command is running.

**Files you deleted or moved come back.** In November 2026 the Nextcloud
server had a stale permission record for this folder that refused every
removal. A server rescan of `00-personal/vita` fixed it. If it happens again,
the same rescan should fix it (`occ files:scan --path=fibrou/files/<folder>`
on the server).

Old CV material is kept in `../../vita-archive/`, outside this folder.

**Two machines.** The laptop and the desktop both sync this folder. Commit
and publish from one machine at a time, and let Nextcloud finish syncing
before switching.

**The site looks unchanged after publishing.** GitHub Pages can take a few
minutes. Hard-refresh the page (Ctrl+Shift+R).

## Files

| File | What it is |
|------|-----------|
| `cv-app-test/cv.db` | The database. Everything comes from here. |
| `app.R` | The Shiny CV editor |
| `publications_editor.R` | Editor for DOIs and publication details |
| `fetch_citations.R` | Refreshes CrossRef citation counts |
| `scholar_metrics.yml` | Google Scholar numbers, updated by hand |
| `publish.sh` | Rebuilds the PDF and site and publishes them |
| `jpbDataDrivenCV.Rmd` | The PDF CV's layout (vitae, awesome-cv style) |
| `awesome-cv.cls`, `fonts/` | LaTeX template and fonts for the PDF |
| `cv-app-test/scripts/data_from_db.R` | Loads the database for the PDF |
| `index.qmd`, `research.qmd`, `papers.qmd`, `cv.qmd` | The four website pages |
| `_quarto.yml`, `custom-cv.scss` | Site navigation, colours and fonts |
| `_site/` | The built website. Generated; never edit it. |

The built site is published to the `gh-pages` branch of the GitHub
repository, which is what GitHub Pages serves. The `main` branch holds only
the source, the database and the PDF. Git history keeps every earlier
version of the database, so committing through `publish.sh` doubles as a
backup.

*Last updated: November 2026*
