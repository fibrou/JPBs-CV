# CV Data Loader with Helper Functions
load_cv_data <- function(file_path = NULL) {
  library(readxl)
  library(dplyr)
  library(here)
  
  if (is.null(file_path)) {
    file_path <- here("cv_data", "cv_data_master.xlsx")
  }
  
  if (!file.exists(file_path)) {
    stop(paste("CV data file not found at:", file_path))
  }
  
  sheets <- excel_sheets(file_path)
  cv_data <- list()
  
  for (sheet in sheets) {
    tryCatch({
      data <- read_excel(file_path, sheet = sheet)
      names(data) <- tolower(gsub(" ", "_", names(data)))
      cv_data[[tolower(sheet)]] <- data
    }, error = function(e) {
      message(paste("Warning: Could not load sheet", sheet))
    })
  }
  
  return(cv_data)
}

escape_latex <- function(text) {
  if (is.na(text) || text == "") return("")
  text <- as.character(text)
  text <- gsub("&", "\\\\&", text)
  text <- gsub("%", "\\\\%", text)
  text <- gsub("\\$", "\\\\$", text)
  text <- gsub("#", "\\\\#", text)
  text <- gsub("_", "\\\\_", text)
  text <- gsub(">", "\\\\textgreater{}", text)
  text <- gsub("<", "\\\\textless{}", text)
  return(text)
}

format_date_range <- function(start, end) {
  start <- as.character(start)
  end <- as.character(end)
  
  if (is.na(start) || start == "") return("")
  if (is.na(end) || end == "" || tolower(end) == "present") {
    return(paste0(start, " -- Present"))
  }
  return(paste0(start, " -- ", end))
}
