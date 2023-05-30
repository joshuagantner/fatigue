# set working directory, load packages and toggle verbosity
getwd()
dir()
rm(list = ls())
setwd('/Users/joshuagantner/Library/CloudStorage/OneDrive-UniversitätZürichUZH/Files/Studium/Masterarbeit/0 v9')
library(lme4)
library(robustlmm)
v_toggle = 0;

# read in data from table
D <- read.csv("table_space5.csv")
D$group <- as.factor(D$group)
D$day <- as.factor(D$day)
D$identifier <- as.factor(D$identifier)

# ad a continuous variable for trials completed within a day. this serves as indicator for time passing/progression of training.
D$training <- (D$block-1)*30+D$trial
D$training <- D$training*(1/120)*4 # scaled to 1 session = +1, thereby a day with 4 sessions of 30 trials starts at 1/30 and ends at 4

# fit the full robust model determining the effect of group*day*training on distance
modelFull <- rlmer(distance~group*day*training+(1+training|identifier), data=D, verbose=v_toggle)
summary(modelFull)

# determine the satterthwaite approximation of degrees of freedom
m <- lmer(distance~group*day*training+(1+training|identifier), data=D)
dfs <- data.frame(coef(summary(m)))$df

# calculate p-values for the fixed effects of the robust model
coefs <- coef(summary(modelFull))
p.values <- 2*pt(abs(coefs[,3]), dfs, lower=FALSE)
p.values