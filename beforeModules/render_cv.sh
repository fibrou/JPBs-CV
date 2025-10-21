#!/bin/bash

# CV Render Script - Generates both PDF and HTML versions
# Author: John Paul Broussard CV System
# Usage: ./render_cv.sh

echo "================================================"
echo "     CV Rendering Script"
echo "     Generating PDF and HTML versions"
echo "================================================"
echo ""

# Set color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if command succeeded
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 completed successfully${NC}"
    else
        echo -e "${RED}✗ $1 failed${NC}"
        exit 1
    fi
}

# Function to render with progress indicator
render_with_progress() {
    local file=$1
    local format=$2
    echo -e "${YELLOW}→ Rendering $format version...${NC}"
    quarto render "$file" 2>&1 | while read line; do
        if [[ $line == *"Output created"* ]]; then
            echo "  $line"
        elif [[ $line == *"Error"* ]]; then
            echo -e "${RED}  $line${NC}"
        fi
    done
    check_status "$format rendering"
}

# Check if quarto is installed
if ! command -v quarto &> /dev/null; then
    echo -e "${RED}Error: Quarto is not installed or not in PATH${NC}"
    echo "Please install Quarto from https://quarto.org/docs/get-started/"
    exit 1
fi

# Check if required files exist
echo "Checking required files..."
if [ ! -f "jpbsCV_modular_pdf.qmd" ]; then
    echo -e "${RED}Error: jpbsCV_modular_pdf.qmd not found${NC}"
    exit 1
fi

if [ ! -f "jpbsCV_modular_html.qmd" ]; then
    echo -e "${RED}Error: jpbsCV_modular_html.qmd not found${NC}"
    exit 1
fi

if [ ! -f "jpbsCVdata/cv_data_with_education.xlsx" ]; then
    echo -e "${RED}Error: Data file cv_data_with_education.xlsx not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All required files found${NC}"
echo ""

# Start rendering
echo "Starting CV rendering process..."
echo "================================"
START_TIME=$(date +%s)

# Render PDF version
echo ""
echo "Step 1/2: Generating PDF version"
echo "---------------------------------"
render_with_progress "jpbsCV_modular_pdf.qmd" "PDF"

# Render HTML version
echo ""
echo "Step 2/2: Generating HTML version"
echo "----------------------------------"
render_with_progress "jpbsCV_modular_html.qmd" "HTML"

# Calculate elapsed time
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo ""
echo "================================"
echo -e "${GREEN}✓ CV rendering complete!${NC}"
echo ""
echo "Generated files:"

# Check for output files and display their info
if [ -f "jpbsCV_modular_pdf.pdf" ]; then
    SIZE=$(ls -lh jpbsCV_modular_pdf.pdf | awk '{print $5}')
    echo -e "  ${GREEN}→${NC} PDF:  jpbsCV_modular_pdf.pdf  (${SIZE})"
else
    echo -e "  ${RED}✗${NC} PDF output not found"
fi

if [ -f "jpbsCV_modular_html.html" ]; then
    SIZE=$(ls -lh jpbsCV_modular_html.html | awk '{print $5}')
    echo -e "  ${GREEN}→${NC} HTML: jpbsCV_modular_html.html (${SIZE})"
else
    echo -e "  ${RED}✗${NC} HTML output not found"
fi

echo ""
echo "Total time: ${ELAPSED} seconds"
echo ""

# Optional: Open the files automatically (uncomment if desired)
# echo "Opening generated files..."
# if [ -f "jpbsCV_modular_pdf.pdf" ]; then
#     xdg-open jpbsCV_modular_pdf.pdf 2>/dev/null || open jpbsCV_modular_pdf.pdf 2>/dev/null
# fi
# if [ -f "jpbsCV_modular_html.html" ]; then
#     xdg-open jpbsCV_modular_html.html 2>/dev/null || open jpbsCV_modular_html.html 2>/dev/null
# fi

echo "================================================"
echo "Done! Your CV has been generated in both formats."
echo "================================================"