# =============================================================================
# Automatic Conversion: jpbsCVdata.r → cv_data.xlsx
# This script converts your existing tribble data to Excel format
# =============================================================================

library(tidyverse)
library(writexl)
library(here)
library(glue)

message("=======================================================")
message("CONVERTING YOUR EXISTING CV DATA TO EXCEL")
message("=======================================================\n")

# =============================================================================
# STEP 1: Load Your Existing Data
# =============================================================================

message("Step 1: Loading your existing CV data...")

# Source your original data file
source(here("jpbsCVdata", "jpbsCVdata.r"))

message("✓ Loaded existing data structures\n")

# =============================================================================
# STEP 2: Convert Administrative Data
# =============================================================================

message("Step 2: Converting administrative achievements...")

admin_excel <- admin %>%
  mutate(
    # Add new columns for Excel structure
    start_date = NA_character_,
    end_date = NA_character_,
    metric_value = NA_real_,
    metric_label = NA_character_,
    impact = NA_character_,
    display_order = row_number(),
    category = "General",
    highlight = TRUE,  # Mark all as highlight by default
    notes = ""
  ) %>%
  select(institution, title, detail, start_date, end_date, 
         metric_value, metric_label, impact, display_order, 
         category, highlight, notes)

message(glue("  ✓ Converted {nrow(admin_excel)} administrative items\n"))

# =============================================================================
# STEP 3: Convert Publications
# =============================================================================

message("Step 3: Converting publications...")

publications_excel <- publications %>%
  mutate(
    id = row_number(),
    # Parse journal info if available
    volume = NA_real_,
    issue = NA_real_,
    pages = NA_character_,
    # Extract DOI if in journal field
    doi = if_else(
      str_detect(journal, "doi.org|dx.doi"),
      str_extract(journal, "https?://[^ ]+"),
      NA_character_
    ),
    # Clean journal name (remove DOI if present)
    journal_clean = str_remove(journal, "Available at.*$") %>%
      str_remove("https?://.*$") %>%
      str_trim(),
    abstract = NA_character_,
    keywords = NA_character_,
    citation_count = 0,
    featured = FALSE,  # You can mark featured ones later
    notes = ""
  ) %>%
  select(id, 
         title = articleTitle, 
         authors, 
         journal = journal_clean, 
         year, 
         volume, 
         issue, 
         pages, 
         doi, 
         abstract, 
         keywords, 
         citation_count, 
         featured, 
         notes)

message(glue("  ✓ Converted {nrow(publications_excel)} publications\n"))

# =============================================================================
# STEP 4: Convert Working Papers
# =============================================================================

message("Step 4: Converting working papers...")

working_papers_excel <- pip %>%
  mutate(
    id = row_number(),
    title = articleTitle,
    target_journal = NA_character_,
    expected_completion = NA_character_,
    abstract = NA_character_,
    keywords = NA_character_,
    conferences_presented = NA_character_,
    display_order = row_number(),
    show_on_website = TRUE,
    notes = ""
  ) %>%
  select(id, title, authors, status, target_journal, 
         expected_completion, abstract, keywords, 
         conferences_presented, display_order, 
         show_on_website, notes)

message(glue("  ✓ Converted {nrow(working_papers_excel)} working papers\n"))

# =============================================================================
# STEP 5: Convert Employment History
# =============================================================================

message("Step 5: Converting employment history...")

employment_excel <- ltWork %>%
  mutate(
    position_title = NA_character_,  # Will need manual entry
    start_date = glue("{startMonth}-{startYear}"),
    end_date = if_else(
      is.na(endMonth) | is.na(endYear),
      NA_character_,
      glue("{endMonth}-{endYear}")
    ),
    location_city = word(where, 1, sep = ","),
    location_state = word(where, 2, sep = ",") %>% str_trim(),
    courses_taught = detail,
    additional_titles = NA_character_,
    display_order = row_number(),
    current = is.na(endYear) | endYear >= 2024
  ) %>%
  select(institution, position_title, start_date, end_date,
         location_city, location_state, courses_taught,
         additional_titles, display_order, current)

