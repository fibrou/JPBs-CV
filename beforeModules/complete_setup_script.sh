#!/bin/bash

# JPB CV Complete Setup Script
# This script sets up everything needed for the modular CV system

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║    JPB Modular CV System - Complete Setup      ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════════════╝${NC}"
echo

# Create directory structure
echo -e "${BLUE}Creating directory structure...${NC}"
mkdir -p cv_modules
mkdir -p cv_data
mkdir -p cv_assets
mkdir -p output
echo -e "${GREEN}✓ Directories created${NC}"

# Handle profile picture
echo -e "${BLUE}Setting up profile picture...${NC}"
PHOTO_FOUND=false
for photo in jaafGalaPic.jpg img/jaafGalaPic.jpg assets/jaafGalaPic.jpg; do
    if [ -f "$photo" ]; then
        cp "$photo" cv_assets/jpbsLatestProfilePic.jpg
        echo -e "${GREEN}✓ Profile picture copied to cv_assets/jpbsLatestProfilePic.jpg${NC}"
        PHOTO_FOUND=true
        break
    fi
done

if [ "$PHOTO_FOUND" = false ]; then
    echo -e "${YELLOW}⚠ Profile picture not found - CV will generate without photo${NC}"
fi

# Copy Excel data file
echo -e "${BLUE}Setting up data files...${NC}"
EXCEL_FOUND=false
for excel in jpbsCVdata/cv_data_with_education.xlsx jpbsCVdata/cv_data.xlsx; do
    if [ -f "$excel" ]; then
        cp "$excel" cv_data/cv_data_master.xlsx
        echo -e "${GREEN}✓ Excel data copied to cv_data/cv_data_master.xlsx${NC}"
        EXCEL_FOUND=true
        break
    fi
done

# Create data loader
cat > cv_data/load_cv_data.r << 'EOF'
# CV Data Loader with Helper Functions
load_cv_data <- function(file_path = NULL) {
  library(readxl)
  library(dplyr)
  library(here)
  
  if (is.null(file_path)) {
    file_path <- here("cv_data", "cv_data_master.xlsx")
  }
  
  if (!file.exists(file_path)) {
    stop(paste("CV data file not found at:", file_path))
  }
  
  sheets <- excel_sheets(file_path)
  cv_data <- list()
  
  for (sheet in sheets) {
    tryCatch({
      data <- read_excel(file_path, sheet = sheet)
      names(data) <- tolower(gsub(" ", "_", names(data)))
      cv_data[[tolower(sheet)]] <- data
    }, error = function(e) {
      message(paste("Warning: Could not load sheet", sheet))
    })
  }
  
  return(cv_data)
}

escape_latex <- function(text) {
  if (is.na(text) || text == "") return("")
  text <- as.character(text)
  text <- gsub("&", "\\\\&", text)
  text <- gsub("%", "\\\\%", text)
  text <- gsub("\\$", "\\\\$", text)
  text <- gsub("#", "\\\\#", text)
  text <- gsub("_", "\\\\_", text)
  text <- gsub(">", "\\\\textgreater{}", text)
  text <- gsub("<", "\\\\textless{}", text)
  return(text)
}

format_date_range <- function(start, end) {
  start <- as.character(start)
  end <- as.character(end)
  
  if (is.na(start) || start == "") return("")
  if (is.na(end) || end == "" || tolower(end) == "present") {
    return(paste0(start, " -- Present"))
  }
  return(paste0(start, " -- ", end))
}
EOF
echo -e "${GREEN}✓ Data loader created${NC}"

# Update Excel with AboutMe sheet
if [ "$EXCEL_FOUND" = true ]; then
    echo -e "${BLUE}Adding AboutMe sheet to Excel...${NC}"
    R --quiet --vanilla << 'RSCRIPT' 2>/dev/null
library(readxl)
library(openxlsx)

