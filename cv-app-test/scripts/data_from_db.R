# data_from_db.R
# Drop-in replacement for jpbsCVdata.r
# Lives at: cv-app-test/scripts/data_from_db.R
# Reads all 27 CV tables from cv-app-test/cv.db and assigns them to the
# exact same variable names that jpbDataDrivenCV.Rmd expects.

library(DBI)
library(RSQLite)
library(here)

con <- dbConnect(SQLite(), here("cv-app-test", "cv.db"))
on.exit(dbDisconnect(con), add = TRUE)

# ── Employment & Appointments ──────────────────────────────────────────────────
admin          <- dbReadTable(con, "admin")
ltWork         <- dbReadTable(con, "lt_work")
stWork         <- dbReadTable(con, "st_work")

# ── Education & Credentials ────────────────────────────────────────────────────
edu            <- dbReadTable(con, "education")
certifications <- dbReadTable(con, "certifications")

# ── Recognition ───────────────────────────────────────────────────────────────
honorsGrants   <- dbReadTable(con, "honors_grants")

# ── Research Output ────────────────────────────────────────────────────────────
publications        <- dbReadTable(con, "publications")
pip                 <- dbReadTable(con, "papers_in_progress")
otherPubsMonos      <- dbReadTable(con, "other_pubs_monos")

# ── Conference Activity ────────────────────────────────────────────────────────
academicPresents    <- dbReadTable(con, "academic_presentations")
pedagogyPresents    <- dbReadTable(con, "pedagogy_presentations")
academicDiscussions <- dbReadTable(con, "academic_discussions")
confCommittees      <- dbReadTable(con, "conf_committees")
confChair           <- dbReadTable(con, "conf_chair")

# ── Service ───────────────────────────────────────────────────────────────────
editor              <- dbReadTable(con, "editor")
adHocReview         <- dbReadTable(con, "ad_hoc_review")
tAndP               <- dbReadTable(con, "t_and_p")
profesionalOFfices  <- dbReadTable(con, "professional_offices")
academicLeader      <- dbReadTable(con, "academic_leadership")
academicCommittees  <- dbReadTable(con, "academic_committees")

# ── Students ──────────────────────────────────────────────────────────────────
dissertationCommittees <- dbReadTable(con, "dissertation_committees")
thesesSupervision      <- dbReadTable(con, "theses_supervision")
studentMentoring       <- dbReadTable(con, "student_mentoring")

# ── Other ─────────────────────────────────────────────────────────────────────
profTraining    <- dbReadTable(con, "prof_training")
mediaInterviews <- dbReadTable(con, "media_interviews")
bizExperiences  <- dbReadTable(con, "biz_experiences")
references      <- dbReadTable(con, "references")