message(glue("  ✓ Converted {nrow(employment_excel)} employment records\n"))

# =============================================================================
# STEP 6: Convert Honors and Grants
# =============================================================================

message("Step 6: Converting honors and grants...")

honors_excel <- honorsGrants %>%
  mutate(
    honor_grant = honorGrant,
    location = where,
    amount = NA_real_,  # Add if you track amounts
    type = case_when(
      str_detect(honorGrant, "Grant|Fellowship") ~ "Grant",
      str_detect(honorGrant, "Award") ~ "Award",
      TRUE ~ "Honor"
    ),
    display_order = row_number(),
    highlight = row_number() <= 10,  # Top 10 as highlights
    notes = detail
  ) %>%
  select(honor_grant, grantor, location, year, amount, 
         type, display_order, highlight, notes)

message(glue("  ✓ Converted {nrow(honors_excel)} honors and grants\n"))

# =============================================================================
# STEP 7: Convert Certifications
# =============================================================================

message("Step 7: Converting certifications...")

certifications_excel <- certifications %>%
  mutate(
    cert_body = certBody,
    credential_number = NA_character_,
    status = "Active",
    display_order = row_number(),
    highlight = TRUE
  ) %>%
  select(cert_body, accomplishment, year, credential_number, 
         status, display_order, highlight, where, detail)

message(glue("  ✓ Converted {nrow(certifications_excel)} certifications\n"))

# =============================================================================
# STEP 8: Convert Other Publications/Monographs
# =============================================================================

message("Step 8: Converting other publications...")

other_pubs_excel <- otherPubsMonos %>%
  mutate(
    id = row_number(),
    type = "Monograph",
    notes = ""
  ) %>%
  select(id, title, authors, outlet, year, type, notes)

message(glue("  ✓ Converted {nrow(other_pubs_excel)} other publications\n"))

# =============================================================================
# STEP 9: Convert Academic Presentations
# =============================================================================

message("Step 9: Converting academic presentations...")

presentations_excel <- academicPresents %>%
  mutate(
    id = row_number(),
    title = articleTitle,
    conference = str_extract(detail, "^[^,]+"),
    location = str_extract(detail, "[A-Za-z ]+,\\s*[A-Z]{2}"),
    date = str_extract(detail, "\\d{4}"),
    type = "Paper",
    display_order = row_number(),
    featured = row_number() <= 5
  ) %>%
  select(id, title, authors, conference, location, 
         date, type, display_order, featured)

message(glue("  ✓ Converted {nrow(presentations_excel)} presentations\n"))

# =============================================================================
# STEP 10: Convert Service Activities
# =============================================================================

message("Step 10: Converting service activities...")

# Combine different service types
service_excel <- bind_rows(
  # Editorial service
  editor %>%
    mutate(
      organization = journal,
      start_date = glue("{as.character(begYear)}-01"),
      end_date = if_else(is.na(endYear), NA_character_, glue("{as.character(endYear)}-12")),
      category = "Editorial"
    ),
  
  # Leadership roles
  academicLeader %>%
    mutate(
      role = title,
      organization = school,
      start_date = glue("{as.character(begYear)}-01"),
      end_date = if_else(is.na(endYear), NA_character_, glue("{as.character(endYear)}-12")),
      category = "University Leadership"
    ),
  
  # Professional offices
  profesionalOFfices %>%
    mutate(
      role = title,
      organization = group,
      start_date = glue("{as.character(begYear)}-01"),
      end_date = if_else(is.na(endYear), NA_character_, glue("{as.character(endYear)}-12")),
      category = "Professional Association"
    )
) %>%
  mutate(
    display_order = row_number(),
    highlight = row_number() <= 15
  ) %>%
  select(role, organization, start_date, end_date, 
         category, display_order, highlight)

message(glue("  ✓ Converted {nrow(service_excel)} service activities\n"))

# =============================================================================
# STEP 11: Convert Media Interviews
# =============================================================================

message("Step 11: Converting media interviews...")

