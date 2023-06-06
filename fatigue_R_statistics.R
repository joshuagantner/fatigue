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
v_toggle = 0 # toggle verbosity

# 1. LOAD VARIABILITY DATA
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

# 6. MODEL SKILL DATA
# read in data from csv table, as created by matlab data processing script
Dskill <- read.csv("table_skill.csv")
# mark categorical variables
Dskill$group <- as.factor(Dskill$group)
Dskill$ID <- as.factor(Dskill$ID)

# fit 2-day-model
modelSkill <- lmer(skillp~group*day*BN+(1|ID), data=Dskill)
tableSkill <- coef(summary(modelSkill))
tableSkill

# fit training-day-model
DskillD1 <- subset(Dskill,Dskill$day==1)
modelSkillD1 <- lmer(skillp~group*BN+(1|ID), data=DskillD1)
tableSkillD1 <- coef(summary(modelSkillD1))
tableSkillD1

# fit control-day-model
DskillD2 <- subset(Dskill,Dskill$day==2)
modelSkillD2 <- lmer(skillp~group*BN+(1|ID), data=DskillD2)
tableSkillD2 <- coef(summary(modelSkillD2))
tableSkillD2

# 7. CORRELATION OF VARIABILITY AND LEARNING
# create combined variability-skill table
Dvs <- Dskill
Dvs$variability <- NA
for (i in 1:nrow(Dvs)) {
  row_values <- Dvs[i, ]
  distances <- subset(D$distance, 
                      D$identifier==row_values$ID &
                      D$day==row_values$day &
                      D$block==row_values$BN)
  Dvs[i,'variability'] <- median(distances)
}
Dvs <- na.omit(Dvs)

# correlations variability // skill
correlations <- data.frame(
  group = c(1,1,2,2,3,3),
  day = c(1,2,1,2,1,2),
  r = c(NaN,NaN,NaN,NaN,NaN,NaN),
  p = c(NaN,NaN,NaN,NaN,NaN,NaN)
)
for (i in 1:3) { # group level
  for (j in 1:2) { # day level
    Dvs_ij <- subset(Dvs, group == i & day == j)
    foo <- cor.test(Dvs_ij$skillp, Dvs_ij$variability,method = "spearman")
    correlations[correlations$group==i & correlations$day == j, ]$r <- foo$estimate
    correlations[correlations$group==i & correlations$day == j, ]$p <- foo$p.value
  }
}
correlations

# correlations variability change // learning
Ddelta <- Dvs %>% #create delta table
  arrange(ID, day) %>%
  group_by(ID) %>%
  mutate(
    delta_skillp = skillp - lag(skillp),
    delta_variability = variability - lag(variability)
  ) %>%
  ungroup()
Ddelta <- Ddelta %>%
  select(ID, day, BN, delta_skillp = delta_skillp, group, delta_variability = delta_variability)
Ddelta <- na.omit(Ddelta)

correlations_delta <- data.frame(
  group = c(1,1,2,2,3,3),
  day = c(1,2,1,2,1,2),
  r = c(NaN,NaN,NaN,NaN,NaN,NaN),
  p = c(NaN,NaN,NaN,NaN,NaN,NaN)
)

for (i in 1:3) { # group level
  for (j in 1:2) { # day level
    Ddelta_ij <- subset(Ddelta, group == i & day == j)
    foo <- cor.test(Ddelta_ij$delta_skillp, Ddelta_ij$delta_variability,method = "pearson")
    correlations[correlations$group==i & correlations$day == j, ]$r <- foo$estimate
    correlations[correlations$group==i & correlations$day == j, ]$p <- foo$p.value
  }
}
correlations

# 8. SHAPE OF VARIABILITY
# kurtosis
DshapeK <- read.csv("table_kurtosis_space5.csv") # load data
DshapeK$group <- as.factor(DshapeK$group) # mark categorical as factor
DshapeK$identifier <- as.factor(DshapeK$identifier)
modelShapeK <- lmer(kurtosis~group + day*block+(1|identifier), data = DshapeK) # fit model
tableShapeK <- coef(summary(modelShapeK))
tableShapeK

# skew
DshapeS <- read.csv("table_skew_space5.csv") # load data
DshapeS$group <- as.factor(DshapeS$group) # mark categorical as factor
DshapeS$identifier <- as.factor(DshapeS$identifier)
modelShapeS <- lmer(skew~group + day*block+(1|identifier), data = DshapeS) # fit model
tableShapeS <- coef(summary(modelShapeS))
tableShapeS

# range
DshapeR <- read.csv("table_range_space5.csv") # load data
DshapeR$group <- as.factor(DshapeR$group) # mark categorical as factor
DshapeR$identifier <- as.factor(DshapeR$identifier)
modelShapeR <- lmer(range~group + day*block+(1|identifier), data = DshapeR) # fit model
tableShapeR <- coef(summary(modelShapeR))
tableShapeR