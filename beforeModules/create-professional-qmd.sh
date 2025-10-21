#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}  Creating Professional PDF CV${NC}"
echo -e "${BOLD}================================================${NC}"
echo

# Create the professional QMD file
echo -e "${BLUE}Creating jpbsQuartoCV_professional.qmd...${NC}"

cat > jpbsQuartoCV_professional.qmd << 'EOF'
---
title: "John Paul Broussard"
subtitle: |
  Finance Professor with Decades of Superior Administrative, Research, and Teaching Experiences  
  Oklahoma City, Oklahoma, USA
format:
  pdf:
    documentclass: article
    geometry:
      - top=0.75in
      - bottom=0.75in
      - left=0.8in
      - right=0.8in
    fontsize: 11pt
    linestretch: 1.05
    include-in-header:
      text: |
        \usepackage{titlesec}
        \usepackage{enumitem}
        \usepackage{fancyhdr}
        \usepackage{hyperref}
        \usepackage{xcolor}
        \definecolor{darkblue}{RGB}{44,95,124}
        \definecolor{sectionred}{RGB}{153,0,0}
        \hypersetup{colorlinks=true, linkcolor=darkblue, urlcolor=darkblue}
        \pagestyle{fancy}
        \fancyhf{}
        \renewcommand{\headrulewidth}{0pt}
        \fancyfoot[C]{\footnotesize \thepage}
        \titleformat{\section}{\Large\bfseries\color{sectionred}}{\thesection}{0em}{}[\titlerule]
        \titleformat{\subsection}{\large\bfseries}{\thesubsection}{0.5em}{}
        \titlespacing{\section}{0pt}{*1.5}{*1}
        \titlespacing{\subsection}{0pt}{*1}{*0.5}
        \setlist[itemize]{leftmargin=*, topsep=1pt, itemsep=0pt, parsep=1pt}
        \setlength{\parindent}{0pt}
        \setlength{\parskip}{0.5em}
execute:
  echo: false
  warning: false
  message: false
---

\vspace{-1.5cm}

```{r setup, include=FALSE}
library(tidyverse)
library(knitr)
library(here)
library(glue)

# Set knitr options to prevent tibble output
knitr::opts_chunk$set(
  echo = FALSE, 
  warning = FALSE, 
  message = FALSE, 
  results = 'asis'
)

# Load CV data
tryCatch({
  source("jpbsCVdata/load_cv_data.r")
  cv_data <- load_cv_data()
  
  # Extract dataframes properly
  if (!is.null(cv_data)) {
    for (name in names(cv_data)) {
      assign(name, cv_data[[name]], envir = .GlobalEnv)
    }
  }
}, error = function(e) {
  # Create minimal fallback data
  message("Using fallback data")
})
```

