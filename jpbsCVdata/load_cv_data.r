# Function to load CV data from Excel file
load_cv_data <- function(filename) {
  
  library(readxl)
  library(dplyr)
  library(here)
  
  # Build the full path to the Excel file
  excel_path <- here("jpbsCVdata", filename)
  
  # If that doesn't exist, try in the current directory
  if (!file.exists(excel_path)) {
    excel_path <- here(filename)
  }
  
  # Check if file exists
  if (!file.exists(excel_path)) {
    stop(paste("Excel file not found:", excel_path))
  }
  
  # Get all sheet names
  sheet_names <- excel_sheets(excel_path)
  
  # Initialize list to store all data
  cv_data <- list()
  
  # Read each sheet
  for (sheet in sheet_names) {
    # Convert sheet name to lowercase for consistency
    data_name <- tolower(sheet)
    
    # Try to read the sheet
    tryCatch({
      cv_data[[data_name]] <- read_excel(excel_path, sheet = sheet)
      message(paste("Loaded sheet:", sheet))
    }, error = function(e) {
      message(paste("Could not read sheet:", sheet, "-", e$message))
      cv_data[[data_name]] <- NULL
    })
  }
  
  # Specific processing for different sheets
  
  # Admin data
  if ("admin" %in% names(cv_data)) {
    cv_data$admin <- cv_data$admin %>%
      mutate(
        highlight = ifelse(is.na(highlight), TRUE, highlight),
        display_order = ifelse(is.na(display_order), row_number(), display_order)
      )
  }
  
  # Employment data
  if ("employment" %in% names(cv_data)) {
    cv_data$employment <- cv_data$employment %>%
      mutate(
        current = ifelse(is.na(current), FALSE, current),
        display_order = ifelse(is.na(display_order), row_number(), display_order)
      )
  }
  
  # Education data
  if ("education" %in% names(cv_data)) {
    cv_data$education <- cv_data$education %>%
      mutate(
        highlight = ifelse(is.na(highlight), TRUE, highlight),
        display_order = ifelse(is.na(display_order), row_number(), display_order)
      )
  }
  
  # Certifications data
  if ("certifications" %in% names(cv_data)) {
    cv_data$certifications <- cv_data$certifications %>%
      mutate(
        highlight = ifelse(is.na(highlight), TRUE, highlight),
        year = as.integer(year)
      )
  }
  
  # Publications data
  if ("publications" %in% names(cv_data)) {
    cv_data$publications <- cv_data$publications %>%
      mutate(
        featured = ifelse(is.na(featured), FALSE, featured),
        year = as.integer(year)
      )
  }
  
  # Honors data
  if ("honors" %in% names(cv_data)) {
    cv_data$honors <- cv_data$honors %>%
      mutate(
        highlight = ifelse(is.na(highlight), TRUE, highlight),
        display_order = ifelse(is.na(display_order), row_number(), display_order),
        year = as.integer(year)
      )
  }
  
  # AboutMe data
  if ("aboutme" %in% names(cv_data)) {
    cv_data$aboutme <- cv_data$aboutme
  }
  
  # Other Publications data
  if ("otherpublications" %in% names(cv_data)) {
    cv_data$otherpublications <- cv_data$otherpublications %>%
      mutate(
        year = if("year" %in% names(.)) as.integer(year) else NA
      )
  }
  
  # Projects in Progress (pip) data
  if ("pip" %in% names(cv_data)) {
    cv_data$pip <- cv_data$pip
  }
  
  # Working Papers data
  if ("workingpapers" %in% names(cv_data)) {
    cv_data$workingpapers <- cv_data$workingpapers %>%
      mutate(
        year = if("year" %in% names(.)) as.integer(year) else NA
      )
  }
  
  # Service data
  if ("service" %in% names(cv_data)) {
    cv_data$service <- cv_data$service
  }
  
  # References data
  if ("references" %in% names(cv_data)) {
    cv_data$references <- cv_data$references
  }
  
  return(cv_data)
}