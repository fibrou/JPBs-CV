# Run once (or re-run to reset) to create cv.db from jpbsCVdata.r.
# Sources the original data file directly — no manual re-entry needed.

library(tibble)   # tribble()
library(DBI)
library(RSQLite)
library(here)

# Load all tribbles from the real data file
source(here("jpbsCVdata", "jpbsCVdata.r"))

db_path <- here("cv-app-test", "cv.db")
con <- dbConnect(SQLite(), db_path)

write_tbl <- function(con, name, df) {
  dbExecute(con, sprintf('DROP TABLE IF EXISTS "%s"', name))
  dbWriteTable(con, name, as.data.frame(df), row.names = FALSE)
  message("  wrote: ", name, " (", nrow(df), " rows)")
}

message("Seeding ", db_path, " ...")

write_tbl(con, "admin",                  admin)
write_tbl(con, "lt_work",               ltWork)
write_tbl(con, "st_work",               stWork)
write_tbl(con, "education",             edu)
write_tbl(con, "certifications",        certifications)
write_tbl(con, "honors_grants",         honorsGrants)
write_tbl(con, "publications",          publications)
write_tbl(con, "papers_in_progress",    pip)
write_tbl(con, "other_pubs_monos",      otherPubsMonos)
write_tbl(con, "academic_presentations",academicPresents)
write_tbl(con, "pedagogy_presentations",pedagogyPresents)
write_tbl(con, "academic_discussions",  academicDiscussions)
write_tbl(con, "conf_committees",       confCommittees)
write_tbl(con, "conf_chair",            confChair)
write_tbl(con, "editor",                editor)
write_tbl(con, "ad_hoc_review",         adHocReview)
write_tbl(con, "t_and_p",               tAndP)
write_tbl(con, "professional_offices",  profesionalOFfices)
write_tbl(con, "academic_leadership",   academicLeader)
write_tbl(con, "academic_committees",   academicCommittees)
write_tbl(con, "dissertation_committees", dissertationCommittees)
write_tbl(con, "theses_supervision",    thesesSupervision)
write_tbl(con, "student_mentoring",     studentMentoring)
write_tbl(con, "prof_training",         profTraining)
write_tbl(con, "media_interviews",      mediaInterviews)
write_tbl(con, "biz_experiences",       bizExperiences)
write_tbl(con, "references",            references)

dbDisconnect(con)
message("Done. cv.db is ready.")
