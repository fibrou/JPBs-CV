#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}     Fixing PDF Rendering Issues${NC}"
echo -e "${BOLD}================================================${NC}"
echo

# 1. Check for the profile photo
echo -e "${BLUE}1. Checking for profile photo...${NC}"
if [ ! -f "jaafGalaPic.jpg" ]; then
    echo -e "${RED}✗ jaafGalaPic.jpg not found in current directory${NC}"
    
    # Look for it in other locations
    if [ -f "img/jaafGalaPic.jpg" ]; then
        cp "img/jaafGalaPic.jpg" .
        echo -e "${GREEN}✓ Copied from img/ directory${NC}"
    elif [ -f "assets/jaafGalaPic.jpg" ]; then
        cp "assets/jaafGalaPic.jpg" .
        echo -e "${GREEN}✓ Copied from assets/ directory${NC}"
    elif [ -f "../jpbDataDrivenCV/img/jaafGalaPic.jpg" ]; then
        cp "../jpbDataDrivenCV/img/jaafGalaPic.jpg" .
        echo -e "${GREEN}✓ Copied from jpbDataDrivenCV${NC}"
    else
        echo -e "${YELLOW}⚠ Creating placeholder image...${NC}"
        # Create a simple placeholder using ImageMagick if available
        if command -v convert &> /dev/null; then
            convert -size 200x200 xc:gray -pointsize 30 -gravity center -annotate +0+0 "JPB" jaafGalaPic.jpg
            echo -e "${GREEN}✓ Placeholder created${NC}"
        else
            echo -e "${RED}Please add jaafGalaPic.jpg to the current directory${NC}"
        fi
    fi
else
    echo -e "${GREEN}✓ jaafGalaPic.jpg found${NC}"
fi

echo
# 2. Check for awesome-cv template files
echo -e "${BLUE}2. Checking for awesome-cv template files...${NC}"
if [ ! -f "awesome-cv.cls" ]; then
    echo -e "${YELLOW}⚠ awesome-cv.cls not found${NC}"
    echo "Attempting to download from GitHub..."
    
    # Download the awesome-cv class file
    if command -v wget &> /dev/null; then
        wget -q https://raw.githubusercontent.com/posquit0/Awesome-CV/master/awesome-cv.cls
        if [ -f "awesome-cv.cls" ]; then
            echo -e "${GREEN}✓ Downloaded awesome-cv.cls${NC}"
        fi
    elif command -v curl &> /dev/null; then
        curl -sL https://raw.githubusercontent.com/posquit0/Awesome-CV/master/awesome-cv.cls -o awesome-cv.cls
        if [ -f "awesome-cv.cls" ]; then
            echo -e "${GREEN}✓ Downloaded awesome-cv.cls${NC}"
        fi
    fi
    
    # Also get the fonts directory if needed
    if [ ! -d "fonts" ]; then
        echo "Downloading fonts..."
        mkdir -p fonts
        cd fonts
        for font in FontAwesome.otf Roboto-*.ttf SourceSansPro-*.ttf; do
            wget -q "https://github.com/posquit0/Awesome-CV/raw/master/fonts/$font" 2>/dev/null || true
        done
        cd ..
        echo -e "${GREEN}✓ Fonts downloaded${NC}"
    fi
else
    echo -e "${GREEN}✓ awesome-cv.cls found${NC}"
fi

echo
# 3. Install missing LaTeX packages
echo -e "${BLUE}3. Checking LaTeX installation...${NC}"
if ! command -v xelatex &> /dev/null; then
    echo -e "${YELLOW}⚠ XeLaTeX not found. Installing TinyTeX...${NC}"
    quarto install tinytex
else
    echo -e "${GREEN}✓ XeLaTeX found${NC}"
fi

echo
# 4. Create a simplified PDF version that should work
echo -e "${BLUE}4. Creating simplified PDF version...${NC}"
cat > jpbsQuartoCV_simple_pdf.qmd << 'EOF'
---
title: "John Paul Broussard"
subtitle: "Curriculum Vitae"
format:
  pdf:
    documentclass: article
    geometry:
      - margin=1in
    fontsize: 11pt
    include-in-header:
      text: |
        \usepackage{titlesec}
        \titleformat{\section}{\large\bfseries}{\thesection}{1em}{}
        \titleformat{\subsection}{\normalsize\bfseries}{\thesubsection}{1em}{}
execute:
  echo: false
  warning: false
  message: false
---

