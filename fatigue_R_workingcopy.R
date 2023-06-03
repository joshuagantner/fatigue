# Peripheral fatigues detrimental effect on motor training - underlying mechanisms
# Author: Joshua Gantner
# eMail:  josh.gantner@gmail.com

# 0. SETUP
# set working directory
setwd('/Users/joshuagantner/Library/CloudStorage/OneDrive-UniversitätZürichUZH/Files/Studium/Masterarbeit/0 v9')
# load packages
library(lmerTest)
library(robustlmm)
# toggle verbosity
v_toggle = 0;

# 1. LOAD DATA
# read in data from csv table, as created by matlab data processing script
D <- read.csv("table_space5_20230530_cutoff95.csv")

# 2. PREPROCESS
# mark categorical variables
D$group <- as.factor(D$group)
#D$day <- as.factor(D$day)
D$identifier <- as.factor(D$identifier)
# ad a continuous variable for trials completed within a day 
# ... to serves as indicator for time passing/progression of training
D$training <- (D$block-1)*30+D$trial
D$training <- D$training*(1/120)*1 # scale to 1 day = +1

# 3. FIT TRAINING-DAY-MODEL
Dd1 <- subset(D,D$day==1)
modelD1 <- rlmer(distance~group*training+(1|identifier), data=Dd1, verbose=v_toggle)
#summary(modelD1)
# determine the satterthwaite approximation of degrees of freedom
m <- lmer(distance~group*training+(1+training|identifier), data=Dd1)
dfs <- data.frame(coef(summary(m)))$df
# calculate p-values for the fixed effects of the robust model
coefs <- coef(summary(modelD1))
pvalues <- 2*pt(abs(coefs[,3]), dfs, lower=FALSE)
cbind(coefs,data.frame(pvalues))

# 4. FIT 2-DAY-MODEL
modelFull <- rlmer(distance~group*day*training+(1+training|identifier), data=D, verbose=v_toggle)
#summary(modelFull)
# determine the satterthwaite approximation of degrees of freedom
m <- lmer(distance~group*day*training+(1+training|identifier), data=D)
dfs <- data.frame(coef(summary(m)))$df
# calculate p-values for the fixed effects of the robust model
coefs <- coef(summary(modelFull))
pvalues <- 2*pt(abs(coefs[,3]), dfs, lower=FALSE)
cbind(coefs,data.frame(pvalues))