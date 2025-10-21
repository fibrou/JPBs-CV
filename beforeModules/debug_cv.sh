#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== CV Build Diagnostic ===${NC}"
echo

# Check Quarto installation
echo -e "${YELLOW}1. Checking Quarto installation:${NC}"
if command -v quarto &> /dev/null; then
    echo -e "${GREEN}✓ Quarto found${NC}"
    quarto --version
else
    echo -e "${RED}✗ Quarto not found${NC}"
    echo "Install from: https://quarto.org/docs/get-started/"
fi
echo

# Check R installation
echo -e "${YELLOW}2. Checking R installation:${NC}"
if command -v R &> /dev/null; then
    echo -e "${GREEN}✓ R found${NC}"
    R --version | head -n 1
else
    echo -e "${RED}✗ R not found${NC}"
fi
echo

# Check current directory structure
echo -e "${YELLOW}3. Current directory structure:${NC}"
ls -la | grep -E "\.qmd$|\.Rmd$"
echo

# Check for data files
echo -e "${YELLOW}4. Checking data files:${NC}"
if [ -d "jpbsCVdata" ]; then
    echo -e "${GREEN}✓ jpbsCVdata directory found${NC}"
    ls -la jpbsCVdata/*.xlsx 2>/dev/null || echo "No Excel files found"
    ls -la jpbsCVdata/*.r 2>/dev/null || echo "No R files found"
else
    echo -e "${RED}✗ jpbsCVdata directory not found${NC}"
fi
echo

# Check which QMD files exist
echo -e "${YELLOW}5. Looking for QMD files:${NC}"
find . -name "*.qmd" -type f 2>/dev/null | head -20
echo

# Try a simple test render
echo -e "${YELLOW}6. Testing Quarto with a simple document:${NC}"
cat > test_quarto.qmd << 'EOF'
---
title: "Test Document"
format: html
---

## Testing Quarto

This is a test.
EOF

if quarto render test_quarto.qmd 2>&1 | tail -5; then
    echo -e "${GREEN}✓ Quarto rendering works${NC}"
    rm -f test_quarto.html test_quarto.qmd
else
    echo -e "${RED}✗ Quarto rendering failed${NC}"
fi
echo

echo -e "${BLUE}=== End Diagnostic ===${NC}"