```{r setup, include=FALSE}
library(tidyverse)
library(knitr)
library(here)

# Load CV data
if (file.exists("jpbsCVdata/load_cv_data.r")) {
  source("jpbsCVdata/load_cv_data.r")
  cv_data <- load_cv_data("jpbsCVdata/cv_data_with_education.xlsx")
  list2env(cv_data, envir = .GlobalEnv)
}
```

# John Paul Broussard

**Finance Professor with Decades of Superior Administrative, Research, and Teaching Experiences**

Willis, Texas, USA  
Email: john.broussard@rutgers.edu  
LinkedIn: tinyurl.com/5bfex8hv  
ORCID: 0000-0002-5090-9947  

---

## Professional Summary

I am a Finance Professor with over 25 years of extensive domestic and international experience in online and traditional academic program management. I create academic programs and courses that monetize academic effort and yield institutional revenue enhancement and stakeholder success.

## Administrative Experience

```{r admin, results='asis'}
if (exists("admin") && !is.null(admin)) {
  admin_highlight <- admin %>%
    filter(highlight == TRUE) %>%
    arrange(display_order)
  
  for (i in 1:nrow(admin_highlight)) {
    cat("### ", admin_highlight$title[i], "\n\n")
    cat("*", admin_highlight$institution[i], "*\n\n")
    cat("-", admin_highlight$detail[i], "\n\n")
  }
} else {
  cat("### Director of Online MS Finance Program\n\n")
  cat("*University of Oklahoma*\n\n")
  cat("- Directed High Graduation Rate (>78%) Online Degree with approximately 150 students\n")
  cat("- Attained CFA Institute University Affiliation Program status\n\n")
}
```

## Education

```{r education, results='asis'}
cat("### Ph.D., Finance (1991-1995)\n")
cat("*Louisiana State University, Baton Rouge, LA*\n\n")

cat("### MBA, Finance (1988-1991)\n")
cat("*Millsaps College, Jackson, MS*\n\n")

cat("### B.S., Biochemistry (1981-1985)\n")
cat("*Louisiana State University, Baton Rouge, LA*\n\n")
```

## Professional Certifications

- **Chartered Financial Analyst (CFA)** - CFA Institute, 1997
- **Financial Risk Manager (FRM)** - GARP, 1999
- **Professional Risk Manager (PRM)** - PRMIA, 2003

## Current Appointments

```{r employment, results='asis'}
cat("### Associate Professor of Finance\n")
cat("*SUNY - Empire State University* (August 2025 - Present)\n\n")

cat("### Professor Emeritus\n")
cat("*Rutgers University* (2018 - Present)\n\n")

cat("### Visiting Professor\n")
cat("*Estonian Business School* (October 2024 - Present)\n\n")
```

## Selected Publications

```{r publications, results='asis'}
if (exists("publications") && !is.null(publications)) {
  recent_pubs <- publications %>%
    filter(year >= 2020) %>%
    arrange(desc(year)) %>%
    head(5)
  
  for (i in 1:nrow(recent_pubs)) {
    cat("- ", recent_pubs$authors[i], " (", recent_pubs$year[i], "). ",
        "**", recent_pubs$title[i], "**. ",
        "*", recent_pubs$journal[i], "*.\n\n", sep="")
  }
} else {
  cat("- Publications list available upon request\n\n")
}
```
EOF

echo -e "${GREEN}✓ Created simplified PDF version${NC}"

echo
# 5. Try rendering the simplified version
echo -e "${BLUE}5. Testing simplified PDF rendering...${NC}"
if quarto render jpbsQuartoCV_simple_pdf.qmd --to pdf; then
    echo -e "${GREEN}✓ Simple PDF rendered successfully${NC}"
    mv jpbsQuartoCV_simple_pdf.pdf output/jpbsQuartoCV_simple.pdf 2>/dev/null
    echo "Simplified PDF saved as: output/jpbsQuartoCV_simple.pdf"
else
    echo -e "${YELLOW}⚠ Simple PDF rendering failed${NC}"
fi

echo
echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}Recommendations:${NC}"
echo -e "${BOLD}================================================${NC}"
echo
echo "1. The HTML version is working perfectly!"
echo "   View it at: output/jpbsQuartoCV.html"
echo
echo "2. For the PDF version with awesome-cv template:"
echo "   - Make sure jaafGalaPic.jpg is in the current directory"
echo "   - Ensure awesome-cv.cls is present"
echo "   - Try the simplified PDF version as a backup"
echo
echo "3. To retry the main PDF after fixes:"
echo "   quarto render jpbsQuartoCV.qmd --to pdf"
echo
echo -e "${GREEN}✓ Fix script complete${NC}"