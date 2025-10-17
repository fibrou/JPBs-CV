# Load CV Data Function with better path handling
load_cv_data <- function(file_path = NULL) {
  library(readxl)
  library(dplyr)
  library(here)
  
  # If no path provided, look for the file
  if (is.null(file_path)) {
    possible_paths <- c(
      "cv_data_with_education.xlsx",
      "jpbsCVdata/cv_data_with_education.xlsx",
      here("jpbsCVdata", "cv_data_with_education.xlsx"),
      "cv_data.xlsx",
      "jpbsCVdata/cv_data.xlsx"
    )
    
    for (path in possible_paths) {
      if (file.exists(path)) {
        file_path <- path
        cat("Found data file at:", path, "\n")
        break
      }
    }
  }
  
  # Check if file exists at the provided or found path
  if (!file.exists(file_path)) {
    # Try without doubling the jpbsCVdata path
    alt_path <- gsub("jpbsCVdata/jpbsCVdata/", "jpbsCVdata/", file_path)
    if (file.exists(alt_path)) {
      file_path <- alt_path
    } else {
      stop(paste("File not found:", file_path, "\nPlease ensure cv_data.xlsx exists in jpbsCVdata/"))
    }
  }
  
  # Read all sheets
  sheets <- excel_sheets(file_path)
  cv_data <- list()
  
  for (sheet in sheets) {
    tryCatch({
      data <- read_excel(file_path, sheet = sheet)
      # Clean column names
      names(data) <- tolower(gsub(" ", "_", names(data)))
      cv_data[[tolower(sheet)]] <- data
      cat("Loaded sheet:", sheet, "with", nrow(data), "rows\n")
    }, error = function(e) {
      cat("Warning: Could not load sheet", sheet, ":", e$message, "\n")
    })
  }
  
  return(cv_data)
}
