# Load the calc_variables dataset
calc_variables <- read.csv("/Users/joshuagantner/Library/CloudStorage/OneDrive-UniversitätZürichUZH/Files/Studium/Masterarbeit/calc_variables_v7.csv")
calc_variables$daily <- (calc_variables$session-1)*30+calc_variables$trial
calc_variables$daily <- calc_variables$daily*(1/120)*60
# as factor
calc_variables$group <- as.factor(calc_variables$group)
calc_variables$subject <- as.factor(calc_variables$subject)
calc_variables$day <- as.factor(calc_variables$day)

# Fit linear mixed-effects model
library(lme4)
library(robustlmm)

model <- rlmer(fdi.apb.adm.fcr.bic~factor(group)*factor(day)*daily+(-1+daily|subject), data = calc_variables, verbose = 1)
summary(model)