media_excel <- mediaInterviews %>%
  mutate(
    url = NA_character_,
    display_order = row_number(),
    featured = !is.na(year) & row_number() <= 5
  ) %>%
  select(modality, topic, outlet, year, url, display_order, featured)

message(glue("  ✓ Converted {nrow(media_excel)} media interviews\n"))

# =============================================================================
# STEP 12: Convert Student Mentoring
# =============================================================================

message("Step 12: Converting student mentoring...")

mentoring_excel <- studentMentoring %>%
  mutate(
    institution = school,
    start_date = glue("{begYear}-01"),
    end_date = if_else(
      is.na(endYear) | endYear == "Present",
      NA_character_,
      glue("{endYear}-12")
    ),
    num_students = NA_integer_,
    display_order = row_number(),
    highlight = row_number() <= 5
  ) %>%
  select(activity, institution, role, start_date, end_date,
         num_students, display_order, highlight)

message(glue("  ✓ Converted {nrow(mentoring_excel)} mentoring activities\n"))

# =============================================================================
# STEP 13: Convert Dissertation Committees
# =============================================================================

message("Step 13: Converting dissertation committees...")

dissertations_excel <- dissertationCommittees %>%
  mutate(
    id = row_number(),
    title = dissTitle,
    notes = ""
  ) %>%
  select(id, student, title, school, year, role, notes)

message(glue("  ✓ Converted {nrow(dissertations_excel)} dissertation committees\n"))

# =============================================================================
# STEP 14: Convert References
# =============================================================================

message("Step 14: Converting references...")

references_excel <- references %>%
  mutate(
    # Parse contact info from details
    email = str_extract(details, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}"),
    phone = str_extract(details, "\\+?1?[\\s-]?\\(?\\d{3}\\)?[\\s-]?\\d{3}[\\s-]?\\d{4}"),
    address = str_remove(details, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}") %>%
      str_remove("\\+?1?[\\s-]?\\(?\\d{3}\\)?[\\s-]?\\d{3}[\\s-]?\\d{4}") %>%
      str_trim()
  ) %>%
  select(name, title, email, phone, address)

message(glue("  ✓ Converted {nrow(references_excel)} references\n"))

# =============================================================================
# STEP 15: Create Metadata
# =============================================================================

message("Step 15: Creating metadata...")

metadata_excel <- tribble(
  ~setting, ~value, ~description,
  "cv_name", "John Paul Broussard", "Full name for CV header",
  "cv_position", "Finance Professor with Decades of Superior Administrative, Research, and Teaching Experiences", 
  "Position title for CV header",
  "cv_address", "Oklahoma City, Oklahoma, USA", "Mailing address",
  "cv_email", "john.broussard@rutgers.edu", "Contact email",
  "cv_website", "tinyurl.com/c3wdneyp", "Personal website",
  "cv_linkedin", "tinyurl.com/5bfex8hv", "LinkedIn profile",
  "cv_orcid", "0000-0002-5090-9947", "ORCID identifier",
  "cv_photo_path", "./img/jaafGalaPic.jpg", "Path to profile photo",
  "last_updated", as.character(Sys.Date()), "Date of last update",
  "version", "2.0", "CV version number",
  "include_references", "TRUE", "Include references section?",
  "admin_experience_limit", "15", "Maximum administrative items",
  "publications_since_year", "2013", "Only show publications from this year",
  "show_metrics", "TRUE", "Display quantified metrics?",
  "primary_color", "990000", "Primary brand color (hex)"
)

message("  ✓ Created metadata\n")

# =============================================================================
# STEP 16: Create README Sheet
# =============================================================================

