# header
## project: Peripheral fatigues detrimental effect on motor training - underlying mechanisms
## script: statistics
## Author: Joshua Gantner
## eMail:  josh.gantner@gmail.com 

# 0. SETUP
##### set working directory -->
setwd('/Users/joshuagantner/Library/CloudStorage/OneDrive-UniversitätZürichUZH/Files/Studium/Masterarbeit/0 v9')
##### load packages -->
library(lmerTest)
library(robustlmm)
library(MuMIn)
library(dplyr)
v_toggle = 0 # toggle verbosity


# 1. MODEL VARIABILITY
## load data
##### read in data from csv table, as created by matlab data processing script -->
D <- read.csv("table_space5.csv")

## preprocess
##### mark categorical variables -->
D$group <- as.factor(D$group)
D$identifier <- as.factor(D$identifier)
##### ad a continuous variable for trials completed within a day to serves as indicator for time passing/progression of training -->
D$training <- (D$block-1)*30+D$trial
D$training <- D$training*(1/120)*1 # scale to 1 day = +1
##### D <- subset(D,D$distance<quantile(D$distance, c(.94))) -->


## fit models
### trainig day - fatigued collective
Dd1 <- subset(D,D$day==1)
Dd1 <- Dd1 %>% mutate(fatigued = ifelse(group == 1, 0, 1))
##### model_formula <- "distance ~ group * training + (1 | identifier)"
model_formula <- "distance ~ fatigued * training + (1 | identifier)"
modelD1 <- rlmer(model_formula, data = Dd1, verbose = v_toggle)
##### satterthwaite approximation of degrees of freedom
m <- lmer(model_formula, data=Dd1)
dfs <- data.frame(coef(summary(m)))$df
##### p-values for the fixed -->
coefs <- coef(summary(modelD1))
pvalues <- 2*pt(abs(coefs[,3]), dfs, lower=FALSE)
tableD1 <- cbind(coefs,data.frame(pvalues))
tableD1

# PLOTING DATA POINTS & SE

## load packages - in case of missing package, install with 'install.packages("packagename")' -->
library(ggplot2)
library(tidyr)
library(ggthemes)
library(patchwork)
## set theme
##### preferred themes: theme_classic(), theme_stata(), theme_hc() -->
theme_set(theme_classic())
mytheme <- theme(legend.position = "bottom", 
                 legend.margin = margin(-8, 1, 1, 1),
                 legend.key.size = unit(0.2, 'cm'), 
                 legend.text = element_text(size=8))
line_width = 1
var_limits = c(5, 54)  # c(8, 45)
grayscale_palette <- gray.colors(28)

## predicted distance
Dd1$predicted = predict(modelD1, newdata = Dd1)

# plot predictions by participants and fixed effects
## plot: control training
 # read fixed effect intercept, slope, and SE from model
intercept <- coefs["(Intercept)", "Estimate"]
slope <- coefs["training", "Estimate"]
se <- coefs["training", "Std. Error"]

 # create data frame for fixed effects line
fixed_effects_nonf <- data.frame(
  x = c(0, 1),               # X values for the line
  y = intercept + slope * c(0, 1),  # Corresponding Y values for the line
  ymin = intercept + slope * c(0, 1) - 1.96 * se,  # Lower bound
  ymax = intercept + slope * c(0, 1) + 1.96 * se   # Upper bound (for a 95% confidence interval)
)

 # create plot
p_var_pred_nonf <- ggplot() +
  geom_point(data = Dd1 %>% filter(fatigued == "0"), aes(x = training, y = predicted, group = identifier, color = identifier), size = 0.2, alpha = 0.33, show.legend = FALSE) +
  scale_color_manual(values = grayscale_palette) +
  ylim(var_limits) +
  labs(x = "Training", y = "Predicted Variability") +
  mytheme +
  geom_line(data = fixed_effects_nonf, aes(x = x, y = y), color = 'red') +  # Plot fixed effects line
  geom_ribbon(data = fixed_effects_nonf, aes(x = x, ymin = ymin, ymax = ymax), fill = "red", alpha = 0.5)  # Plot fixed effects SE

p_var_pred_nonf # print graph to R Studio viewer

## plot: fatigued collective training
 # read fixed effect intercept, slope, and SE from model
intercept <- coefs["(Intercept)", "Estimate"] + coefs["fatigued", "Estimate"]
slope <- coefs["training", "Estimate"] + coefs["fatigued:training", "Estimate"]
se <- coefs["fatigued:training", "Std. Error"]

 # create data frame for fixed effects line
fixed_effects_fati <- data.frame(
  x = c(0, 1),               # X values for the line
  y = intercept + slope * c(0, 1),  # Corresponding Y values for the line
  ymin = intercept + slope * c(0, 1) - 1.96 * se,  # Lower bound
  ymax = intercept + slope * c(0, 1) + 1.96 * se   # Upper bound (for a 95% confidence interval)
)

 # create plot
