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

# Move image files (fixed syntax)
echo -e "${YELLOW}Moving image files to assets/...${NC}"
for img in *.jpg *.png *.jpeg *.gif; do
    if [ -f "$img" ]; then
        # Keep a copy in root for LaTeX compatibility
        cp "$img" assets/
        echo "  Copied: $img → assets/"
    fi
done 2>/dev/null

# Archive old/test versions
echo -e "${YELLOW}Archiving old versions...${NC}"
for file in jpbsQuartoCV-FIXED*.qmd jpbsClean*.qmd; do
    if [ -f "$file" ]; then
        mv "$file" archive/
        echo "  Archived: $file"
    fi
done 2>/dev/null

# Move modular components if they exist
echo -e "${YELLOW}Organizing modular components...${NC}"
[ -f "_administrative.qmd" ] && mv "_administrative.qmd" jpbsQuartoCV_htmlFiles/ && echo "  Moved _administrative.qmd"
[ -f "_education.qmd" ] && mv "_education.qmd" jpbsQuartoCV_htmlFiles/ && echo "  Moved _education.qmd"

# Fix the modular files to point to correct includes
if [ -f "jpbsCV_modular_pdf.qmd" ]; then
    echo -e "${YELLOW}Fixing jpbsCV_modular_pdf.qmd include paths...${NC}"
    # Create the expected include files
    cat > _administrative_pdf.qmd << 'EOF'
## Administrative Experience

```{r}
#| label: admin-pdf
#| output: asis

# Administrative section for PDF
if (exists("admin") && nrow(admin) > 0) {
  admin_filtered <- admin %>%
    filter(!is.na(title)) %>%
    arrange(desc(as.numeric(gsub("-.*", "", start_date))))
  
  for (i in 1:min(nrow(admin_filtered), 5)) {
    cat("**", admin_filtered$title[i], "**\n\n", sep = "")
    cat("*", admin_filtered$institution[i], "*\n\n", sep = "")
    if (!is.na(admin_filtered$detail[i])) {
      cat("- ", admin_filtered$detail[i], "\n\n", sep = "")
    }
  }
}
```
EOF
    echo "  Created _administrative_pdf.qmd"
fi

if [ -f "jpbsCV_modular_html.qmd" ]; then
    echo -e "${YELLOW}Fixing jpbsCV_modular_html.qmd include paths...${NC}"
    # Create the expected include files
    cat > _administrative_html.qmd << 'EOF'
## Administrative Leadership

```{r}
#| label: admin-html
#| output: asis

# Administrative section for HTML
if (exists("admin") && nrow(admin) > 0) {
  cat('<div class="admin-section">\n')
  
  admin_filtered <- admin %>%
    filter(!is.na(title)) %>%
    arrange(desc(as.numeric(gsub("-.*", "", start_date))))
  
  for (i in 1:min(nrow(admin_filtered), 5)) {
    cat('<div class="admin-role">\n')
    cat('<h3>', admin_filtered$title[i], '</h3>\n')
    cat('<p class="institution">', admin_filtered$institution[i], '</p>\n')
    if (!is.na(admin_filtered$detail[i])) {
      cat('<ul><li>', admin_filtered$detail[i], '</li></ul>\n')
    }
    cat('</div>\n')
  }
  
  cat('</div>\n')
}
```
EOF
    echo "  Created _administrative_html.qmd"
fi

# Keep main files in root
echo
echo -e "${YELLOW}Main files in root:${NC}"
ls -1 *.qmd 2>/dev/null | grep -v "^_" | head -10

echo
echo -e "${BOLD}Current Structure:${NC}"
echo -e "${BLUE}📁 Root Directory${NC}"
echo "   ├── 📄 jpbsQuartoCV.qmd (main CV)"
echo "   ├── 📄 papers.qmd (working papers)"
echo "   ├── 🖼️ jaafGalaPic.jpg (profile photo)"
echo "   ├── 📂 jpbsCVdata/ (data files)"
echo "   ├── 📂 assets/ (images backup)"
echo "   ├── 📂 output/ (generated files)"
echo "   ├── 📂 jpbsQuartoCV_pdfFiles/ (PDF modules)"
echo "   ├── 📂 jpbsQuartoCV_htmlFiles/ (HTML modules)"
echo "   └── 📂 archive/ (old versions)"

echo
echo -e "${GREEN}✓ Organization complete${NC}"