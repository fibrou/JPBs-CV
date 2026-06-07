# ── migrate_add_abstracts.R ────────────────────────────────────────────────
# Run ONCE from RStudio console before first website render.
# Adds the `abstract` column to papers_in_progress and populates
# all 5 working papers with the approved draft abstracts.
#
# Safe to re-run: skips ALTER TABLE if column already exists,
# and REPLACE matches on LIKE so it's idempotent.
#
# After running: quarto render → papers.qmd will show full abstracts.
# ─────────────────────────────────────────────────────────────────────────

library(DBI)
library(RSQLite)
library(here)

db_path <- here("cv-app-test", "cv.db")
con <- dbConnect(RSQLite::SQLite(), db_path)
cat("Connected to:", db_path, "\n\n")

# ── Step 1: Add abstract column ──────────────────────────────────────────
existing_cols <- dbListFields(con, "papers_in_progress")

if (!"abstract" %in% existing_cols) {
  dbExecute(con, "ALTER TABLE papers_in_progress ADD COLUMN abstract TEXT")
  cat("✓ Added 'abstract' column to papers_in_progress\n\n")
} else {
  cat("✓ 'abstract' column already exists — skipping ALTER TABLE\n\n")
}

# ── Step 2: Current state ────────────────────────────────────────────────
cat("Papers currently in db:\n")
current <- dbReadTable(con, "papers_in_progress")
print(current[, intersect(c("articleTitle", "authors", "status"), names(current))])
cat("\n")

# ── Step 3: Draft abstracts ──────────────────────────────────────────────
# Edit these texts before running if needed — they load from the
# draft file you reviewed. LIKE matches are case-insensitive in SQLite.