\begin{center}
\textbf{Contact:} \href{mailto:john.broussard@rutgers.edu}{john.broussard@rutgers.edu} $\bullet$ 
\href{https://tinyurl.com/c3wdneyp}{tinyurl.com/c3wdneyp} $\bullet$ 
\href{https://orcid.org/0000-0002-5090-9947}{0000-0002-5090-9947} $\bullet$ 
\href{https://tinyurl.com/5bfex8hv}{tinyurl.com/5bfex8hv}
\end{center}

\vspace{-0.3cm}
\noindent\rule{\textwidth}{0.4pt}
\vspace{-0.3cm}

*I am a Finance Professor with over 25 years of extensive domestic and international experience in online and traditional academic program management. I create academic programs and courses that monetize academic effort and yield institutional revenue enhancement and stakeholder success. I maintain real-world relevance through being a Financial Professional Designation Exam Trainer, Financial Risk Management Specialist, Financial Market Consultant, Expert on Big Data, Implementer of Natural Language Processing, Artificial Intelligence and Machine Learning applications in Finance.*

# ADMINISTRATIVE EXPERIENCE

```{r admin}
# Manual entry to ensure proper formatting
cat("\\textbf{Director of Online MS Finance Program}, University of Oklahoma\n\n")
cat("\\begin{itemize}\n")
cat("\\item Directed High Graduation Rate (>78\\%) Online Degree with approximately 150 students\n")
cat("\\item Attained CFA Institute University Affiliation Program status\n")
cat("\\item Developed Marketing Strategy for Implementation by 3rd Party Provider\n")
cat("\\item Created Streamlined Admissions Process for Automatic and Accelerated Admission Decisions\n")
cat("\\item Modified and Updated Program Offerings for Learner Flexibility\n")
cat("\\item Worked with Instructional Design Team to Deliver Consistent Course Structures\n")
cat("\\item Created and Delivered 1st Asynchronous Offering\n")
cat("\\end{itemize}\n\n")

cat("\\textbf{Assistant Director of Finance Division}, University of Oklahoma\n\n")
cat("\\begin{itemize}\n")
cat("\\item Assisted Director (Chair) with Managing 5th Largest Unit in OU system - Approximately 1050 Majors\n")
cat("\\item Managed Staff, Recruited Students and Faculty, Developed and Managed Programs, Engaged in Strategic Planning\n")
cat("\\item Directed Initiative to Restructure Undergraduate Curriculum to Incorporate Certificate Structure\n")
cat("\\item Modified Teaching Schedules, Worked with Development Office on 7-Figure Fund-Raising Gifts\n")
cat("\\end{itemize}\n\n")

cat("\\textbf{Co-Program Director for Global Business Experience in Arezzo Italy}, University of Oklahoma\n\n")
cat("\\begin{itemize}\n")
cat("\\item Managed Schedule for Academic and Cultural Activities\n")
cat("\\item Taught Undergraduate Principles of Finance\n")
cat("\\item Guided Students on Cultural Trips to Florence and Rome\n")
cat("\\end{itemize}\n\n")

cat("\\textbf{Finance Area Head}, Estonian Business School\n\n")
cat("\\begin{itemize}\n")
cat("\\item Managed Program Across Multi-Nation Campuses, Created Nano Degree, Recruited Faculty, Engaged in Strategic Planning\n")
cat("\\end{itemize}\n\n")

cat("\\textbf{Multi-Year Finance Area Head}, Rutgers University\n\n")
cat("\\begin{itemize}\n")
cat("\\item Led Online MBA Initiative, Managed Teaching Schedule, Recruited Faculty\n")
cat("\\item Engaged in Strategic Planning, Worked with Donors on 5-Figure Scholarship Gifts\n")
cat("\\end{itemize}\n")
```

# EDUCATION

```{r education}
cat("\\textbf{Ph.D., Finance} (1991--1995)\\\\\n")
cat("Louisiana State University, Baton Rouge, LA\n\n")

cat("\\textbf{MBA, Finance} (1988--1991)\\\\\n")
cat("Millsaps College, Jackson, MS\n\n")

cat("\\textbf{B.S., Biochemistry} (1981--1985)\\\\\n")
cat("Louisiana State University, Baton Rouge, LA\n\n")
```

# PROFESSIONAL CERTIFICATIONS

```{r certifications}
cat("\\textbf{Chartered Financial Analyst (CFA)}, 1997\\\\\n")
cat("CFA Institute\n\n")

cat("\\textbf{Certified Financial Risk Manager (FRM)}, 1999\\\\\n")
cat("Global Association of Risk Professionals\n\n")

cat("\\textbf{Professional Risk Manager (PRM)}, 2003\\\\\n")
cat("Professional Risk Managers' International Association\n\n")
```

# LONG-TERM ACADEMIC APPOINTMENTS

```{r appointments}
cat("\\textbf{Associate Professor of Finance}\\\\\n")
cat("SUNY - Empire, Saratoga Springs, NY (August 2025 -- Present)\n\n")

cat("\\textbf{Professor of Finance}\\\\\n")
cat("University of Oklahoma, Norman, OK (January 2021 -- July 2024)\n\n")

cat("\\textbf{Professor Emeritus}\\\\\n")
cat("Rutgers University, Camden, NJ (2018 -- Present)\n\n")

cat("\\textbf{Professor of Finance}\\\\\n")
cat("Estonian Business School, Tallinn, Estonia (September 2018 -- December 2020)\n\n")

cat("\\textbf{Visiting Professor}\\\\\n")
cat("Hanken School of Economics, Helsinki, Finland (September 2016 -- July 2020)\n\n")

cat("\\textbf{Visiting Research Professor}\\\\\n")
cat("Middlesex University, London, England (January 2015 -- December 2016)\n\n")

cat("\\textbf{Associate/Assistant Professor}\\\\\n")
cat("Rutgers University, Camden, NJ (July 1997 -- 2018)\n\n")
```

# SHORT-TERM ACADEMIC APPOINTMENTS

```{r short-term}
cat("\\textbf{Visiting Professor}, Estonian Business School, Tallinn, Estonia (October 2024 -- Present)\n\n")
cat("\\textbf{International Lecturer}, ZHAW Banking, Finance, Real Estate, Winterthur, Switzerland (July 2024 -- Present)\n\n")
cat("\\textbf{Visiting Professor}, Turku School of Economics, Turku, Finland (January -- February 2013)\n\n")
cat("\\textbf{Visiting Professor}, Lappeenranta University of Technology, Lappeenranta, Finland (January -- February 2007)\n\n")
```
EOF

echo -e "${GREEN}✓ Created jpbsQuartoCV_professional.qmd${NC}"

# Now render it
echo
echo -e "${BLUE}Rendering professional PDF...${NC}"

if quarto render jpbsQuartoCV_professional.qmd --to pdf; then
    if [ -f "jpbsQuartoCV_professional.pdf" ]; then
        mv jpbsQuartoCV_professional.pdf output/jpbCV_professional.pdf
        echo
        echo -e "${GREEN}✓✓✓ SUCCESS! Professional PDF generated!${NC}"
        echo -e "${GREEN}Location: output/jpbCV_professional.pdf${NC}"
        ls -lh output/jpbCV_professional.pdf
        
        # Try to open it
        xdg-open output/jpbCV_professional.pdf 2>/dev/null &
    fi
else
    echo -e "${YELLOW}Rendering encountered issues${NC}"
fi

echo
echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}Available CV Versions${NC}"
echo -e "${BOLD}================================================${NC}"
echo

for file in output/*.pdf; do
    if [ -f "$file" ]; then
        SIZE=$(du -h "$file" | cut -f1)
        NAME=$(basename "$file")
        case "$NAME" in
            "jpbCV_awesome.pdf")
                echo -e "  ${GREEN}✓${NC} Awesome-CV Template: $file ($SIZE)"
                echo "      Modern design with photo placeholder"
                ;;
            "jpbCV_professional.pdf")
                echo -e "  ${GREEN}✓${NC} Professional Template: $file ($SIZE)"
                echo "      Clean, traditional academic format"
                ;;
            "jpbsQuartoCV_simple.pdf")
                echo -e "  ${GREEN}✓${NC} Simple Version: $file ($SIZE)"
                echo "      Basic formatting"
                ;;
            *)
                echo -e "  ${GREEN}✓${NC} $file ($SIZE)"
                ;;
        esac
    fi
done

echo
echo -e "${GREEN}Done! Your CV is ready for administrator applications.${NC}"