#!/bin/bash

# Script to clean up CV project directory by moving old files to beforeModules folder
# Keeps only the modular structure files and essential resources

echo "========================================"
echo "CV Project Cleanup - Moving to Modular Structure"
echo "========================================"

# Create the beforeModules directory if it doesn't exist
if [ ! -d "beforeModules" ]; then
    mkdir beforeModules
    echo "Created beforeModules directory"
else
    echo "beforeModules directory already exists"
fi

# Define files to KEEP in the main directory (everything else will be moved)
KEEP_FILES=(
    # Main modular files
    "jpbCV_main.qmd"
    "jpbCV_main.pdf"
    "jpbCV_main.tex"
    
    # Module files
    "admin_section.qmd"
    "education_section.qmd"
    "employment_section.qmd"
    "research_section.qmd"
    "references_section.qmd"
    "hero_section.qmd"
    "footer_section.qmd"
    
    # Essential resources
    "custom-cv.scss"
    "awesome-cv.tex"
    "awesome-cv.cls"
    "jaafGalaPic.jpg"
    
    # Data files and folders
    "cv_data_with_education.xlsx"
    "jpbsCVdata"
    
    # Other essential files
    "papers.qmd"
    ".gitignore"
    "README.md"
)

KEEP_DIRS=(
    "jpbsCVdata"
    "fonts"
    "img"
    "beforeModules"  # Don't move this into itself
)

# Function to check if file should be kept
should_keep() {
    local item=$1
    
    # Check if it's in the keep list
    for keep in "${KEEP_FILES[@]}"; do
        if [ "$item" == "$keep" ]; then
            return 0
        fi
    done
    
    # Check if it's a directory we should keep
    for dir in "${KEEP_DIRS[@]}"; do
        if [ "$item" == "$dir" ]; then
            return 0
        fi
    done
    
    return 1
}

# Move old CV variations
echo ""
echo "Moving old CV file variations..."
for file in jpbsQuartoCV*.qmd jpbsQuartoCV*.pdf jpbsQuartoCV*.html jpbsQuartoCV*.tex; do
    if [ -f "$file" ]; then
        # Skip the main jpbsQuartoCV.qmd if it exists
        if [ "$file" != "jpbsQuartoCV.qmd" ] || [ "$file" == "jpbsQuartoCV.qmd.bak" ]; then
            echo "  Moving: $file"
            mv "$file" beforeModules/ 2>/dev/null
        fi
    fi
done

# Move old modular attempts
echo ""
echo "Moving old modular attempts..."
for file in jpbsCV_modular*.qmd jpbsCleanQuarto*.* jpbsQuarto_professional*.qmd; do
    if [ -f "$file" ]; then
        echo "  Moving: $file"
        mv "$file" beforeModules/ 2>/dev/null
    fi
done

# Move administrative fragments
echo ""
echo "Moving administrative fragments..."
for file in _administrative*.qmd; do
    if [ -f "$file" ]; then
        echo "  Moving: $file"
        mv "$file" beforeModules/ 2>/dev/null
    fi
done

# Move old scripts
echo ""
echo "Moving old scripts..."
for script in *.sh; do
    if [ -f "$script" ] && [ "$script" != "cleanup_to_modules.sh" ]; then
        echo "  Moving: $script"
        mv "$script" beforeModules/ 2>/dev/null
    fi
done

# Move R scripts (except data loading scripts in jpbsCVdata)
echo ""
echo "Moving R scripts..."
for rscript in *.r *.R; do
    if [ -f "$rscript" ]; then
        echo "  Moving: $rscript"
        mv "$rscript" beforeModules/ 2>/dev/null
    fi
done

# Move old documentation
echo ""
echo "Moving old documentation..."
for doc in *_Guide.md *_README.md QUICK_START.md 00_START_HERE.md; do
    if [ -f "$doc" ] && [ "$doc" != "README.md" ]; then
        echo "  Moving: $doc"
        mv "$doc" beforeModules/ 2>/dev/null
    fi
done

# Move test and output directories
echo ""
echo "Moving test and output directories..."
for dir in test_quarto_files outputs output _output archive docs website html pdf; do
    if [ -d "$dir" ]; then
        echo "  Moving directory: $dir"
        mv "$dir" beforeModules/ 2>/dev/null
    fi
done

# Move file listing and logs
echo ""
echo "Moving logs and temporary files..."
for file in *.log fileListing.txt; do
    if [ -f "$file" ]; then
        echo "  Moving: $file"
        mv "$file" beforeModules/ 2>/dev/null
    fi
done

# Move old template files
echo ""
echo "Moving old template files..."
for file in awesome-cv-FIXED.cls jpbsQuartoCV.Rproj; do
    if [ -f "$file" ]; then
        echo "  Moving: $file"
        mv "$file" beforeModules/ 2>/dev/null
    fi
done

# Move generated file directories
echo ""
echo "Moving generated file directories..."
for dir in *_files; do
    if [ -d "$dir" ] && [ "$dir" != "jpbCV_main_files" ]; then
        echo "  Moving directory: $dir"
        mv "$dir" beforeModules/ 2>/dev/null
    fi
done

# Create a new clean README if needed
if [ ! -f "README.md" ]; then
    cat > README.md << 'EOF'
# John Paul Broussard - Modular CV System

## Current Structure

This CV uses a modular Quarto system with the following components:

### Main Files
- `jpbCV_main.qmd` - Main document that includes all modules
- `jpbCV_main.pdf` - Generated PDF output

### Module Files
- `admin_section.qmd` - Administrative leadership experience
- `education_section.qmd` - Education and certifications
- `employment_section.qmd` - Academic appointments
- `research_section.qmd` - Publications and research
- `references_section.qmd` - Professional references
- `hero_section.qmd` - Header/hero section for HTML
- `footer_section.qmd` - Footer with download links

### Data
- `cv_data_with_education.xlsx` - Excel file with all CV data
- `jpbsCVdata/` - Data loading scripts

### Styling
- `custom-cv.scss` - Custom styles for HTML output
- `awesome-cv.cls` - LaTeX class for PDF formatting
- `awesome-cv.tex` - LaTeX template

## To Build

```bash
# Generate PDF
quarto render jpbCV_main.qmd --to pdf

# Generate HTML
quarto render jpbCV_main.qmd --to html
```

## Old Files

Previous versions and test files have been moved to `beforeModules/` directory.
EOF
    echo "Created new README.md"
fi

echo ""
echo "========================================"
echo "Cleanup Complete!"
echo "========================================"
echo ""
echo "Kept in main directory:"
echo "  - Main CV file (jpbCV_main.qmd)"
echo "  - Module files (*_section.qmd)"
echo "  - Data files and jpbsCVdata folder"
echo "  - Essential resources (images, fonts, styles)"
echo ""
echo "Moved to beforeModules/:"
echo "  - Old CV variations"
echo "  - Test files"
echo "  - Scripts"
echo "  - Documentation"
echo "  - Output directories"
echo ""
echo "You can now run:"
echo "  quarto render jpbCV_main.qmd --to pdf"
