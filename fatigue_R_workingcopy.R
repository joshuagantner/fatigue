# Peripheral fatigues detrimental effect on motor training - underlying mechanisms
# Author: Joshua Gantner
# eMail:  josh.gantner@gmail.com

# 0. SETUP
# set working directory
setwd('/Users/joshuagantner/Library/CloudStorage/OneDrive-UniversitätZürichUZH/Files/Studium/Masterarbeit/0 v9')
# load packages
library(lmerTest)
library(robustlmm)
library(dplyr)
# toggle verbosity
v_toggle = 0;

# 1. LOAD DATA
# read in data from csv table, as created by matlab data processing script
D <- read.csv("table_space5.csv")

# 2. PREPROCESS
# mark categorical variables
D$group <- as.factor(D$group)
D$identifier <- as.factor(D$identifier)
# ad a continuous variable for trials completed within a day 
# ... to serves as indicator for time passing/progression of training
D$training <- (D$block-1)*30+D$trial
D$training <- D$training*(1/120)*1 # scale to 1 day = +1
#D <- subset(D,D$distance<quantile(D$distance, c(.94)))

# 3. FIT 2-DAY-MODEL
modelFull <- rlmer(distance~group*day*training+(1+training|identifier), data=D, verbose=v_toggle)
# determine the satterthwaite approximation of degrees of freedom
m <- lmer(distance~group*day*training+(1+training|identifier), data=D)
dfs <- data.frame(coef(summary(m)))$df
# calculate p-values for the fixed effects of the robust model
coefs <- coef(summary(modelFull))
pvalues <- 2*pt(abs(coefs[,3]), dfs, lower=FALSE)
tableFull <- cbind(coefs,data.frame(pvalues))
tableFull

# 4. FIT TRAINING DAY FATIGUED COLLECTIVE MODEL
Dd1 <- subset(D,D$day==1)
Dd1 <- Dd1 %>% mutate(fatigued = ifelse(group == 1, 0, 1))
modelD1 <- rlmer(distance~fatigued*training+(1|identifier), data=Dd1, verbose=v_toggle)
# determine the satterthwaite approximation of degrees of freedom
m <- lmer(distance~fatigued*training+(1|identifier), data=Dd1)
dfs <- data.frame(coef(summary(m)))$df
# calculate p-values for the fixed effects of the robust model
coefs <- coef(summary(modelD1))
pvalues <- 2*pt(abs(coefs[,3]), dfs, lower=FALSE)
tableD1 <- cbind(coefs,data.frame(pvalues))
tableD1

# 5. FIT CONTROL DAY MODEL
Dd2 <- subset(D,D$day==2)
modelD2 <- rlmer(distance~group*training+(1|identifier), data=Dd2, verbose=v_toggle)
# determine the satterthwaite approximation of degrees of freedom
m <- lmer(distance~group*training+(1|identifier), data=Dd2)
dfs <- data.frame(coef(summary(m)))$df
# calculate p-values for the fixed effects of the robust model
coefs <- coef(summary(modelD2))
pvalues <- 2*pt(abs(coefs[,3]), dfs, lower=FALSE)
tableD2 <- cbind(coefs,data.frame(pvalues))
tableD2