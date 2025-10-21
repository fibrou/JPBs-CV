#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}     Fixing Data Path Issues${NC}"
echo -e "${BOLD}================================================${NC}"
echo

# 1. Check the actual data structure
echo -e "${BLUE}1. Checking data directory structure...${NC}"
echo "Contents of jpbsCVdata/:"
ls -la jpbsCVdata/ | grep -E "\.xlsx|\.r"
echo

# 2. Fix the load_cv_data.r file if needed
echo -e "${BLUE}2. Fixing load_cv_data.r paths...${NC}"
if [ -f "jpbsCVdata/load_cv_data.r" ]; then
    # Create a backup
    cp jpbsCVdata/load_cv_data.r jpbsCVdata/load_cv_data.r.bak
    
    # Create a fixed version
    cat > jpbsCVdata/load_cv_data_fixed.r << 'EOF'
# Load CV Data Function with better path handling
load_cv_data <- function(file_path = NULL) {
  library(readxl)
  library(dplyr)
  library(here)
  
  # If no path provided, look for the file
  if (is.null(file_path)) {
    possible_paths <- c(
      "cv_data_with_education.xlsx",
      "jpbsCVdata/cv_data_with_education.xlsx",
      here("jpbsCVdata", "cv_data_with_education.xlsx"),
      "cv_data.xlsx",
      "jpbsCVdata/cv_data.xlsx"
    )
    
    for (path in possible_paths) {
      if (file.exists(path)) {
        file_path <- path
        cat("Found data file at:", path, "\n")
        break
      }
    }
  }
  
  # Check if file exists at the provided or found path
  if (!file.exists(file_path)) {
    # Try without doubling the jpbsCVdata path
    alt_path <- gsub("jpbsCVdata/jpbsCVdata/", "jpbsCVdata/", file_path)
    if (file.exists(alt_path)) {
      file_path <- alt_path
    } else {
      stop(paste("File not found:", file_path, "\nPlease ensure cv_data.xlsx exists in jpbsCVdata/"))
    }
  }
  
  # Read all sheets
  sheets <- excel_sheets(file_path)
  cv_data <- list()
  
  for (sheet in sheets) {
    tryCatch({
      data <- read_excel(file_path, sheet = sheet)
      # Clean column names
      names(data) <- tolower(gsub(" ", "_", names(data)))
      cv_data[[tolower(sheet)]] <- data
      cat("Loaded sheet:", sheet, "with", nrow(data), "rows\n")
    }, error = function(e) {
      cat("Warning: Could not load sheet", sheet, ":", e$message, "\n")
    })
  }
  
  return(cv_data)
}
EOF
    
    # Also update the original file to fix the path issue
    mv jpbsCVdata/load_cv_data.r jpbsCVdata/load_cv_data_original.r
    cp jpbsCVdata/load_cv_data_fixed.r jpbsCVdata/load_cv_data.r
    
    echo -e "${GREEN}✓ Fixed load_cv_data.r${NC}"
else
    echo -e "${YELLOW}⚠ load_cv_data.r not found${NC}"
fi

echo
# 3. Now try the main PDF render again
echo -e "${BLUE}3. Attempting main PDF render...${NC}"
echo -e "${YELLOW}Rendering jpbsQuartoCV.qmd to PDF...${NC}"

if quarto render jpbsQuartoCV.qmd --to pdf 2>&1 | tee render_pdf.log | tail -20; then
    if [ -f "jpbsQuartoCV.pdf" ]; then
        mv jpbsQuartoCV.pdf output/
        echo -e "${GREEN}✓ PDF successfully generated and moved to output/jpbsQuartoCV.pdf${NC}"
        ls -lh output/jpbsQuartoCV.pdf
    fi
else
    echo -e "${YELLOW}⚠ PDF rendering encountered issues${NC}"
    echo
    echo "Checking log for specific errors..."
    grep -i "error" render_pdf.log | head -5
fi

echo
# 4. If main PDF fails, try simple PDF again with fixed paths
if [ ! -f "output/jpbsQuartoCV.pdf" ]; then
    echo -e "${BLUE}4. Retrying simplified PDF with fixed paths...${NC}"
    
    # Update the simple PDF to use the fixed loader
    sed -i 's/load_cv_data("jpbsCVdata\/cv_data_with_education.xlsx")/load_cv_data()/' jpbsQuartoCV_simple_pdf.qmd
    
    if quarto render jpbsQuartoCV_simple_pdf.qmd --to pdf; then
        if [ -f "jpbsQuartoCV_simple_pdf.pdf" ]; then
            mv jpbsQuartoCV_simple_pdf.pdf output/jpbsQuartoCV_simple.pdf
            echo -e "${GREEN}✓ Simple PDF generated: output/jpbsQuartoCV_simple.pdf${NC}"
        fi
    fi
fi

echo
# 5. Summary
echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}Summary of Available Outputs:${NC}"
echo -e "${BOLD}================================================${NC}"
echo

echo -e "${BLUE}Files in output directory:${NC}"
ls -lh output/*.pdf output/*.html 2>/dev/null || echo "Check output directory"

echo
if [ -f "output/jpbsQuartoCV.html" ]; then
    echo -e "${GREEN}✓ HTML CV available at: output/jpbsQuartoCV.html${NC}"
fi

if [ -f "output/jpbsQuartoCV.pdf" ]; then
    echo -e "${GREEN}✓ Full PDF CV available at: output/jpbsQuartoCV.pdf${NC}"
elif [ -f "output/jpbsQuartoCV_simple.pdf" ]; then
    echo -e "${GREEN}✓ Simple PDF CV available at: output/jpbsQuartoCV_simple.pdf${NC}"
fi

echo
echo -e "${GREEN}✓ Data path fixes complete${NC}"