p_var_pred_fati <- ggplot() +
  geom_point(data = Dd1 %>% filter(fatigued == "1"), aes(x = training, y = predicted, group = identifier, color = identifier), size = 0.2, alpha = 0.33, show.legend = FALSE) +
  scale_color_manual(values = grayscale_palette) +
  ylim(var_limits) +
  labs(x = "Training", y = "Predicted Variability") +
  mytheme +
  geom_line(data = fixed_effects_fati, aes(x = x, y = y), color = 'blue') +  # Plot fixed effects line
  geom_ribbon(data = fixed_effects_fati, aes(x = x, ymin = ymin, ymax = ymax), fill = 'blue', alpha = 0.5)  # Plot fixed effects SE

p_var_pred_fati # print graph to R Studio viewer
  
## plot: fixed effects training
p_fe_training <- ggplot()+
  ylim(var_limits) +
  labs(x = "Training", y = "Predicted Variability") +
  mytheme +
  geom_line(data = fixed_effects_nonf, aes(x = x, y = y), color = 'red') +  # Plot fixed effects line
  geom_ribbon(data = fixed_effects_nonf, aes(x = x, ymin = ymin, ymax = ymax), fill = "red", alpha = 0.5)+  # Plot fixed effects SE
  geom_line(data = fixed_effects_fati, aes(x = x, y = y), color = 'blue') +  # Plot fixed effects line
  geom_ribbon(data = fixed_effects_fati, aes(x = x, ymin = ymin, ymax = ymax), fill = 'blue', alpha = 0.5)  # Plot fixed effects SE
  
p_fe_training

## Arrange the plots
p_var_training <- p_var_pred_nonf + p_fe_training + p_var_pred_fati
ggsave("p_var_training.png", plot = p_var_training, width = 6*3, height = 5, units = "cm", dpi = 300)

### control day
Dd2 <- subset(D,D$day==2)
modelD2 <- rlmer(distance~group*training+(1|identifier), data=Dd2, verbose=v_toggle)
##### satterthwaite approximation of degrees of freedom -->
m <- lmer(distance~group*training+(1|identifier), data=Dd2)
dfs <- data.frame(coef(summary(m)))$df
##### p-values for the fixed effects -->
coefs <- coef(summary(modelD2))
pvalues <- 2*pt(abs(coefs[,3]), dfs, lower=FALSE)
tableD2 <- cbind(coefs,data.frame(pvalues))
tableD2



# 2. MODEL SKILL
## load data
##### read in data from csv table, as created by matlab data processing script -->
Dskill <- read.csv("table_skill.csv")
##### mark categorical variables-->
Dskill$group <- as.factor(Dskill$group)
Dskill$ID <- as.factor(Dskill$ID)

## fit models
### 2-day
modelSkill <- lmer(skillp~group*day*BN+(1|ID), data=Dskill)
tableSkill <- coef(summary(modelSkill))
tableSkill

### training-day-model
DskillD1 <- subset(Dskill,Dskill$day==1)
modelSkillD1 <- lmer(skillp~group*BN+(1|ID), data=DskillD1)
tableSkillD1 <- coef(summary(modelSkillD1))
tableSkillD1

### training day - fatigued collective
DskillD1 <- subset(Dskill,Dskill$day==1)
DskillD1 <- DskillD1 %>% mutate(fatigued = ifelse(group == 1, 0, 1))
modelSkillD1f <- lmer(skillp~fatigued*BN+(1|ID), data=DskillD1)
tableSkillD1f <- coef(summary(modelSkillD1f))
tableSkillD1f

### control day
DskillD2 <- subset(Dskill,Dskill$day==2)
modelSkillD2 <- lmer(skillp~group*BN+(1|ID), data=DskillD2)
tableSkillD2 <- coef(summary(modelSkillD2))
tableSkillD2

### control day FSD baseline
DskillD2 <- subset(Dskill,Dskill$day==2)
DskillD2$group <- factor(DskillD2$group, levels = c(2, 1, 3))
modelSkillD2 <- lmer(skillp~group*BN+(1|ID), data=DskillD2)
tableSkillD2 <- coef(summary(modelSkillD2))
tableSkillD2



# 3. CORRELATIONS
## create combined variability-skill table
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

## correlate variability // skill
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

## correlate variability // skill for combined fatigue
correlations <- data.frame(
  fatigued = c(0,0,1,1),
  day = c(1,2,1,2),
  r = c(NaN,NaN,NaN,NaN),
  p = c(NaN,NaN,NaN,NaN)
)

Dvs <- Dvs %>% mutate(fatigued = ifelse(group == 1, 0, 1))

for (i in 0:1) { # fatigued level
  for (j in 1:2) { # day level
    Dvs_ij <- subset(Dvs, fatigued == i & day == j)
    foo <- cor.test(Dvs_ij$skillp, Dvs_ij$variability,method = "spearman")
    correlations[correlations$fatigued==i & correlations$day == j, ]$r <- foo$estimate
    correlations[correlations$fatigued==i & correlations$day == j, ]$p <- foo$p.value
  }
}
correlations



