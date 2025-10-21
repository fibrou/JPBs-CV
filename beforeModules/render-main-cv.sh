#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}     Rendering John Paul Broussard's CV${NC}"
echo -e "${BOLD}================================================${NC}"
echo

# Create output directory
mkdir -p output

# Start timer
START=$(date +%s)

# Main CV file
MAIN_CV="jpbsQuartoCV.qmd"

if [ ! -f "$MAIN_CV" ]; then
    echo -e "${RED}Error: $MAIN_CV not found${NC}"
    exit 1
fi

echo -e "${BLUE}Using main CV file: $MAIN_CV${NC}"
echo

# First, let's check what formats are defined in the YAML
echo -e "${YELLOW}Checking defined formats in $MAIN_CV...${NC}"
grep -A5 "^format:" $MAIN_CV | head -10
echo

# Render HTML version
echo -e "${BOLD}Step 1: Generating HTML version${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if quarto render $MAIN_CV --to html; then
    echo -e "${GREEN}✓ HTML rendered successfully${NC}"
    
    # Find and move HTML output
    HTML_OUTPUT="${MAIN_CV%.qmd}.html"
    if [ -f "$HTML_OUTPUT" ]; then
        mv "$HTML_OUTPUT" output/
        echo -e "${GREEN}✓ HTML moved to output/${NC}"
    fi
    
    # Move support files if they exist
    HTML_FILES="${MAIN_CV%.qmd}_files"
    if [ -d "$HTML_FILES" ]; then
        mv "$HTML_FILES" output/
        echo -e "${GREEN}✓ HTML support files moved to output/${NC}"
    fi
else
    echo -e "${YELLOW}⚠ HTML rendering encountered issues${NC}"
fi

echo

# Render PDF version
echo -e "${BOLD}Step 2: Generating PDF version${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check if LaTeX is available
if ! command -v xelatex &> /dev/null && ! command -v pdflatex &> /dev/null; then
    echo -e "${YELLOW}⚠ LaTeX not found. Installing TinyTeX...${NC}"
    quarto install tinytex
fi

if quarto render $MAIN_CV --to pdf; then
    echo -e "${GREEN}✓ PDF rendered successfully${NC}"
    
    # Find and move PDF output
    PDF_OUTPUT="${MAIN_CV%.qmd}.pdf"
    if [ -f "$PDF_OUTPUT" ]; then
        mv "$PDF_OUTPUT" output/
        echo -e "${GREEN}✓ PDF moved to output/${NC}"
    fi
else
    echo -e "${YELLOW}⚠ PDF rendering encountered issues${NC}"
    echo "Common issues:"
    echo "  1. Missing LaTeX packages - try: quarto install tinytex"
    echo "  2. Missing awesome-cv template files"
    echo "  3. Image path issues"
fi

echo

# Try other QMD files if main doesn't produce both outputs
if [ ! -f "output/jpbsQuartoCV.pdf" ] || [ ! -f "output/jpbsQuartoCV.html" ]; then
    echo -e "${YELLOW}Trying alternative QMD files...${NC}"
    
    # Try modular versions
    for qmd in jpbsCV_modular_pdf.qmd jpbsCV_modular_html.qmd; do
        if [ -f "$qmd" ]; then
            echo -e "${BLUE}Rendering $qmd...${NC}"
            quarto render "$qmd"
            
            # Move outputs
            OUTPUT_BASE="${qmd%.qmd}"
            [ -f "${OUTPUT_BASE}.pdf" ] && mv "${OUTPUT_BASE}.pdf" output/
            [ -f "${OUTPUT_BASE}.html" ] && mv "${OUTPUT_BASE}.html" output/
        fi
    done
fi

# Calculate elapsed time
END=$(date +%s)
ELAPSED=$((END - START))

# Final summary
echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}Rendering Complete - Summary${NC}"
echo -e "${BOLD}================================================${NC}"

echo -e "${BLUE}Output directory contents:${NC}"
ls -lh output/ 2>/dev/null || echo "No files in output directory"

echo
echo -e "${BLUE}Generated CV files:${NC}"

# Check for any PDF files
PDF_COUNT=$(find output -name "*.pdf" 2>/dev/null | wc -l)
if [ $PDF_COUNT -gt 0 ]; then
    find output -name "*.pdf" -exec echo -e "${GREEN}✓ PDF: {}"${NC} \;
else
    echo -e "${YELLOW}⚠ No PDF files generated${NC}"
fi

# Check for any HTML files
HTML_COUNT=$(find output -name "*.html" 2>/dev/null | wc -l)
if [ $HTML_COUNT -gt 0 ]; then
    find output -name "*.html" -exec echo -e "${GREEN}✓ HTML: {}"${NC} \;
else
    echo -e "${YELLOW}⚠ No HTML files generated${NC}"
fi

echo
echo "Time elapsed: ${ELAPSED} seconds"
echo -e "${BOLD}================================================${NC}"

# Open files if available
if [ $PDF_COUNT -gt 0 ] || [ $HTML_COUNT -gt 0 ]; then
    echo
    read -p "Open generated files? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Open PDFs
        find output -name "*.pdf" -exec xdg-open {} \; 2>/dev/null
        # Open HTMLs
        find output -name "*.html" -exec xdg-open {} \; 2>/dev/null
    fi
fi