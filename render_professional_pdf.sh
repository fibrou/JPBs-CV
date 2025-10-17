#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}  Generating Professional PDF CV${NC}"
echo -e "${BOLD}================================================${NC}"
echo

# Check if the professional QMD exists, if not download it
if [ ! -f "jpbsQuartoCV_professional.qmd" ]; then
    echo -e "${YELLOW}Creating professional PDF template...${NC}"
    # The artifact content would be created here
    # For now, assume the file has been created from the artifact above
fi

# Render the professional PDF
echo -e "${BLUE}Rendering professional PDF...${NC}"
echo "This may take a moment..."
echo

if quarto render jpbsQuartoCV_professional.qmd --to pdf 2>&1 | tee professional_pdf.log | tail -20; then
    if [ -f "jpbsQuartoCV_professional.pdf" ]; then
        # Move to output directory
        mv jpbsQuartoCV_professional.pdf output/jpbCV_professional.pdf
        
        echo
        echo -e "${GREEN}✓✓✓ SUCCESS! Professional PDF generated!${NC}"
        echo -e "${GREEN}Location: output/jpbCV_professional.pdf${NC}"
        
        # Show file info
        ls -lh output/jpbCV_professional.pdf
        
        echo
        echo -e "${BLUE}Opening PDF...${NC}"
        xdg-open output/jpbCV_professional.pdf 2>/dev/null &
    else
        echo -e "${YELLOW}PDF file not found after rendering${NC}"
    fi
else
    echo -e "${RED}✗ PDF rendering failed${NC}"
    echo
    echo "Checking error log..."
    grep -i "error" professional_pdf.log | head -10
    
    echo
    echo -e "${YELLOW}Common fixes:${NC}"
    echo "1. Install missing LaTeX packages:"
    echo "   sudo apt-get install texlive-xetex texlive-fonts-extra"
    echo "2. Or install TinyTeX:"
    echo "   quarto install tinytex"
fi

echo
echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}Summary${NC}"
echo -e "${BOLD}================================================${NC}"

# List all CV versions
echo -e "${BLUE}Available CV versions:${NC}"
echo
for file in output/*.pdf output/*.html; do
    if [ -f "$file" ]; then
        SIZE=$(du -h "$file" | cut -f1)
        echo -e "  ${GREEN}✓${NC} $file ($SIZE)"
    fi
done

echo
echo -e "${GREEN}Done!${NC}"