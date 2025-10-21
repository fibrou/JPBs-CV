#!/bin/bash

# Colors
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}     CV File Organization Script${NC}"
echo -e "${BOLD}================================================${NC}"
echo

# Create organized structure
echo -e "${BLUE}Creating organized directory structure...${NC}"

# Create directories
mkdir -p archive
mkdir -p output
mkdir -p assets
mkdir -p jpbsQuartoCV_pdfFiles
mkdir -p jpbsQuartoCV_htmlFiles

echo -e "${GREEN}✓ Directories created${NC}"
echo

# Move image files
echo -e "${YELLOW}Moving image files to assets/...${NC}"
for img in *.jpg *.png *.jpeg *.gif 2>/dev/null; do
    if [ -f "$img" ]; then
        mv "$img" assets/
        echo "  Moved: $img → assets/"
    fi
done

# Archive old/test versions
echo -e "${YELLOW}Archiving old versions...${NC}"
for file in jpbsQuartoCV-FIXED*.qmd jpbsClean*.qmd 2>/dev/null; do
    if [ -f "$file" ]; then
        mv "$file" archive/
        echo "  Archived: $file"
    fi
done

# Move modular components
echo -e "${YELLOW}Organizing modular components...${NC}"
[ -f "_administrative.qmd" ] && mv "_administrative.qmd" jpbsQuartoCV_htmlFiles/
[ -f "_education.qmd" ] && mv "_education.qmd" jpbsQuartoCV_htmlFiles/
[ -f "pdf-admin-module.qmd" ] && mv "pdf-admin-module.qmd" jpbsQuartoCV_pdfFiles/
[ -f "pdf-orchestrator.qmd" ] && mv "pdf-orchestrator.qmd" jpbsQuartoCV_pdfFiles/

# Keep main files in root
echo -e "${YELLOW}Main files in root:${NC}"
ls -1 *.qmd 2>/dev/null | grep -E "^jpbs.*\.qmd$|^papers\.qmd$"

echo
echo -e "${BOLD}Current Structure:${NC}"
echo -e "${BLUE}📁 Root Directory${NC}"
echo "   ├── 📄 jpbsQuartoCV.qmd (main CV)"
echo "   ├── 📄 papers.qmd (working papers)"
echo "   ├── 📂 jpbsCVdata/ (data files)"
echo "   ├── 📂 assets/ (images)"
echo "   ├── 📂 output/ (generated files)"
echo "   ├── 📂 jpbsQuartoCV_pdfFiles/ (PDF modules)"
echo "   ├── 📂 jpbsQuartoCV_htmlFiles/ (HTML modules)"
echo "   └── 📂 archive/ (old versions)"

echo
echo -e "${GREEN}✓ Organization complete${NC}"

# Offer to create a README
echo
read -p "Create a README.md file? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cat > README.md << 'EOF'
# John Paul Broussard - Academic CV

## Structure

- `jpbsQuartoCV.qmd` - Main CV file (generates both HTML and PDF)
- `papers.qmd` - Working papers with abstracts
- `jpbsCVdata/` - Excel data files and R loading scripts
- `assets/` - Images and media files
- `output/` - Generated PDF and HTML files
- `render_main_cv.sh` - Script to build CV

## Building the CV

```bash
# Make script executable (first time only)
chmod +x render_main_cv.sh

# Build both PDF and HTML versions
./render_main_cv.sh
```

## Requirements

- R (with tidyverse, readxl, here, gt packages)
- Quarto
- LaTeX (for PDF generation) - install with `quarto install tinytex`

## Data Management

CV data is stored in `jpbsCVdata/cv_data_with_education.xlsx` with the following sheets:
- Administrative
- Employment
- Education
- Certifications
- Publications
- Honors
- Service

Edit the Excel file to update CV content.
EOF
    echo -e "${GREEN}✓ README.md created${NC}"
fi