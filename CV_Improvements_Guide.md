# CV Improvements and Working Papers Website Guide

## Overview

This guide explains the improvements made to your academic CV and provides instructions for creating a dynamic website featuring your curriculum vitae and working papers.

## Files Included

1.  **jpbsQuartoCV.qmd** - Updated main CV file with fixed PDF grouping
2.  **papers.qmd** - New working papers page with abstracts
3.  **CV_Improvements_Guide.md** - This guide

## Key Improvements Made

### 1. Fixed PDF Role Grouping

**Problem:** In the PDF output, administrative roles with the same title were appearing multiple times with separate headers instead of being grouped under one header with all accomplishments listed.

**Solution:** Modified the `admin-pdf` R code block (line 234) to properly group by institution and title only:

``` r
group_by(institution, title) %>%
  summarise(
    details = list(detail),
    display_order = first(display_order),
    .groups = 'drop'
  )
```

**Result:** Now both HTML and PDF versions group all accomplishments under a single job title heading.

**Example:** - **Before:** "Director of Online MS Finance Program" appeared 7 times - **After:** One heading with all 7 accomplishments listed as bullet points

### 2. Address Already Correct

Your address field correctly shows "Willis, Texas, USA" (line 6 in the QMD file).

### 3. Created Working Papers Page

A new `papers.qmd` file provides a dedicated page for your working papers with: - Paper titles - Author lists - Full abstracts - Status badges (Under Review, Working Paper, In Progress, Draft) - Keywords - Professional styling

## How to Use the Working Papers Page

### Option 1: Use Sample Data (Quick Start)

The papers.qmd file includes example papers. You can: 1. Replace the sample data with your actual papers 2. Edit directly in the R code block starting at line 29

### Option 2: Use Excel Data (Recommended for Multiple Papers)

Create a new sheet called `working_papers` in your `cv_data.xlsx` file with these columns:

| Column   | Description                   | Example                                    |
|----------|-------------------------------|--------------------------------------------|
| title    | Paper title                   | "Machine Learning in Portfolio Management" |
| authors  | Author names                  | "John Paul Broussard and Jane Doe"         |
| abstract | Full abstract (250-300 words) | "This paper examines..."                   |
| year     | Year                          | "2025"                                     |
| status   | Current status                | "Under Review"                             |
| keywords | Comma-separated keywords      | "Machine Learning, Finance, AI"            |

Then update the R code in papers.qmd to load from Excel:

``` r
source(here("jpbsCVdata", "load_cv_data.r"))
working_papers <- read_excel(here("jpbsCVdata", "cv_data.xlsx"), 
                             sheet = "working_papers")
```

## Rendering Your CV Website

### Basic Rendering

``` bash
# Render the main CV (creates HTML and PDF)
quarto render jpbsQuartoCV.qmd

# Render the working papers page
quarto render papers.qmd
```

### Create Complete Website

To create a fully integrated website:

1.  \*\*Create \_quarto.yml\*\* configuration file:

``` yaml
project:
  type: website
  output-dir: docs

website:
  title: "John Paul Broussard"
  navbar:
    left:
      - text: "CV"
        href: jpbsQuartoCV.html
      - text: "Working Papers"
        href: papers.html
    right:
      - icon: linkedin
        href: https://tinyurl.com/5bfex8hv
      - icon: envelope
        href: mailto:john.broussard@rutgers.edu

format:
  html:
    theme: cosmo
    css: custom-cv.scss
```

2.  **Render the entire site:**

``` bash
quarto render
```

3.  **Preview locally:**

``` bash
quarto preview
```

## Publishing Your Website

### Option 1: GitHub Pages (Free)

1.  Create a GitHub repository
2.  Push your files to the repository
3.  In repository settings, enable GitHub Pages from the `/docs` folder
4.  Your site will be live at `https://yourusername.github.io/repository-name`

### Option 2: Quarto Pub (Free)

``` bash
quarto publish quarto-pub
```

Follow the prompts to create an account and publish.

### Option 3: Netlify (Free)

1.  Create account at netlify.com
2.  Drag and drop your `docs` folder
3.  Get instant URL: `https://your-site-name.netlify.app`

### Option 4: Custom Domain

After publishing to any service above, you can connect a custom domain like: - `johnbroussard.com` - `broussard.finance`

## Marketing Your Administrative Experience

### Strengths to Emphasize

Based on your CV, here are your key marketable strengths for administrator positions:

#### 1. **Program Growth & Revenue Generation**

