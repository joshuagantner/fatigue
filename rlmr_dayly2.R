# Load the calc_variables dataset
calc_variables <- read.csv("/Users/joshuagantner/Library/CloudStorage/OneDrive-UniversitätZürichUZH/Files/Studium/Masterarbeit/0 v9/table_space5.csv")
calc_variables$daily <- (calc_variables$block-1)*30+calc_variables$trial
calc_variables$daily <- calc_variables$daily*(1/120)*4
# as factor
calc_variables$group <- as.factor(calc_variables$group)
calc_variables$subject <- as.factor(calc_variables$subject)
calc_variables$day <- as.factor(calc_variables$day)

# Fit linear mixed-effects model
library(lme4)
library(robustlmm)

model <- rlmer(distance~group*day*daily+(1+daily|identifier), data = calc_variables, verbose = 1)
summary(model)
