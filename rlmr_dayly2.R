# Load the calc_variables dataset
calc_variables <- read.csv("/Users/joshuagantner/Library/CloudStorage/OneDrive-UniversitätZürichUZH/Files/Studium/Masterarbeit/calc_variables_v7.csv")
calc_variables$daily <- (calc_variables$session-1)*30+calc_variables$trial
calc_variables$daily2 <- calc_variables$daily*(1/120)*4

# Fit linear mixed-effects model
library(lme4)
library(robustlmm)

model <- rlmer(fdi.apb.adm.fcr.bic ~ group*day*daily + (1|subject/day) , data = calc_variables, verbose = 1)
summary(model)
