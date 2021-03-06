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
    refer_cmr = ifelse(grepl("know", refer_cmr), "unsure", refer_cmr),
    non_convey = case_when(
      as.numeric(percent_non_convey) < 60 ~ "0-50%",
      as.numeric(percent_non_convey) >= 80 ~ "80-100%",
      TRUE ~ "60-70%"
    )
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

df1 %>%
  select(starts_with("percent")) %>%
  mutate_all(as.numeric) %>%
  pivot_longer(., cols = everything(), names_to="item", values_to = "percent") %>%
  ggplot(aes(x = percent, fill = item)) +
  scale_fill_viridis_d() +
  scale_x_continuous(name = "Percentage of cases", labels = seq(0, 100, 10), breaks = seq(0, 100, 10)) +
  geom_density(alpha = 0.4)

df1 %>%
  select(starts_with("percent")) %>%
  mutate_all(as.numeric) %>%
  pivot_longer(., cols = everything(), names_to="item", values_to = "percent") %>%
  count(item, percent) %>%
  ggplot(aes(x = percent, y = n, fill = item)) +
  #scale_fill_viridis_d() +
  scale_x_continuous(name = "Percentage of cases", labels = seq(0, 100, 10), breaks = seq(0, 100, 10)) +
  geom_area(alpha = 0.4, position="identity") +
  facet_wrap(~item)


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

df2 <- df1 %>% mutate(
  current_role = forcats::fct_lump(current_role, 9, other_level = "other")
)

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
y <- str_split(x, "\r\n\\s?", simplify = F)

processChoices <- function(x) {

  item <- strsplit(x, "(?<=[\\d+])\\s?", perl = T)
  print(item)

}

#map(y,processChoices)

# df1 %>% separate(col="risk_factors_meds_diff", into=c("number", "item"), sep="\\d+\\s?") %>% select(number, item)
#
# df1 %>% select(risk_factors_meds_diff) %>% map_df(.,processChoices)

rank_df <- df1 %>%
  # Split character vector into list and then put each row of the list on a new dataframe row
  unnest(y = str_split(risk_factors_meds_diff, "\r\n\\s?", simplify = F)) %>% select(id, y) %>%
  # Separate the number (rank) from the risk factor (item)
  separate(col="y", into=c("rank", "item"), sep = "(?<=[\\d+])\\s?") %>%
  filter(
    # Only going to look at top 5 since likely people got bored after
    # dragging and dropping 5 risk factors around the screen
    rank <= 5,
    # Rank 10 was split into 1 and 0. Not a problem since not including it, but it needs removing
    item != 0
  ) %>%
  mutate(
    item = str_replace(item, "\\r?\\s?\\d+", ""),
    item = ifelse(grepl("can", item), "patient cannot recall all their prescribed medicines", item)
  )

totals_df <- rank_df %>%
  count(item, rank) %>%
  group_by(item) %>%
  summarise(
    tot_n = sum(n),
    total = 5*first(n[rank == "1"], default = 0) + 4*first(n[rank == "2"], default = 0) + 3*first(n[rank == "3"], default = 0) + 2*first(n[rank == "4"], default = 0) + first(n[rank == "5"], default = 0)
  ) %>%
  arrange(desc(total))

rank_df %>%
  mutate(
    item = factor(item)
  ) %>%
  ggplot(aes(x = item, fill = rank)) +
  geom_bar()

# Check choices have been correctly extracted:
# df1 %>% filter(id == 22) %>% select(risk_factors_meds_diff) %>% pull(risk_factors_meds_diff)

# [1] "1 patient says they find it difficult to take their medicines\r\n2 patient says they are not taking medicines as prescribed\r\n3 carer says that patient not taking medicines as prescribed\r\n4 unused medicines around the home\r\n5 patient says they wish they could stop taking some of their medicines\r\n6 expired medicines in the home\r\n7 medicines kept in multiple places\r\n8 medicines kept in hard to reach locations\r\n9 patient says they have trouble taking their medicines on time\r\n10 patient can’t recall all their prescribed medicines"

# rank_df %>% filter(id == 22) %>% select(rank, item)
#
# # A tibble: 5 x 2
# rank  item
# <chr> <chr>
# 1 1     patient says they find it difficult to take their medicines
# 2 2     patient says they are not taking medicines as prescribed
# 3 3     carer says that patient not taking medicines as prescribed
# 4 4     unused medicines around the home
# 5 5     patient says they wish they could stop taking some of their medicines

library(tableone)

summary_table <- CreateTableOne(
  data = df2,
  vars = c("current_role", "freq_frontline_ops", "freq_falls", "important_cmr_refer"),
  strata = "refer_cmr",
  factorVars = c("current_role", "freq_frontline_ops", "freq_falls", "important_cmr_refer"),
  test = F,
  addOverall = T
)
kableone(summary_table)
