# Load the calc_variables dataset
calc_variables <- read.csv("/Users/joshuagantner/Library/CloudStorage/OneDrive-UniversitätZürichUZH/Files/Studium/Masterarbeit/calc_variables_v7.csv")
calc_variables$daily <- (calc_variables$session-1)*30+calc_variables$trial

# Fit linear mixed-effects model
library(lme4)
library(robustlmm)
simple_model <- rlmer(fdi.apb.adm.fcr.bic ~ group*day + (1|subject), data = calc_variables)
summary(simple_model)
categorical_model <- rlmer(fdi.apb.adm.fcr.bic ~ factor(group)*factor(day) + (1|subject), data = calc_variables)
summary(categorical_model)
#robust_model <- rlmer(fdi.apb.adm.fcr.bic ~ factor(group) * factor(day) + (1+factor(group)*factor(subject)*factor(day)*factor(session)*factor(trial)|group/subject/day/session), data = calc_variables)
#robust_model <- rlmer(fdi.apb.adm.fcr.bic ~ factor(group) * factor(day) + (1 + day + session + trial | group/subject), data = calc_variables)
#complex_model <- rlmer(fdi.apb.adm.fcr.bic ~ factor(group)*factor(day) + (1+day|group/subject), data = calc_variables)

complex_model <- rlmer(fdi.apb.adm.fcr.bic ~ factor(group)*factor(day)*daily + (1+daily|subject/day) , data = calc_variables, verbose = 0)
summary(complex_model)

