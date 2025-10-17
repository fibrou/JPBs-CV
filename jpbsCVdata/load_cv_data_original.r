# =============================================================================
# CV Data Loading Functions
# This script loads your CV data from Excel into R
# =============================================================================

library(readxl)
library(dplyr)
library(glue)
library(lubridate)
library(here)

# =============================================================================
# Main Loading Function
# =============================================================================

load_cv_data <- function(filename = "cv_data.xlsx") {
  
  filepath <- here("jpbsCVdata", filename)
  
  if (!file.exists(filepath)) {
    stop(glue("File not found: {filepath}\nPlease ensure cv_data.xlsx exists in jpbsCVdata/"))
  }
  
  message("Loading CV data from: ", filename)
  
  # Read metadata
  metadata <- read_excel(filepath, sheet = "Metadata") %>%
    select(setting, value) %>%
    tibble::deframe()  # Convert to named vector
  
  # Read main data sheets
  admin <- read_excel(filepath, sheet = "Administrative") %>%
    arrange(display_order)
  
  publications <- read_excel(filepath, sheet = "Publications") %>%
    arrange(desc(year), id)
  
  pip <- read_excel(filepath, sheet = "WorkingPapers") %>%
    arrange(display_order)
  
  employment <- read_excel(filepath, sheet = "Employment") %>%
    arrange(display_order)
  
  honors <- read_excel(filepath, sheet = "Honors") %>%
    arrange(desc(year), display_order)
  
  certifications <- read_excel(filepath, sheet = "Certifications") %>%
    arrange(desc(year))
  
  other_pubs <- read_excel(filepath, sheet = "OtherPublications") %>%
    arrange(desc(year))
  
  presentations <- read_excel(filepath, sheet = "Presentations") %>%
    arrange(desc(date))
  
  service <- read_excel(filepath, sheet = "Service") %>%
    arrange(desc(start_date))
  
  media <- read_excel(filepath, sheet = "Media") %>%
    arrange(desc(year))
  
  mentoring <- read_excel(filepath, sheet = "Mentoring") %>%
    arrange(desc(start_date))
  
  dissertations <- read_excel(filepath, sheet = "Dissertations") %>%
    arrange(desc(year))
  
  references <- read_excel(filepath, sheet = "References")
  
  # Create list for easy access
  cv_data <- list(
    metadata = metadata,
    admin = admin,
    publications = publications,
    pip = pip,
    employment = employment,
    honors = honors,
    certifications = certifications,
    other_pubs = other_pubs,
    presentations = presentations,
    service = service,
    media = media,
    mentoring = mentoring,
    dissertations = dissertations,
    references = references
  )
  
  # Also create individual objects in global environment for easy access
  list2env(cv_data, envir = .GlobalEnv)
  
  message("✓ Loaded CV data successfully!")
  message("  - ", nrow(admin), " administrative items")
  message("  - ", nrow(publications), " publications")
  message("  - ", nrow(pip), " working papers")
  message("  - ", nrow(employment), " employment records")
  message("  - ", nrow(honors), " honors/grants")
  message("  - ", nrow(service), " service activities")
  message("  - ", nrow(references), " references")
  
  invisible(cv_data)
}

# =============================================================================
# Helper Functions
# =============================================================================

# Format date ranges nicely
format_date_range <- function(start_date, end_date) {
  
  # Handle NA or empty values
  if (is.na(start_date) || start_date == "") {
    return("")
  }
  
  # Parse start date
  start <- ymd(start_date, truncated = 1)
  start_str <- format(start, "%B %Y")
  
  # Handle end date
  if (is.na(end_date) || end_date == "" || tolower(end_date) == "present") {
    end_str <- "Present"
  } else {
    end <- ymd(end_date, truncated = 1)
    end_str <- format(end, "%B %Y")
  }
  
  glue("{start_str} → {end_str}")
}

# Get recent publications
get_recent_pubs <- function(publications, since_year = 2013) {
  publications %>%
    filter(year >= since_year) %>%
    arrange(desc(year), id)
}

# Get highlighted items
get_highlights <- function(data, n = 5) {
  if ("highlight" %in% names(data)) {
    data %>%
      filter(highlight == TRUE) %>%
      slice_head(n = n)
  } else if ("featured" %in% names(data)) {
    data %>%
      filter(featured == TRUE) %>%
      slice_head(n = n)
  } else {
    data %>%
      slice_head(n = n)
  }
}

# Validation function
validate_cv_data <- function() {
  
  message("Validating CV data...")
  issues <- list()
  
  # Check for missing DOIs in recent publications
  if (exists("publications")) {
    missing_dois <- publications %>%
      filter(year >= 2020, is.na(doi) | doi == "") %>%
      select(title, year)
    
    if (nrow(missing_dois) > 0) {
      issues$missing_dois <- missing_dois
      message("⚠ ", nrow(missing_dois), " recent publications missing DOIs")
    }
  }
  
  # Check for working papers without expected completion
  if (exists("pip")) {
    missing_dates <- pip %>%
      filter(is.na(expected_completion) | expected_completion == "") %>%
      select(title, status)
    
    if (nrow(missing_dates) > 0) {
      issues$missing_dates <- missing_dates
      message("⚠ ", nrow(missing_dates), " working papers missing expected completion dates")
    }
  }
  
  # Check for admin items without metrics
  if (exists("admin")) {
    missing_metrics <- admin %>%
      filter(is.na(metric_value)) %>%
      select(institution, title)
    
    if (nrow(missing_metrics) > 0) {
      message("ℹ ", nrow(missing_metrics), " admin items could use quantified metrics")
    }
  }
  
  if (length(issues) == 0) {
    message("✓ All validation checks passed!")
  } else {
    message("\n⚠ Found some items to enhance (optional):")
    message("  - Add DOIs to recent publications")
    message("  - Add expected completion dates to working papers")
    message("  - Add metrics to administrative achievements")
  }
  
  invisible(issues)
}

# =============================================================================
# Usage Examples
# =============================================================================

# Load data:
# source("jpbsCVdata/load_cv_data.r")
# load_cv_data()

# Format dates:
# format_date_range("2021-01", "2024-07")
# format_date_range("2021-01", NA)

# Get recent publications:
# recent <- get_recent_pubs(publications, since_year = 2013)

# Get highlights:
# top_admin <- get_highlights(admin, n = 5)

# Validate:
# validate_cv_data()