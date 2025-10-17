# LaTeX Helper Functions for PDF CV Generation

# Function to escape LaTeX special characters
escape_latex <- function(text) {
  if (is.na(text) || text == "") return(text)
  
  text <- gsub("\\\\", "\\\\textbackslash{}", text)
  text <- gsub("&", "\\\\&", text)
  text <- gsub("%", "\\\\%", text)
  text <- gsub("\\$", "\\\\$", text)
  text <- gsub("#", "\\\\#", text)
  text <- gsub("_", "\\\\_", text)
  text <- gsub("\\{", "\\\\{", text)
  text <- gsub("\\}", "\\\\}", text)
  text <- gsub("~", "\\\\textasciitilde{}", text)
  text <- gsub("\\^", "\\\\textasciicircum{}", text)
  
  return(text)
}

# Function to format date ranges for PDF
format_date_range_pdf <- function(start, end) {
  arrow <- " -- "
  if (is.na(start) || start == "") {
    return("")
  } else if (is.na(end) || end == "" || tolower(end) == "present") {
    return(paste0(start, arrow, "Present"))
  } else {
    return(paste0(start, arrow, end))
  }
}

# Function to create LaTeX section header
latex_section <- function(title) {
  cat("\\section{", escape_latex(title), "}\n\n", sep = "")
}

# Function to create LaTeX subsection
latex_subsection <- function(title) {
  cat("\\subsection{", escape_latex(title), "}\n\n", sep = "")
}

# Function to format a CV entry for LaTeX
latex_cv_entry <- function(title, organization, date_range = NULL, location = NULL) {
  cat("\\textbf{", escape_latex(title), "}", sep = "")
  
  if (!is.null(date_range) && date_range != "") {
    cat(" \\hfill ", escape_latex(date_range), sep = "")
  }
  cat("\n\n")
  
  cat("\\textit{", escape_latex(organization), "}", sep = "")
  
  if (!is.null(location) && location != "") {
    cat(", ", escape_latex(location), sep = "")
  }
  cat("\n\n")
}

# Function to create itemized list in LaTeX
latex_itemize <- function(items) {
  if (length(items) == 0) return()
  
  cat("\\begin{itemize}\n")
  for (item in items) {
    if (!is.na(item) && item != "") {
      cat("\\item ", escape_latex(item), "\n", sep = "")
    }
  }
  cat("\\end{itemize}\n\n")
}

# Function to add vertical space
latex_vspace <- function(space = "2mm") {
  cat("\\vspace{", space, "}\n\n", sep = "")
}

# Function to format publications for LaTeX
latex_publication <- function(title, authors, journal, year, doi = NULL) {
  cat("\\textbf{", escape_latex(title), "} (", year, ")\n\n", sep = "")
  cat("\\textit{", escape_latex(authors), "}\n\n", sep = "")
  cat(escape_latex(journal))
  
  if (!is.null(doi) && doi != "") {
    cat(" \\href{", doi, "}{[Link]}", sep = "")
  }
  cat("\n\n")
}

# Function to create a two-column layout for skills or similar
latex_two_column <- function(left_items, right_items) {
  cat("\\begin{minipage}[t]{0.48\\textwidth}\n")
  cat("\\begin{itemize}\n")
  for (item in left_items) {
    cat("\\item ", escape_latex(item), "\n", sep = "")
  }
  cat("\\end{itemize}\n")
  cat("\\end{minipage}\n")
  cat("\\hfill\n")
  cat("\\begin{minipage}[t]{0.48\\textwidth}\n")
  cat("\\begin{itemize}\n")
  for (item in right_items) {
    cat("\\item ", escape_latex(item), "\n", sep = "")
  }
  cat("\\end{itemize}\n")
  cat("\\end{minipage}\n\n")
}