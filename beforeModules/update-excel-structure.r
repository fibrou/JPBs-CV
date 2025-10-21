# Script to add AboutMe sheet to existing Excel file
# Run this in R to update your Excel file structure

library(readxl)
library(openxlsx)

# Path to your Excel file
excel_path <- "jpbsCVdata/cv_data_with_education.xlsx"
output_path <- "jpbsCVdata/cv_data_with_aboutme.xlsx"

# Read existing sheets
existing_sheets <- excel_sheets(excel_path)
wb <- loadWorkbook(excel_path)

# Create AboutMe data
aboutme_data <- data.frame(
  section = c(
    "full_about",
    "short_about",
    "tagline",
    "leadership_philosophy",
    "email",
    "website",
    "linkedin",
    "orcid",
    "location",
    "phone"
  ),
  content = c(
    "I am a Finance Professor with over 25 years of extensive domestic and international experience in online and traditional academic program management. I create academic programs and courses that monetize academic effort and yield institutional revenue enhancement and stakeholder success. I maintain real-world relevance through being a Financial Professional Designation Exam Trainer, Financial Risk Management Specialist, Financial Market Consultant, Expert on Big Data, Implementer of Natural Language Processing, Artificial Intelligence and Machine Learning applications in Finance.",
    
    "Finance Professor with 25+ years of experience in academic program management, specializing in online education, enrollment growth, and revenue generation.",
    
    "Finance Professor with Decades of Superior Administrative, Research, and Teaching Experiences",
    
    "I build programs that serve students, faculty, and institutions simultaneously—creating sustainable growth through strategic vision, operational excellence, and authentic stakeholder engagement.",
    
    "john.broussard@rutgers.edu",
    "tinyurl.com/c3wdneyp",
    "tinyurl.com/5bfex8hv",
    "0000-0002-5090-9947",
    "Oklahoma City, Oklahoma, USA",
    ""  # Phone number - leave empty if not desired
  ),
  active = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE),
  stringsAsFactors = FALSE
)

# Add AboutMe sheet if it doesn't exist
if (!"AboutMe" %in% names(wb)) {
  addWorksheet(wb, "AboutMe")
}

# Write the data
writeData(wb, "AboutMe", aboutme_data)

# Style the sheet
headerStyle <- createStyle(
  fontSize = 12,
  fontColour = "#FFFFFF",
  bgFill = "#2c5f7c",
  halign = "center",
  valign = "center",
  textDecoration = "bold"
)

addStyle(wb, "AboutMe", headerStyle, rows = 1, cols = 1:3, gridExpand = TRUE)
setColWidths(wb, "AboutMe", cols = 1, widths = 25)
setColWidths(wb, "AboutMe", cols = 2, widths = 120)
setColWidths(wb, "AboutMe", cols = 3, widths = 10)

# Save the workbook
saveWorkbook(wb, output_path, overwrite = TRUE)

cat("✓ Excel file updated with AboutMe sheet!\n")
cat("  New file: ", output_path, "\n")
cat("\nAboutMe sections added:\n")
for (i in 1:nrow(aboutme_data)) {
  cat("  - ", aboutme_data$section[i], "\n")
}

cat("\nYou can now edit these values directly in Excel:\n")
cat("  1. Open ", output_path, "\n")
cat("  2. Go to the 'AboutMe' sheet\n")
cat("  3. Edit the 'content' column for any section\n")
cat("  4. Set 'active' to FALSE to hide any section\n")