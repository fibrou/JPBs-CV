#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}  Fixing Awesome-CV Template Version${NC}"
echo -e "${BOLD}================================================${NC}"
echo

# Create a version that works with awesome-cv
echo -e "${BLUE}Creating fixed awesome-cv version...${NC}"

cat > jpbsQuartoCV_awesome_fixed.qmd << 'EOF'
---
name: John Paul
surname: Broussard
position: "Finance Professor with Decades of Superior Administrative, Research, and Teaching Experiences"
address: "Oklahoma City, Oklahoma, USA"
profilepic: "jaafGalaPic.jpg"
www: tinyurl.com/c3wdneyp
email: john.broussard@rutgers.edu
linkedin: tinyurl.com/5bfex8hv
orcid: 0000-0002-5090-9947
aboutme: "I am a Finance Professor with over 25 years of extensive domestic and international experience in online and traditional academic program management. I create academic programs and courses that monetize academic effort and yield institutional revenue enhancement and stakeholder success."
docname: Curriculum Vitae
format:
  pdf:
    template: awesome-cv.tex
    pdf-engine: xelatex
    keep-tex: false
date: now
date-format: "MMMM YYYY"
execute:
  echo: false
  warning: false
  message: false
---

```{r setup, include=FALSE}
library(knitr)
library(tidyverse)
library(here)

# Load data safely
tryCatch({
  source("jpbsCVdata/load_cv_data.r")
  cv_data <- load_cv_data()
  if (!is.null(cv_data)) {
    list2env(cv_data, envir = .GlobalEnv)
  }
}, error = function(e) {
  message("Using fallback data")
})

# Ensure we don't output tibbles
options(knitr.kable.NA = '')
```

## Administrative Experience

```{r admin, results='asis'}
cat("\\begin{cventries}\n")

# Director position
cat("\\cventry\n")
cat("{Director of Online MS Finance Program}\n")
cat("{University of Oklahoma}\n")
cat("{Norman, OK}\n")
cat("{2021-2024}\n")
cat("{\\begin{cvitems}\n")
cat("\\item Directed High Graduation Rate (>78\\%) Online Degree with approximately 150 students\n")
cat("\\item Attained CFA Institute University Affiliation Program status\n")
cat("\\item Developed Marketing Strategy for Implementation by 3rd Party Provider\n")
cat("\\item Created Streamlined Admissions Process for Automatic and Accelerated Admission Decisions\n")
cat("\\end{cvitems}}\n\n")

# Assistant Director
cat("\\cventry\n")
cat("{Assistant Director of Finance Division}\n")
cat("{University of Oklahoma}\n")
cat("{Norman, OK}\n")
cat("{2021-2024}\n")
cat("{\\begin{cvitems}\n")
cat("\\item Managed 5th Largest Unit in OU system - Approximately 1050 Majors\n")
cat("\\item Recruited Students and Faculty, Developed and Managed Programs\n")
cat("\\item Directed Initiative to Restructure Undergraduate Curriculum\n")
cat("\\end{cvitems}}\n\n")

cat("\\end{cventries}\n")
```

## Education

```{r education, results='asis'}
cat("\\begin{cventries}\n")

cat("\\cventry\n")
cat("{Ph.D. in Finance}\n")
cat("{Louisiana State University}\n")
cat("{Baton Rouge, LA}\n")
cat("{1991-1995}\n")
cat("{}\n\n")

cat("\\cventry\n")
cat("{MBA in Finance}\n")
cat("{Millsaps College}\n")
cat("{Jackson, MS}\n")
cat("{1988-1991}\n")
cat("{}\n\n")

cat("\\cventry\n")
cat("{B.S. in Biochemistry}\n")
cat("{Louisiana State University}\n")
cat("{Baton Rouge, LA}\n")
cat("{1981-1985}\n")
cat("{}\n\n")

cat("\\end{cventries}\n")
```

## Professional Certifications

```{r certs, results='asis'}
cat("\\begin{cvhonors}\n")
cat("\\cvhonor{CFA}{Chartered Financial Analyst}{CFA Institute}{1997}\n")
cat("\\cvhonor{FRM}{Financial Risk Manager}{GARP}{1999}\n")
cat("\\cvhonor{PRM}{Professional Risk Manager}{PRMIA}{2003}\n")
cat("\\end{cvhonors}\n")
```
EOF

echo -e "${GREEN}✓ Created jpbsQuartoCV_awesome_fixed.qmd${NC}"

# Now try rendering it
echo
echo -e "${BLUE}Testing awesome-cv rendering...${NC}"

if quarto render jpbsQuartoCV_awesome_fixed.qmd --to pdf 2>&1 | tail -10; then
    if [ -f "jpbsQuartoCV_awesome_fixed.pdf" ]; then
        mv jpbsQuartoCV_awesome_fixed.pdf output/jpbCV_awesome.pdf
        echo
        echo -e "${GREEN}✓ Awesome-CV PDF generated successfully!${NC}"
        echo "  Location: output/jpbCV_awesome.pdf"
    fi
else
    echo -e "${YELLOW}Awesome-CV still has issues. Using professional template instead.${NC}"
fi

echo
echo -e "${GREEN}Done!${NC}"