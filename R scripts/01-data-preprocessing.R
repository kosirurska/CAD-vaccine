### SCRIPT 01

### PRE-PROCESSING AND CLEANING THE DATA FOR THE ANALYSES

library(tidyverse)
library(haven)
library(dplyr)

# Read in the raw data
leger_raw <- read_sas("data/leger1_7.sas7bdat") %>%
  select_all(tolower)

# Create a unique user ID (single digit)
leger_raw <- rowid_to_column(leger_raw)

# Subset the data needed for the analyses
leger_for_analysis <- leger_raw %>%
  filter(wave %in% c(6:7)) %>%
  select(rowid, date_part,
         prov, sex, age_yrs, recimp, medins, edu, ethn, hoinc, reven, area, # demographic factors
         emplstat_sq001:emplstat_sq008,
         concern_sq001:concern_sq005, 
         concern_sq008, concern_sq016, concern_sq017, concern_sq019, concern_sq020, # concerns
         impacvd_sq001:impacvd_sq003,impacvd_sq006, impacvd_sq020, # impacts
         hecond_sq001:hecond_sq011, # self-reported chronic conditions
         phyhe, menthe, wave, pond,
         cvdvacci, cvdvacc_v2, contrpos, vacboos, #vaccination questions
         contains("inflvac"), contains("inflvade"), contains("infvasec")) %>%
  mutate_at(vars(hecond_sq001, hecond_sq002, hecond_sq003, hecond_sq004,
                 hecond_sq005, hecond_sq006, hecond_sq007, hecond_sq008, 
                 hecond_sq009, hecond_sq010, hecond_sq011), ~ifelse(. == 2, 0, .)) %>% # recode into dummy with 1 and 0 for chronic conditions, easier for counting
  rowwise() %>%
  dplyr::mutate(ethnicity = case_when(ethn == 1 ~ 1, # recode ethnicity for fewer categories
                               ethn == 3 ~ 2, ## LATER realized there is no data on ethnicity
                               ethn == 4 ~ 3,
                               ethn == 6 ~ 4,
                               ethn == 7 ~ 5,
                               ethn == 2 | ethn == 5 | ethn == 8 | ethn == 9 | ethn == 10 | ethn == 11 ~ 6,
                               ethn == 12 | ethn == 13 | ethn == 14 ~ 7),
         employment = case_when(emplstat_sq001 == 1 ~ 1,
                                emplstat_sq002 == 1 ~ 2,
                                emplstat_sq003 == 1 ~ 3,
                                emplstat_sq004 == 1 ~ 4,
                                emplstat_sq005 == 1 ~ 5,
                                emplstat_sq006 == 1 ~ 6,
                                emplstat_sq007 == 1 ~ 7,
                                emplstat_sq008 == 1 ~ 8),
         hecond_immune = coalesce(hecond_sq010, hecond_sq011),
         chronic = sum(c(hecond_sq001, hecond_sq002, hecond_sq003, hecond_sq004, hecond_sq005, hecond_sq006, hecond_sq007, hecond_immune), na.rm = T),
         chronic_dummy = case_when(chronic == 0 ~ 0,
                                   chronic >= 1 ~ 1),
         chronic_multi = case_when(chronic == 0 | chronic == 1  ~ 0, # dummy variables for multiple chronic conditions (2 or more)
                                   chronic > 1 ~ 1),
         chronic_descriptive = case_when(hecond_sq001 == 1 ~ "Heart disease",
                                         hecond_sq002 == 1 ~ "Lung disease",
                                         hecond_sq003 == 1 ~ "Cancer",
                                         hecond_sq004 == 1 ~ "Hypertension",
                                         hecond_sq005 == 1 ~ "Diabetes",
                                         hecond_sq006 == 1 ~ "Obesity",
                                         hecond_sq007 == 1 ~ "Autoimmune",
                                         hecond_immune == 1 ~ "Other"),
         distress = sum(c(impacvd_sq001, impacvd_sq002, impacvd_sq003), na.rm = FALSE),
         depression = case_when(hecond_sq008 == 2 ~ 0,
                                hecond_sq008 == 1 ~ 1),
         anxiety = case_when(hecond_sq009 == 2 ~ 0,
                             hecond_sq009 == 1 ~ 1),
         comorbid_dep_anx = case_when(depression == 0 & anxiety == 0 ~ 0,
                                      depression == 1 & anxiety == 1 ~ 1),
         any_m_health = ifelse(depression == 1 | anxiety == 1, 1, 0)) %>%
  tidyr::replace_na(list(anxiety = 0, depression = 0, comorbid_dep_anx = 0, any_m_health = 0)) %>%
  dplyr::mutate(vaccine = factor(cvdvacci, 
                          levels = c(1:5), # relabel the vaccine status variable
                          labels = c("No",
                                     "Yes (partially)",
                                     "Yes (fully)",
                                     "Yes (fully)",
                                     "Pref. not to answer")),
         vaccine_dummy = case_when(cvdvacci == 1 ~ 0, # create a vaccine dummy yes or no for binary log.
                                   cvdvacci != 1 ~ 1),
         inf1 = coalesce(inflvac_sq001, inflvade_sq001, infvasec_sq001), #coalesce the vaccine motivations
         inf2 = coalesce(inflvac_sq002, inflvade_sq002, infvasec_sq002),
         inf3 = coalesce(inflvac_sq003, inflvade_sq003, infvasec_sq003),
         inf4 = coalesce(inflvac_sq004, inflvade_sq004, infvasec_sq004),
         inf5 = coalesce(inflvac_sq005, inflvade_sq005, infvasec_sq005),
         inf6 = coalesce(inflvac_sq006, inflvade_sq006, infvasec_sq006),
         inf7 = coalesce(inflvac_sq007, inflvade_sq007, infvasec_sq007),
         inf10 = coalesce(inflvac_sq010, inflvade_sq010, infvasec_sq010),
         inf11 = coalesce(inflvac_sq011, inflvade_sq011, infvasec_sq011),
         inf12 = coalesce(inflvac_sq012, inflvade_sq012, infvasec_sq012),
         inf13 = coalesce(inflvac_sq013, inflvade_sq013, infvasec_sq013),
         inf14 = coalesce(inflvac_sq014, inflvade_sq014, infvasec_sq014),
         inf15 = coalesce(inflvac_sq015, inflvade_sq015),
         inf16 = coalesce(inflvac_sq016, inflvade_sq016, infvasec_sq016),
         inf17 = coalesce(inflvac_sq017, inflvade_sq017, infvasec_sq017),
         inf18 = coalesce(inflvac_sq018, inflvade_sq018),
         booster = factor(vacboos, 
                          levels = c(1:5), #vaccine booster question
                          labels = c("Extremely likely",
                                     "Somewhat likely",
                                     "Somewhat unlikely",
                                     "Extremely unlikely",
                                     "Pref. not to answer"),
                          ordered = TRUE),
         booster_dummy = case_when(vacboos == 1 | vacboos == 2 ~ "Likely",
                                   vacboos == 3 |vacboos == 4 | vacboos == 5 ~ "Unlikely"),
         sex = factor(sex, levels = c(1:4),
                      labels = c("Male", "Female", "Other", "Prefer not to answer")),
         area = factor(area, levels = c(1:4),
                       labels = c("Rural", "Suburban", "Urban", "Prefer not to answer")),
         hoinc = factor(hoinc, 
                        levels = c(1:4),
                        labels = c("Bottom 3rd", "Middle 3rd", "Top 3rd", "Prefer not to answer")),
         province_full = factor(prov, 
                                levels = c(1:10), 
                                labels = c("British Columbia", "Alberta", "Saskatchewan", 
                                           "Manitoba", "Ontario", "Quebec", "New Brunswick", 
                                           "Nova Scotia", "Prince Edward Island", "Newfoundland")),
         province = as.factor(case_when(prov <= 4 ~ "West",
                                        prov == 5 | prov == 6 ~ "Central",
                                        prov > 6 ~ "East")),
         edu = factor(edu, 
                      levels = c(1:6),
                      labels = c("Primary", "Secondary", "College", "Graduate", "Never been" ,"Prefer not to answer"))) %>%
  dplyr::mutate(distress_rev = 13-distress) %>%
  dplyr::mutate(distress_rev = distress_rev + 2)

# ADDED - replace incorrect values for age with NA for more accurate analyses, 3 cases are erroneous
leger_for_analysis[leger_for_analysis==559] <- NA 
leger_for_analysis[leger_for_analysis==333] <- NA 
leger_for_analysis[leger_for_analysis==205] <- NA 

# Save the new data file for the analyses

write_csv(leger_for_analysis, "data/leger_for_analyses.csv")
  