# 4. SHAPE of VARIABILITY
## kurtosis
DshapeK <- read.csv("table_kurtosis_space5.csv") # load data
DshapeK$group <- as.factor(DshapeK$group) # mark categorical as factor
DshapeK$identifier <- as.factor(DshapeK$identifier)
modelShapeK <- lmer(kurtosis~group*day*block+(1|identifier), data = DshapeK) # fit model
tableShapeK <- coef(summary(modelShapeK))
tableShapeK

## skew
DshapeS <- read.csv("table_skew_space5.csv") # load data
DshapeS$group <- as.factor(DshapeS$group) # mark categorical as factor
DshapeS$identifier <- as.factor(DshapeS$identifier)
modelShapeS <- lmer(skew~group*day*block+(1|identifier), data = DshapeS) # fit model
tableShapeS <- coef(summary(modelShapeS))
tableShapeS

## range
DshapeR <- read.csv("table_range_space5.csv") # load data
DshapeR$group <- as.factor(DshapeR$group) # mark categorical as factor
DshapeR$identifier <- as.factor(DshapeR$identifier)
modelShapeR <- lmer(range~group*day*block+(1|identifier), data = DshapeR) # fit model
tableShapeR <- coef(summary(modelShapeR))
tableShapeR



# 5. DRIVERS of VARIABILITY CHANGE
## link data
filenames <- c(
  "table_spaceFDI.csv",
  "table_spaceAPB.csv",
  "table_spaceADM.csv",
  "table_spaceIntrinsic.csv", 
  "table_spaceExtrinsic.csv")

##### Create an empty data frame to store the results -->
r2 <- data.frame(subspace = character(),
                 cR2 = numeric(),
                 stringsAsFactors = FALSE)

## find r2
for (filename in filenames) {
  # Read the CSV file
  Dspace <- read.csv(filename)
  Dspace$group <- as.factor(Dspace$group)
  Dspace$identifier <- as.factor(Dspace$identifier)
  Dspace$training <- (Dspace$block - 1) * 30 + Dspace$trial
  Dspace$training <- Dspace$training * (1 / 120) * 1
  
  # Fit the model
  model <- lmer(distance ~ group * day * training + (1 + training | identifier), data = Dspace, REML = FALSE)
  
  # Calculate R-squared and add it to the data frame
  cR2 <- r.squaredGLMM(model)[, "R2c"]
  r2 <- rbind(r2, data.frame(subspace = filename, cR2 = cR2))
}
r2



# 6. MAXIMUM EMG AMPLITUDE
## load data
Dmax <- read.csv("table_maxemgamp_FDI.csv")
Dmax$group <- as.factor(Dmax$group)
Dmax$time <- ((Dmax$block-1)*30+Dmax$trial)/30
Dmax <- Dmax %>% mutate(fatigued = ifelse(group == 1, 0, 1))

## fit model
modelMaxamp <- rlmer(max~fatigued*time + (1|identifier), data = Dmax[Dmax$day==1, ], verbose = v_toggle)
##### satterthwaite approximation of degrees of freedom -->
m <- lmer(max~fatigued*time + (1|identifier), data = Dmax[Dmax$day==1, ])
dfs <- data.frame(coef(summary(m)))$df
##### calculate p-values for the fixed effects of the robust model -->
coefs <- coef(summary(modelMaxamp))
pvalues <- 2*pt(abs(coefs[,3]), dfs, lower=FALSE)
tableMaxamp <- cbind(coefs,data.frame(pvalues))
tableMaxamp

## calculate fatigue quotient
Dtaskfail <- Dmax %>%
  filter(block %in% 1:4) %>%
  group_by(identifier, day, group, block) %>%
  summarise(max_trial = max(trial)) %>%
  pivot_wider(names_from = block, values_from = max_trial, names_prefix = "trial_") %>%
  ungroup()
pivot_df

addedFatigue <- data.frame(
  group = c(1,2,3),
  added_fatigue = c(NaN,NaN,NaN)
)

### include missing session 4s
for (group in 1:3) {
  foo <- Dtaskfail[Dtaskfail$group==group & Dtaskfail$day==1, c('trial_1', 'trial_4')]
  foo$trial_4[is.na(foo$trial_4)] <- 0
  foo <- na.omit(foo)
  q <- (foo$trial_1-foo$trial_4)/foo$trial_1
  addedFatigue[addedFatigue$group==group, 'added_fatigue'] <- mean(q)
}
addedFatigue

### exclude missing session 4s
for (group in 1:3) {
  foo <- Dtaskfail[Dtaskfail$group==group & Dtaskfail$day==1, c('trial_1', 'trial_4')]
  foo <- na.omit(foo)
  q <- (foo$trial_1-foo$trial_4)/foo$trial_1
  addedFatigue[addedFatigue$group==group, 'added_fatigue'] <- mean(q)
}
addedFatigue