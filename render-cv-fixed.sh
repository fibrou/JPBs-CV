#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}→${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Header
echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}         CV Rendering Script${NC}"
echo -e "${BOLD}   Generating PDF and HTML versions${NC}"
echo -e "${BOLD}================================================${NC}"
echo

# Check if Quarto is installed
if ! command -v quarto &> /dev/null; then
    print_error "Quarto is not installed or not in PATH"
    echo "Please install Quarto from: https://quarto.org/docs/get-started/"
    exit 1
fi

# Check for required files
print_status "Checking required files..."

REQUIRED_FILES=(
    "jpbsQuartoCV_pdf.qmd"
    "jpbsQuartoCV_html.qmd"
    "jpbsCVdata/cv_data_with_education.xlsx"
)

MISSING_FILES=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        print_error "Missing file: $file"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

if [ $MISSING_FILES -gt 0 ]; then
    print_error "Missing $MISSING_FILES required file(s). Exiting."
    exit 1
fi

print_success "All required files found"
echo

# Create output directory if it doesn't exist
mkdir -p output

# Start timing
START_TIME=$(date +%s)

print_status "Starting CV rendering process..."
echo
echo -e "${BOLD}================================${NC}"

# Render PDF version
echo -e "${BOLD}Step 1/2: Generating PDF version${NC}"
echo -e "${BOLD}---------------------------------${NC}"
print_status "Rendering PDF version..."

if quarto render jpbsQuartoCV_pdf.qmd --to pdf 2>&1 | tee render_pdf.log | grep -q "ERROR"; then
    print_error "PDF rendering failed. Check render_pdf.log for details"
    tail -n 20 render_pdf.log
else
    print_success "PDF rendering completed"
    # Move PDF to output directory
    if [ -f "jpbsQuartoCV_pdf.pdf" ]; then
        mv jpbsQuartoCV_pdf.pdf output/jpbsQuartoCV.pdf
        print_success "PDF moved to output/jpbsQuartoCV.pdf"
    fi
fi

echo
echo -e "${BOLD}Step 2/2: Generating HTML version${NC}"
echo -e "${BOLD}----------------------------------${NC}"
print_status "Rendering HTML version..."

if quarto render jpbsQuartoCV_html.qmd --to html 2>&1 | tee render_html.log | grep -q "ERROR"; then
    print_error "HTML rendering failed. Check render_html.log for details"
    tail -n 20 render_html.log
else
    print_success "HTML rendering completed"
    # Move HTML to output directory
    if [ -f "jpbsQuartoCV_html.html" ]; then
        mv jpbsQuartoCV_html.html output/jpbsQuartoCV.html
        # Also move any supporting files
        if [ -d "jpbsQuartoCV_html_files" ]; then
            mv jpbsQuartoCV_html_files output/
        fi
        print_success "HTML moved to output/jpbsQuartoCV.html"
    fi
fi

# Calculate elapsed time
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo
echo -e "${BOLD}================================${NC}"
echo

# Check outputs
print_success "CV rendering complete!"
echo
echo "Generated files:"

if [ -f "output/jpbsQuartoCV.pdf" ]; then
    print_success "PDF: output/jpbsQuartoCV.pdf ($(du -h output/jpbsQuartoCV.pdf | cut -f1))"
else
    print_warning "PDF output not found"
fi

if [ -f "output/jpbsQuartoCV.html" ]; then
    print_success "HTML: output/jpbsQuartoCV.html ($(du -h output/jpbsQuartoCV.html | cut -f1))"
else
    print_warning "HTML output not found"
fi

echo
echo "Total time: ${ELAPSED} seconds"

echo
echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}Done! Your CV has been generated.${NC}"
echo -e "${BOLD}================================================${NC}"

# Optional: Open the files
if command -v xdg-open &> /dev/null; then
    echo
    read -p "Would you like to open the generated files? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "output/jpbsQuartoCV.pdf" ]; then
            xdg-open output/jpbsQuartoCV.pdf &
        fi
        if [ -f "output/jpbsQuartoCV.html" ]; then
            xdg-open output/jpbsQuartoCV.html &
        fi
    fi
fi