wb_path <- "cv_data/cv_data_master.xlsx"
if (file.exists(wb_path)) {
  wb <- loadWorkbook(wb_path)
  
  aboutme_data <- data.frame(
    section = c("full_about", "short_about", "tagline", "email", "website", 
                "linkedin", "orcid", "address", "city_state"),
    content = c(
      "I am a Finance Professor with over 25 years of extensive domestic and international experience in online and traditional academic program management. I create academic programs and courses that monetize academic effort and yield institutional revenue enhancement and stakeholder success. I maintain real-world relevance through being a Financial Professional Designation Exam Trainer, Financial Risk Management Specialist, Financial Market Consultant, Expert on Big Data, Implementer of Natural Language Processing, Artificial Intelligence and Machine Learning applications in Finance.",
      "Finance Professor with 25+ years of experience in academic program management.",
      "Finance Professor with Decades of Superior Administrative, Research, and Teaching Experiences",
      "john.broussard@rutgers.edu",
      "tinyurl.com/c3wdneyp",
      "tinyurl.com/5bfex8hv",
      "0000-0002-5090-9947",
      "9987 Monarch Landing Cove",
      "Willis, Texas 77318"
    ),
    active = rep(TRUE, 9),
    stringsAsFactors = FALSE
  )
  
  if ("AboutMe" %in% names(wb)) removeWorksheet(wb, "AboutMe")
  addWorksheet(wb, "AboutMe")
  writeData(wb, "AboutMe", aboutme_data)
  saveWorkbook(wb, wb_path, overwrite = TRUE)
  cat("AboutMe sheet added\n")
}
RSCRIPT
    echo -e "${GREEN}✓ AboutMe data configured${NC}"
fi

# Create Module 1: Administrative
echo -e "${BLUE}Creating CV modules...${NC}"
cat > cv_modules/01_administrative.qmd << 'EOF'
## Administrative Experience

```{r admin, results='asis'}
if (exists("administrative") && !is.null(administrative)) {
  admin_data <- administrative %>%
    filter(!is.na(title)) %>%
    arrange(display_order, desc(start_date))
  
  if (nrow(admin_data) > 0) {
    cat("\\begin{cventries}\n")
    
    for (i in 1:min(nrow(admin_data), 10)) {
      title <- escape_latex(admin_data$title[i])
      inst <- escape_latex(admin_data$institution[i])
      loc <- if (!is.na(admin_data$location[i])) escape_latex(admin_data$location[i]) else ""
      dates <- format_date_range(admin_data$start_date[i], admin_data$end_date[i])
      
      cat("\\cventry\n")
      cat("{", title, "}\n", sep = "")
      cat("{", inst, "}\n", sep = "")
      cat("{", loc, "}\n", sep = "")
      cat("{", dates, "}\n", sep = "")
      cat("{\\begin{cvitems}\n")
      
      details <- c()
      if (!is.na(admin_data$detail[i])) {
        detail_items <- strsplit(as.character(admin_data$detail[i]), ";")[[1]]
        details <- c(details, trimws(detail_items))
      }
      
      for (col in names(admin_data)[grepl("^detail_[0-9]+$", names(admin_data))]) {
        if (!is.na(admin_data[[col]][i]) && admin_data[[col]][i] != "") {
          details <- c(details, admin_data[[col]][i])
        }
      }
      
      for (detail in details) {
        cat("\\item ", escape_latex(detail), "\n", sep = "")
      }
      
      cat("\\end{cvitems}}\n\n")
    }
    cat("\\end{cventries}\n")
  }
}
```
EOF

# Create Module 2: Education
cat > cv_modules/02_education.qmd << 'EOF'
## Education

```{r education, results='asis'}
if (exists("education") && !is.null(education)) {
  edu_data <- education %>%
    filter(!is.na(degree)) %>%
    arrange(display_order, desc(end_year))
  
  cat("\\begin{cventries}\n")
  
  for (i in 1:nrow(edu_data)) {
    cat("\\cventry\n")
    cat("{", escape_latex(edu_data$degree[i]), "}\n", sep = "")
    cat("{", escape_latex(edu_data$institution[i]), "}\n", sep = "")
    cat("{", escape_latex(paste(edu_data$location_city[i], edu_data$location_state[i], sep = ", ")), "}\n", sep = "")
    cat("{", edu_data$start_year[i], "--", edu_data$end_year[i], "}\n", sep = "")
    cat("{}\n\n")
  }
  
  cat("\\end{cventries}\n")
}
```
EOF