abstracts <- list(

  list(
    pattern  = "%Multimodal%Central Bank%",
    abstract = paste0(
      "Central bank communication has become a primary instrument of monetary ",
      "policy, yet existing research analyzes speech transcripts in isolation, ",
      "discarding the rich informational content embedded in vocal delivery, ",
      "facial expression, and non-verbal cues. This paper introduces a multimodal ",
      "analytical framework that combines natural language processing, audio feature ",
      "extraction, and computer vision to construct a comprehensive signal from ",
      "central banker press conferences and public addresses. Applying large language ",
      "models to Federal Reserve and European Central Bank communications alongside ",
      "acoustic and visual sentiment indicators, we find that multimodal signals ",
      "exhibit significantly greater predictive power for short-term interest rate ",
      "expectations and equity market volatility than text-only approaches. Our ",
      "results suggest that financial markets partially price non-verbal information ",
      "embedded in central bank communications, with important implications for the ",
      "conduct and transparency of monetary policy."
    )
  ),

  list(
    pattern  = "%Vines%Dr. Copper%",
    abstract = paste0(
      "Copper prices have long served as a leading macroeconomic indicator — a role ",
      "so reliable that market practitioners have nicknamed the metal 'Dr. Copper.' ",
      "Yet the dependence structure between copper and other financial and commodity ",
      "markets is complex, asymmetric, and regime-dependent in ways that standard ",
      "linear correlation models cannot capture. This paper employs vine copula ",
      "methodology — specifically D-vine and R-vine structures — to model the joint ",
      "dependence of copper with equity indices, energy markets, and key industrial ",
      "commodities across distinct economic regimes. We document significant tail ",
      "dependence between copper and global growth proxies during contractionary ",
      "periods that is absent during expansions, consistent with copper's asymmetric ",
      "signaling role. Our findings have direct implications for commodity portfolio ",
      "construction, macroeconomic nowcasting, and cross-asset risk management strategies."
    )
  ),

  list(
    pattern  = "%Vines%Endowment%",
    abstract = paste0(
      "University endowments occupy a unique position in institutional portfolio ",
      "management: perpetual investment horizons, illiquidity tolerance, and ",
      "significant allocations to alternative assets create dependence structures ",
      "that traditional mean-variance optimization fundamentally misrepresents. ",
      "This paper applies vine copula models — D-vine and R-vine structures — to ",
      "the multi-asset allocation problem faced by large endowments, capturing ",
      "asymmetric tail dependencies between public equities, private equity, real ",
      "assets, hedge funds, and fixed income. Using a sample of major U.S. and ",
      "Nordic university endowments, we demonstrate that vine-based portfolio ",
      "construction produces superior out-of-sample drawdown characteristics relative ",
      "to both classical and DCC-GARCH benchmarks, without sacrificing long-run ",
      "return expectations. Our results provide endowment investment committees with ",
      "a tractable framework for stress-testing tail scenarios that standard risk ",
      "models systematically underweight."
    )
  ),

  list(
    pattern  = "%FinFluencer%",
    abstract = paste0(
      "The emergence of financial influencers — 'FinFluencers' — on platforms ",
      "including YouTube, TikTok, and X (formerly Twitter) has democratized access ",
      "to investment commentary while raising questions about market integrity, ",
      "retail investor behavior, and the propagation of financial misinformation. ",
      "This paper constructs a longitudinal panel of FinFluencer activity across ",
      "major platforms, employing network analysis and large language model-based ",
      "sentiment extraction to measure how content cascades through follower networks ",
      "and into observable trading patterns. We document significant network ",
      "amplification effects, wherein a small number of high-centrality FinFluencers ",
      "disproportionately drive retail order flow in small- and mid-cap equities. ",
      "Event-study analysis around viral posts reveals abnormal returns and volume ",
      "spikes consistent with coordinated, if unintentional, price pressure. Our ",
      "findings carry implications for securities regulation, platform governance, ",
      "and the design of retail investor protection frameworks."
    )
  ),

  list(
    pattern  = "%Earnings Management%Alternative Earnings%",
    abstract = paste0(
      "The widespread adoption of non-GAAP and alternative earnings disclosures by ",
      "public firms has fundamentally altered the information environment surrounding ",
      "corporate financial reporting. This paper examines whether the availability of ",
      "alternative earnings measures — including adjusted EBITDA, pro forma earnings, ",
      "and segment-level metrics — serves as a complement to or a substitute for ",
      "traditional accrual-based earnings management. Using a large international ",
      "panel of publicly listed firms, we find that firms with larger gaps between ",
      "reported and alternative earnings engage in significantly less accruals ",
      "manipulation, consistent with alternative disclosures reducing the incentive ",
      "to manage GAAP figures. However, this effect is concentrated in ",
      "high-analyst-coverage environments; firms with limited external scrutiny use ",
      "alternative earnings disclosures opportunistically, as a screen behind which ",
      "accrual management persists. Our evidence contributes to the growing literature ",
      "on the real effects of voluntary disclosure and has implications for ",
      "standard-setters considering mandatory non-GAAP disclosure rules."
    )
  )

)

# ── Step 4: Update each paper ────────────────────────────────────────────
cat("Updating abstracts...\n")
for (wp in abstracts) {
  rows_updated <- dbExecute(
    con,
    "UPDATE papers_in_progress SET abstract = ? WHERE articleTitle LIKE ?",
    params = list(wp$abstract, wp$pattern)
  )
  cat(sprintf("  %-45s → %d row(s) updated\n",
              substr(wp$pattern, 1, 45), rows_updated))
}

# ── Step 5: Verify ───────────────────────────────────────────────────────
cat("\nVerification:\n")
final <- dbReadTable(con, "papers_in_progress")
for (i in seq_len(nrow(final))) {
  has_abstract <- "abstract" %in% names(final) &&
                  !is.na(final$abstract[i])    &&
                  nchar(final$abstract[i]) > 10
  cat(sprintf("  [%s] %s\n",
              if (has_abstract) "✓ OK " else "✗ MISSING",
              substr(final$articleTitle[i], 1, 55)))
}

dbDisconnect(con)
cat("\n── Done ──\n")
cat("Next step: quarto render\n")
cat("Then:      git add docs/ && git commit -m 'Site render' && git push\n")