readme_excel <- tribble(
  ~Section, ~Content,
  "Welcome", "This Excel workbook contains all data for your academic CV.",
  "Instructions", "1. Edit each sheet to add/modify your CV content",
  "Instructions", "2. Do NOT change column names - the R script depends on them",
  "Instructions", "3. Use display_order column to control sequence of items",
  "Instructions", "4. Set highlight=TRUE or featured=TRUE for key items",
  "Instructions", "5. After editing, run load_cv_data('cv_data.xlsx') in R",
  "Tips", "Use Excel's sort/filter to organize data easily",
  "Tips", "The notes column is for your reference only (not displayed in CV)",
  "Tips", "Dates should be in YYYY-MM format (e.g., 2025-01)",
  "Tips", "Use NA for missing numeric values",
  "Important", "This file was AUTO-GENERATED from your jpbsCVdata.r file",
  "Important", "Review each sheet and enhance with metrics, dates, etc.",
  "Important", "Some fields may need manual completion (marked with NA)",
  "Version", glue("Converted: {Sys.Date()}")
)

# =============================================================================
# STEP 17: Write Everything to Excel
# =============================================================================

message("\nStep 17: Writing to Excel file...")

output_file <- here("jpbsCVdata", "cv_data.xlsx")

all_sheets <- list(
  "README" = readme_excel,
  "Metadata" = metadata_excel,
  "Administrative" = admin_excel,
  "Publications" = publications_excel,
  "WorkingPapers" = working_papers_excel,
  "Employment" = employment_excel,
  "Honors" = honors_excel,
  "Certifications" = certifications_excel,
  "OtherPublications" = other_pubs_excel,
  "Presentations" = presentations_excel,
  "Service" = service_excel,
  "Media" = media_excel,
  "Mentoring" = mentoring_excel,
  "Dissertations" = dissertations_excel,
  "References" = references_excel
)

write_xlsx(all_sheets, output_file)

message("\n=======================================================")
message("✓ CONVERSION COMPLETE!")
message("=======================================================\n")
message("Created: ", output_file)
message("\nContents:")
message("  - Administrative:      ", nrow(admin_excel), " items")
message("  - Publications:        ", nrow(publications_excel), " items")
message("  - Working Papers:      ", nrow(working_papers_excel), " items")
message("  - Employment:          ", nrow(employment_excel), " items")
message("  - Honors/Grants:       ", nrow(honors_excel), " items")
message("  - Certifications:      ", nrow(certifications_excel), " items")
message("  - Other Publications:  ", nrow(other_pubs_excel), " items")
message("  - Presentations:       ", nrow(presentations_excel), " items")
message("  - Service:             ", nrow(service_excel), " items")
message("  - Media:               ", nrow(media_excel), " items")
message("  - Mentoring:           ", nrow(mentoring_excel), " items")
message("  - Dissertations:       ", nrow(dissertations_excel), " items")
message("  - References:          ", nrow(references_excel), " items")
message("\n=======================================================")
message("NEXT STEPS:")
message("=======================================================")
message("1. Open ", output_file)
message("2. Review each sheet - verify data converted correctly")
message("3. Enhance with additional info:")
message("   - Add start_date and end_date for admin items")
message("   - Add metric_value and metric_label for achievements")
message("   - Add abstracts for working papers")
message("   - Add target_journal for working papers")
message("   - Complete position_title for employment")
message("   - Mark featured publications (featured=TRUE)")
message("4. Save and close Excel")
message("5. Test loading: source('jpbsCVdata/load_cv_data.r')")
message("6. Render CV: source('render_cv.R'); main('html')")
message("=======================================================\n")

# =============================================================================
# STEP 18: Create Backup of Original
# =============================================================================

backup_file <- here("jpbsCVdata", "jpbsCVdata_BACKUP.r")
if (file.exists(here("jpbsCVdata", "jpbsCVdata.r"))) {
  file.copy(
    here("jpbsCVdata", "jpbsCVdata.r"),
    backup_file,
    overwrite = TRUE
  )
  message("✓ Backed up original file to: ", backup_file, "\n")
}

# Open Excel file for review
if (interactive()) {
  message("Opening Excel file for your review...")
  if (.Platform$OS.type == "windows") {
    shell.exec(output_file)
  } else if (Sys.info()["sysname"] == "Darwin") {
    system(paste("open", shQuote(output_file)))
  } else {
    system(paste("xdg-open", shQuote(output_file)))
  }
}

message("\n🎉 Your CV data has been successfully converted to Excel!")
message("Review the file, make enhancements, then you're ready to render!\n")