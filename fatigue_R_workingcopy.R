# set working directory, load the lme4 package and toggle verbosity
getwd()
dir()
rm(list = ls())
#setwd('/Users/joshuagantner/Library/CloudStorage/OneDrive-UniversitätZürichUZH/Files/Studium/Masterarbeit/0 v9/playground')
library(lme4)
library(lmerTest)
v_toggle = 0;

# read in data from table
D <- read.csv("/Users/joshuagantner/Library/CloudStorage/OneDrive-UniversitätZürichUZH/Files/Studium/Masterarbeit/0 v9/table_space5_deltas_cutoff98.csv")
D$group <- as.factor(D$group)
D$day <- as.factor(D$day)
D$identifier <- as.factor(D$identifier)

# 1. build full model
modelFull <- lmer(delta ~ group*day + (1|identifier), data=D, REML=F)
summary(modelFull)

# 2. anova for group effect
model0<-lmer(delta ~ day + (1|identifier), data=D, REML=F)
modelW<-lmer(delta ~ group*day + (1|identifier), data=D, REML=F)
r2<-anova(model0,modelW)
r2

# 3. anova for change over time 
# 3a  control group
Di<-subset(D,D$group==1)
Di$day <- as.numeric(Di$day)
Di$day <- Di$day-1
model0<-lmer(delta ~ 1 + (1|identifier), data=Di, REML=F)
modelW<-lmer(delta ~ day + (1|identifier), data=Di, REML=F)
r3a<-anova(model0,modelW)
r3a

# 3b  FSD group
Di<-subset(D,D$group==2)
model0<-lmer(delta ~ 1 + (1|identifier), data=Di, REML=F)
modelW<-lmer(delta ~ day + (1|identifier), data=Di, REML=F)
r3b<-anova(model0,modelW)
r3b

# 3c  FRD group
Di<-subset(D,D$group==3)
model0<-lmer(delta ~ 1 + (1|identifier), data=Di, REML=F)
modelW<-lmer(delta ~ day + (1|identifier), data=Di, REML=F)
r3c<-anova(model0,modelW)
r3c