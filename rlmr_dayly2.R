# load the calc_variables dataset
calc_variables <- read.csv("/Users/joshuagantner/Library/CloudStorage/OneDrive-UniversitätZürichUZH/Files/Studium/Masterarbeit/0 v9/table_space5.csv")
calc_variables$daily <- (calc_variables$block-1)*30+calc_variables$trial
calc_variables$daily <- calc_variables$daily*(1/120)*4
# set categorical variables
calc_variables$group <- as.factor(calc_variables$group)
calc_variables$identifier <- as.factor(calc_variables$identifier)
calc_variables$day <- as.factor(calc_variables$day)

# load packages
library(lme4)
library(robustlmm)

# fit models
model_0 <- as.formula("distance~day*daily+(1+daily|identifier)")
model_W <- as.formula("distance~group*day*daily+(1+daily|identifier)")
v_toggle = 1;

# 1. robust models
r0_r <- rlmer(model_0, data = calc_variables, verbose = v_toggle)
summary(r0_r)
rW_r <- rlmer(model_W, data = calc_variables, verbose = v_toggle)
summary(rW_r)
r1 <- anova(r0_r,rW_r)
r1
summary(r1)

# 2. simple models with restricted maximum likelihood
s0_r <- lmer(model_0, data = calc_variables, verbose = v_toggle, REML=T)
summary(s0_r)
sW_r <- lmer(model_W, data = calc_variables, verbose = v_toggle, REML=T)
summary(sW_r)
r2 <- anova(s0_r,sW_r)
r2
summary(r2)

# 3. simple models with maximum likelihood
s0_m <- lmer(model_0, data = calc_variables, verbose = v_toggle, REML=F)
summary(s0_m)
sW_m <- lmer(model_W, data = calc_variables, verbose = v_toggle, REML=F)
summary(sW_m)
r3 <- anova(s0_m,sW_m)
r3
summary(r3)