# Create Module 3: Certifications
cat > cv_modules/03_certifications.qmd << 'EOF'
## Professional Certifications

```{r certifications, results='asis'}
if (exists("certifications") && !is.null(certifications)) {
  cert_data <- certifications %>%
    filter(!is.na(accomplishment)) %>%
    arrange(desc(year))
  
  cat("\\begin{cvhonors}\n")
  
  for (i in 1:nrow(cert_data)) {
    full_cert <- cert_data$accomplishment[i]
    abbrev <- gsub(".*\\((.*)\\).*", "\\1", full_cert)
    if (abbrev == full_cert) abbrev <- substr(full_cert, 1, 3)
    
    cat("\\cvhonor")
    cat("{", abbrev, "}", sep = "")
    cat("{", escape_latex(cert_data$accomplishment[i]), "}", sep = "")
    cat("{", escape_latex(cert_data$cert_body[i]), "}", sep = "")
    cat("{", cert_data$year[i], "}\n", sep = "")
  }
  
  cat("\\end{cvhonors}\n")
}
```
EOF

# Create Module 4: Appointments
cat > cv_modules/04_appointments.qmd << 'EOF'
## Academic Appointments

```{r appointments, results='asis'}
if (exists("employment") && !is.null(employment)) {
  emp_data <- employment %>%
    filter(!is.na(institution)) %>%
    arrange(display_order, desc(start_date))
  
  cat("\\begin{cventries}\n")
  
  for (i in 1:min(nrow(emp_data), 15)) {
    position <- if (!is.na(emp_data$position_title[i])) {
      escape_latex(emp_data$position_title[i])
    } else "Professor"
    
    cat("\\cventry\n")
    cat("{", position, "}\n", sep = "")
    cat("{", escape_latex(emp_data$institution[i]), "}\n", sep = "")
    cat("{", escape_latex(paste(emp_data$location_city[i], emp_data$location_state[i], sep = ", ")), "}\n", sep = "")
    cat("{", format_date_range(emp_data$start_date[i], emp_data$end_date[i]), "}\n", sep = "")
    cat("{}\n\n")
  }
  
  cat("\\end{cventries}\n")
}
```
EOF

# Create Module 5: Publications
cat > cv_modules/05_publications.qmd << 'EOF'
## Selected Recent Publications

```{r publications, results='asis'}
if (exists("publications") && !is.null(publications)) {
  pubs <- publications %>%
    filter(!is.na(title)) %>%
    arrange(desc(year)) %>%
    head(10)
  
  if (nrow(pubs) > 0) {
    cat("\\begin{cventries}\n")
    
    for (i in 1:nrow(pubs)) {
      cat("\\cventry\n")
      cat("{", escape_latex(pubs$title[i]), "}\n", sep = "")
      cat("{", escape_latex(pubs$journal[i]), "}\n", sep = "")
      cat("{", escape_latex(pubs$authors[i]), "}\n", sep = "")
      cat("{", pubs$year[i], "}\n", sep = "")
      cat("{}\n\n")
    }
    
    cat("\\end{cventries}\n")
  }
}
```
EOF

# Create empty modules for future expansion
cat > cv_modules/06_honors.qmd << 'EOF'
<!-- Honors section - to be added -->
EOF

cat > cv_modules/07_service.qmd << 'EOF'
<!-- Service section - to be added -->
EOF

echo -e "${GREEN}✓ All modules created${NC}"

echo
echo -e "${BOLD}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║            Setup Complete!                      ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════════════╝${NC}"
echo
echo "Next steps:"
echo "  1. Create jpbCV_main.qmd (provided separately)"
echo "  2. Run: quarto render jpbCV_main.qmd --to pdf"
echo "  3. Your CV will be at: output/jpbCV_main.pdf"
echo
echo "Directory structure created:"
echo "  📁 cv_modules/     - Individual QMD modules"
echo "  📁 cv_data/        - Excel data and loader"
echo "  📁 cv_assets/      - Profile picture"
echo "  📁 output/         - Generated PDFs"
echo
echo -e "${GREEN}✓ All components ready!${NC}"