-   58% enrollment growth in MS Finance program
-   Managed program with 150 students and \>78% graduation rate
-   Developed marketing strategies with 3rd party providers

#### 2. **Strategic Leadership**

-   Assistant Director of 5th largest unit in OU system (1,050 majors)
-   Multi-year Finance Area Head at Rutgers
-   International program management (Estonian Business School)

#### 3. **Operational Excellence**

-   Streamlined admissions processes for faster decisions
-   Created flexible program structures for learner accessibility
-   Led curriculum restructuring initiatives

#### 4. **Stakeholder Engagement**

-   Worked with development office on 7-figure fundraising
-   Achieved CFA Institute University Affiliation status
-   Managed relationships with instructional design teams

#### 5. **Innovation & Technology**

-   Created first asynchronous program offering
-   Expert in AI/ML applications in finance
-   Data-driven decision making

### Recommended CV Customization for Admin Roles

When applying for administrative positions, consider creating role-specific versions:

**For Dean/Associate Dean Positions:** - Lead with enrollment growth and revenue metrics - Emphasize strategic planning and unit management - Highlight fundraising and external relations

**For Program Director Positions:** - Feature accreditation achievements (CFA affiliation) - Emphasize curriculum innovation - Highlight student success metrics (graduation rates)

**For Department Chair Positions:** - Focus on faculty recruitment and development - Emphasize budget management - Highlight unit growth and strategic initiatives

## Advanced Tips

### Adding Impact Metrics

In your Excel `admin` sheet, you can add an `impact` column to highlight quantitative achievements:

| title                                 | institution            | detail                          | impact                                   |
|---------------------------------------|------------------------|---------------------------------|------------------------------------------|
| Director of Online MS Finance Program | University of Oklahoma | Developed Marketing Strategy... | Increased enrollment by 58% over 3 years |

The CV will automatically display these as highlighted impact statements.

### Updating Publications

To add new publications, simply update the `publications` sheet in your Excel file. The CV automatically: - Counts total publications - Calculates recent output (since 2013) - Orders by year and featured status - Generates proper citations with DOI links

### Customizing the Design

The CV uses SCSS for styling. Key files: - **custom-cv.scss** - Controls colors, fonts, spacing - Modify colors by changing hex values - Adjust spacing by modifying rem values

### Creating PDF-Specific Content

You can create content that only appears in PDF or HTML:

``` r
# Only in HTML
if (knitr::is_html_output()) {
  cat("This appears only in HTML")
}

# Only in PDF
if (knitr::is_latex_output()) {
  cat("\\textbf{This appears only in PDF}")
}
```

## Troubleshooting

### PDF Not Rendering

1.  **Check XeLaTeX installation:**

    ``` bash
    xelatex --version
    ```

2.  **Install missing packages:**

    ``` bash
    tlmgr install awesome-cv fontawesome xelatex
    ```

3.  **Use simple PDF format** (add to YAML):

    ``` yaml
    format:
      pdf:
        pdf-engine: pdflatex
    ```

### HTML Styling Issues

1.  Ensure `custom-cv.scss` is in the same directory
2.  Check that Font Awesome CSS is loading
3.  Clear browser cache

### Grouping Not Working

Verify in your Excel file: - Same `title` and `institution` for items that should group - Same `display_order` keeps them together - No extra spaces in title or institution names

## Next Steps

1.  **Review the fixed CV** - Check that roles now group properly in PDF
2.  **Add your working papers** - Update papers.qmd with your actual research
3.  **Test rendering** - Run `quarto render` to generate files
4.  **Customize styling** - Adjust colors and layout to your preference
5.  **Publish online** - Choose a hosting option and make it live
6.  **Update regularly** - Keep your CV dynamic by updating as achievements occur

## Support Resources

-   **Quarto Documentation:** <https://quarto.org>
-   **CV Template Issues:** Contact via email
-   **Customization Help:** Review Quarto's HTML and PDF guides

## Summary of Changes

**Fixed:** ✅ PDF role grouping (line 234 in jpbsQuartoCV.qmd) ✅ Address field verified (Willis, Texas, USA)

**Created:** ✅ Working papers page (papers.qmd) ✅ Sample paper data with abstracts ✅ Professional styling for papers

**Maintained:** ✅ Beautiful HTML layout ✅ Professional PDF output ✅ Responsive design ✅ Icon integration

Your CV is now ready to help you market yourself as an accomplished teacher, researcher, and administrator!

------------------------------------------------------------------------

**Questions?** Email: [john.broussard\@rutgers.edu](mailto:john.broussard@rutgers.edu){.email}
