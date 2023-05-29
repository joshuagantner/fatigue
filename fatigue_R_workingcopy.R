# set working directory, load the lme4 package and toggle verbosity
getwd()
dir()
rm(list = ls())
#setwd('/Users/joshuagantner/Library/CloudStorage/OneDrive-UniversitätZürichUZH/Files/Studium/Masterarbeit/0 v9/playground')
library(lme4)
v_toggle = 0;

# read in data from table
D <- read.csv("/Users/joshuagantner/Library/CloudStorage/OneDrive-UniversitätZürichUZH/Files/Studium/Masterarbeit/0 v9/table_space5_deltas.csv")
D$group <- as.factor(D$group)
D$day <- as.factor(D$day)
D$identifier <- as.factor(D$identifier)

# 1. build full model
modelFull <- lmer(delta ~ group*day + (1|identifier), data=D)

# 2. look at changes in controls over weeks
...

# 3. look at changes in patients over weeks
Di<-subset(D,D$control==0)
week<-factor(Di$week)
SN<-factor(Di$SubjN)
y<-Di$sici_ratio

model0<-lmer(y~1 + (1|SN),REML=F)
summary(model0)
modelW<-lmer(y~1 + week + (1|SN),REML=F)
summary(modelW)
r3<-anova(model0,modelW)
r3
summary(r3)

