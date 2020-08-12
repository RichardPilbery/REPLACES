library(tidyverse)
library(readxl)

df <- read_xlsx('data/REPLACES-results.xlsx') %>%
  filter(!is.na(`Submission Date`)) %>%
  select(-ID, -`No Label`) %>%
  mutate(
    id = row_number()
  ) %>%
  mutate_all(tolower)

questions <- colnames(df)
colnames(df) <- c("submission_date", "consent", "current_role", "freq_frontline_ops", "freq_falls", "percent_non_convey", "percent_falls_pathway", "percent_falls_gp", "pt_struggle_meds", "percent_pt_diff_meds", "risk_factors_meds_diff", "refer_cmr", "important_cmr_refer", "care_plan", "id")

df1 <- df %>%
  mutate(
    refer_cmr = ifelse(grepl("know", refer_cmr), "unsure", refer_cmr)
  )

glimpse(df1)

# Rows: 146
# Columns: 15
# $ submission_date        <chr> "2019-10-31 12:38:13", "2019-10-31 12:26...
# $ consent                <chr> "i have read the study information, and ...
# $ current_role           <chr> "paramedic", "locality manager", "parame...
# $ freq_frontline_ops     <chr> "full-time (37.5 hours a week)", "part-t...
# $ freq_falls             <chr> "more than once a shift", "once a month"...
# $ percent_non_convey     <chr> "50", "20", "80", "10", "60", "80", "0",...
# $ percent_falls_pathway  <chr> "50", "100", "60", "10", "60", "50", "10...
# $ percent_falls_gp       <chr> "20", "20", "60", "10", "100", "20", "10...
# $ pt_struggle_meds       <chr> "loads of boxes of medication that are o...
# $ percent_pt_diff_meds   <chr> "30", "0", "30", "10", "50", "30", "20",...
# $ risk_factors_meds_diff <chr> "1patient says they wish they could stop...
# $ refer_cmr              <chr> "yes and work in the leeds area", "no, b...
# $ important_cmr_refer    <chr> "very important", "important", "importan...
# $ care_plan              <chr> "referral to falls team\r\n\r\nfall patt...
# $ id                     <chr> "1", "2", "3", "4", "5", "6", "7", "8", ...

df1 %>% count(forcats::fct_lump(current_role, 9, other_level = "other"), sort = T)

# `forcats::fct_lump(current_role, 9, other_level = "other")`     n
# <fct>                                                       <int>
# 1 paramedic                                                      65
# 2 newly qualified paramedic                                      21
# 3 emergency care assistant                                       13
# 4 emergency medical technician (emt1, emt2, or similar)           9
# 5 clinical supervisor                                             8
# 6 eca                                                             8
# 7 advanced paramedic (e.g. ecp/ucp)                               7
# 8 specialist paramedic (e.g. paramedic practitioner)              6
# 9 other                                                           6
# 10 student paramedic                                              3

df1 %>% count(freq_frontline_ops)
df1 %>% count(freq_falls, sort = T)
df1 %>% count(percent_non_convey, sort = T)
df1 %>% count(percent_falls_pathway, sort = T)
df1 %>% count(percent_falls_gp, sort = T)
df1 %>% count(percent_pt_diff_meds, sort = T)
df1 %>% count(refer_cmr, sort = T)
df1 %>% count(important_cmr_refer, sort = T)

# Process risk factors list
x <- df1$risk_factors_meds_diff[137]
str_split(str_replace(x,"\\d+\\s?", ""), "\r\n\\d+\\s?", simplify = F)
