# header
 # project: Peripheral fatigues detrimental effect on motor training - underlying mechanisms
 # Author: Joshua Gantner
 # eMail:  josh.gantner@gmail.com 
 
 # READ ME ↓
 # • View as R Markdown for outline and collapsible sections.
 # • Make sure to update the working directory (line 12) to your working folder. It will serve as source for loading data and location to save figures.

# 0. SETUP
 # set working directory
setwd('/Users/joshuagantner/Library/CloudStorage/OneDrive-UniversitätZürichUZH/Files/Studium/Masterarbeit/0 v9')

## load packages, install if not yet present
packages <- c(    # list of requiered packages to be loaded and installed if missing
  "lmerTest", 
  "robustlmm", 
  "MuMIn", 
  "dplyr", 
  "ggplot2", 
  "tidyr", 
  "ggthemes", 
  "patchwork"
  )
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))

## set parameters
v_toggle = 0 # toggle verbosity

## set theme for plots
theme_set(theme_classic())
mytheme <- theme(legend.position = "bottom", 
                 legend.margin = margin(-8, 1, 1, 1),
                 legend.key.size = unit(0.2, 'cm'), 
                 legend.text = element_text(size=8),
                 legend.title = element_blank())
line_width = 1
y_limits_d1 = c(8, 45)
y_limits_d2 = c(14, 36)
y_limits_skill = c(-0.03,0.4)
x_values = c(0, 0.125, 0.375, 0.625, 0.875, 1)
errorbar_width_skill = 0.2

# 1. VARIABILITY
## load data
 # read in data from csv table, as created by matlab data processing script
D <- read.csv("table_space5.csv")

## preprocess
 # mark categorical variables
D$group <- as.factor(D$group)
D$identifier <- as.factor(D$identifier)

 # ad a continuous variable for trials completed within a day to serves as indicator for time passing/progression of training
D$training <- (D$block-1)*30+D$trial
D$training <- D$training*(1/120)*1 # scale to 1 day = +1

## fit models
### trainig day
#### model
 # create day 1 subset
Dd1 <- subset(D,D$day==1)
Dd1 <- Dd1 %>% mutate(fatigued = ifelse(group == 1, 0, 1))    # add binary fatigue identifier

 # define model - (1) for modeling all 3 groups, (2) for modeling fatigued as one
 # model_formula <- "distance ~ group * training + (1 | identifier)" # (1)
model_formula <- "distance ~ fatigued * training + (1 | identifier)" # (2)

 # fit robust model
modelD1 <- rlmer(model_formula, data = Dd1, verbose = v_toggle)

 # satterthwaite approximation of degrees of freedom
m <- lmer(model_formula, data=Dd1)
dfs <- data.frame(coef(summary(m)))$df

 # caclulate p-values
coefs <- coef(summary(modelD1))
pvalues <- 2*pt(abs(coefs[,3]), dfs, lower=FALSE)
tableD1 <- cbind(coefs,data.frame(pvalues))
tableD1 # print model summary to console
  # Save the table as a CSV file
write.csv(tableD1, "tableD1.csv", row.names = TRUE)

#### predict
 # predict fixed effects for controls
intercept <- coefs["(Intercept)", "Estimate"]
slope <- coefs["training", "Estimate"]
se <- coefs["training", "Std. Error"]
fixed_effects_nonf <- data.frame(
  x = c(0, 0.125, 0.375, 0.625, 0.875, 1),               # X values for the line
  y = intercept + slope * c(0, 0.125, 0.375, 0.625, 0.875, 1),  # Corresponding Y values for the line
  ymin = intercept + slope * c(0, 0.125, 0.375, 0.625, 0.875, 1) - 1.96 * se,  # Lower bound
  ymax = intercept + slope * c(0, 0.125, 0.375, 0.625, 0.875, 1) + 1.96 * se   # Upper bound (for a 95% confidence interval)
)

 # predict fixed effects for fatigued collective
intercept <- coefs["(Intercept)", "Estimate"] + coefs["fatigued", "Estimate"]
slope <- coefs["training", "Estimate"] + coefs["fatigued:training", "Estimate"]
se <- coefs["fatigued:training", "Std. Error"]
fixed_effects_fati <- data.frame(
  x = c(0, 0.125, 0.375, 0.625, 0.875, 1),               # X values for the line
  y = intercept + slope * c(0, 0.125, 0.375, 0.625, 0.875, 1),  # Corresponding Y values for the line
  ymin = intercept + slope * c(0, 0.125, 0.375, 0.625, 0.875, 1) - 1.96 * se,  # Lower bound
  ymax = intercept + slope * c(0, 0.125, 0.375, 0.625, 0.875, 1) + 1.96 * se   # Upper bound (for a 95% confidence interval)
)

#### plot
p_fe_training <- ggplot() +
  ylim(y_limits_d1) +
  labs(x = "session", y = "variability") +
  scale_x_continuous(breaks = c(0.125, 0.375, 0.625, 0.875), labels = c(1, 2, 3, 4)) +
  mytheme +
  geom_line(data = fixed_effects_nonf, aes(x = x, y = y, color = "CON")) +
  geom_point(data = fixed_effects_nonf[2:5,], aes(x = x, y = y, color = "CON")) +
  geom_errorbar(data = fixed_effects_nonf[2:5,], aes(x = x, ymin = ymin, ymax = ymax, color = "CON"), width = 0.05) +
  geom_line(data = fixed_effects_fati, aes(x = x, y = y, color = "fatigued")) +
  geom_point(data = fixed_effects_fati[2:5,], aes(x = x, y = y, color = "fatigued")) +
  geom_errorbar(data = fixed_effects_fati[2:5,], aes(x = x, ymin = ymin, ymax = ymax, color = "fatigued"), width = 0.05)
  
p_fe_training   # print ggplot to R Studio Viewer

### control day
#### model
 # create day 2 subset
Dd2 <- subset(D,D$day==2)    # create day 2 subset

 # fit robust model to day 2 distinguishing all three groups
modelD2 <- rlmer(distance~group*training+(1|identifier), data=Dd2, verbose=v_toggle)

 # satterthwaite approximation of degrees of freedom
m <- lmer(distance~group*training+(1|identifier), data=Dd2)
dfs <- data.frame(coef(summary(m)))$df

 # caclulate p-values
coefs <- coef(summary(modelD2))
pvalues <- 2*pt(abs(coefs[,3]), dfs, lower=FALSE)
tableD2 <- cbind(coefs,data.frame(pvalues))
tableD2 # print model summary to console
  # Save the table as a CSV file
write.csv(tableD2, "tableD2.csv", row.names = TRUE)

#### predict
 # predict fixed effects for controls
intercept <- coefs["(Intercept)", "Estimate"]
slope <- coefs["training", "Estimate"]
se <- coefs["training", "Std. Error"]
fixed_effects_con <- data.frame(
  x = c(0, 0.125, 0.375, 0.625, 0.875, 1),               # X values for the line
  y = intercept + slope * c(0, 0.125, 0.375, 0.625, 0.875, 1),  # Corresponding Y values for the line
  ymin = intercept + slope * c(0, 0.125, 0.375, 0.625, 0.875, 1) - 1.96 * se,  # Lower bound
  ymax = intercept + slope * c(0, 0.125, 0.375, 0.625, 0.875, 1) + 1.96 * se   # Upper bound (for a 95% confidence interval)
)

 # predict fixed effects for group 2
intercept <- coefs["(Intercept)", "Estimate"] + coefs["group2", "Estimate"]
slope <- coefs["training", "Estimate"] + coefs["group2:training", "Estimate"]
se <- coefs["group2:training", "Std. Error"]
fixed_effects_g2 <- data.frame(
  x = c(0, 0.125, 0.375, 0.625, 0.875, 1),               # X values for the line
  y = intercept + slope * c(0, 0.125, 0.375, 0.625, 0.875, 1),  # Corresponding Y values for the line
  ymin = intercept + slope * c(0, 0.125, 0.375, 0.625, 0.875, 1) - 1.96 * se,  # Lower bound
  ymax = intercept + slope * c(0, 0.125, 0.375, 0.625, 0.875, 1) + 1.96 * se   # Upper bound (for a 95% confidence interval)
)

 # predict fixed effects for group 3
intercept <- coefs["(Intercept)", "Estimate"] + coefs["group3", "Estimate"]
slope <- coefs["training", "Estimate"] + coefs["group3:training", "Estimate"]
se <- coefs["group3:training", "Std. Error"]
fixed_effects_g3 <- data.frame(
  x = c(0, 0.125, 0.375, 0.625, 0.875, 1),               # X values for the line
  y = intercept + slope * c(0, 0.125, 0.375, 0.625, 0.875, 1),  # Corresponding Y values for the line
  ymin = intercept + slope * c(0, 0.125, 0.375, 0.625, 0.875, 1) - 1.96 * se,  # Lower bound
  ymax = intercept + slope * c(0, 0.125, 0.375, 0.625, 0.875, 1) + 1.96 * se   # Upper bound (for a 95% confidence interval)
)
  
#### plot
p_fe_control <- ggplot()+
  ylim(y_limits_d2) +
  labs(x = "session", y = "variability") +
  scale_x_continuous(breaks = c(0.125, 0.375, 0.625, 0.875), labels = c(1, 2, 3, 4))+
  mytheme +
  geom_line(data = fixed_effects_con, aes(x = x, y = y, color = "CON")) +  # Plot control
  geom_point(data = fixed_effects_con[2:5,], aes(x = x, y = y, color = "CON")) +
  geom_errorbar(data = fixed_effects_con[2:5,], aes(x = x, ymin = ymin, ymax = ymax, color = "CON"), width = 0.05) +
  geom_line(data = fixed_effects_g2, aes(x = x, y = y, color = "FSD")) +  # Plot fatigued
  geom_point(data = fixed_effects_g2[2:5,], aes(x = x, y = y, color = "FSD")) +
  geom_errorbar(data = fixed_effects_g2[2:5,], aes(x = x, ymin = ymin, ymax = ymax, color = "FSD"), width = 0.05) +
  geom_line(data = fixed_effects_g3, aes(x = x, y = y, color = "FRD")) +  # Plot fatigued
  geom_point(data = fixed_effects_g3[2:5,], aes(x = x, y = y, color = "FRD")) +
  geom_errorbar(data = fixed_effects_g3[2:5,], aes(x = x, ymin = ymin, ymax = ymax, color = "FRD"), width = 0.05)
  
p_fe_control   # print ggplot to R Studio Viewer

# 2. SKILL
## load data
 # read in data from csv table, as created by matlab data processing script
Dskill <- read.csv("table_skill.csv")

## preprocess
 # mark categorical variables
Dskill$group <- as.factor(Dskill$group)
Dskill$ID <- as.factor(Dskill$ID)

## fit models
### training day
#### model
 # create day 1 subset
DskillD1 <- subset(Dskill,Dskill$day==1)
DskillD1 <- DskillD1 %>% mutate(fatigued = ifelse(group == 1, 0, 1))    # add binary fatigue indicator

 # define model - (1) for modeling all 3 groups, (2) for modeling fatigued as one
 # model_formula = "skillp~group*BN+(1|ID)" # (1)
model_formula = "skillp~fatigued*BN+(1|ID)" # (2)

 # fit model
modelSkillD1 <- lmer(model_formula, data=DskillD1)
tableSkillD1 <- coef(summary(modelSkillD1))
tableSkillD1    # print model summary to console
  # Save the table as a CSV file
write.csv(tableSkillD1, "tableSkillD1.csv", row.names = TRUE)

#### predict
 # predict fixed effects for controls
intercept <- tableSkillD1["(Intercept)", "Estimate"]
slope <- tableSkillD1["BN", "Estimate"]
se <- tableSkillD1["BN", "Std. Error"]
fixed_effects_nonf <- data.frame(
  x = c(0, 0.5, 1.5, 2.5, 3.5, 4),               # X values for the line
  y = intercept + slope * c(0, 0.5, 1.5, 2.5, 3.5, 4),  # Corresponding Y values for the line
  ymin = intercept + slope * c(0, 0.5, 1.5, 2.5, 3.5, 4) - 1.96 * se,  # Lower bound
  ymax = intercept + slope * c(0, 0.5, 1.5, 2.5, 3.5, 4) + 1.96 * se   # Upper bound (for a 95% confidence interval)
)

 # predict fixed effects for fatigued collective
intercept <- tableSkillD1["(Intercept)", "Estimate"] + tableSkillD1["fatigued", "Estimate"]
slope <- tableSkillD1["BN", "Estimate"] + tableSkillD1["fatigued:BN", "Estimate"]
se <- tableSkillD1["fatigued:BN", "Std. Error"]
fixed_effects_fati <- data.frame(
  x = c(0, 0.5, 1.5, 2.5, 3.5, 4),               # X values for the line
  y = intercept + slope * c(0, 0.5, 1.5, 2.5, 3.5, 4),  # Corresponding Y values for the line
  ymin = intercept + slope * c(0, 0.5, 1.5, 2.5, 3.5, 4) - 1.96 * se,  # Lower bound
  ymax = intercept + slope * c(0, 0.5, 1.5, 2.5, 3.5, 4) + 1.96 * se   # Upper bound (for a 95% confidence interval)
)
  
#### plot
p_skill_training <- ggplot()+
  ylim(y_limits_skill) +
  labs(x = "session", y = "skill") +
  scale_x_continuous(breaks = c(0.5, 1.5, 2.5, 3.5), labels = c(1, 2, 3, 4))+
  mytheme +
  geom_line(data = fixed_effects_nonf, aes(x = x, y = y, color = "CON")) +  # Plot control
  geom_point(data = fixed_effects_nonf[2:5,], aes(x = x, y = y, color = "CON")) +
  geom_errorbar(data = fixed_effects_nonf[2:5,], aes(x = x, ymin = ymin, ymax = ymax, color = "CON"), width = errorbar_width_skill) +
  geom_line(data = fixed_effects_fati, aes(x = x, y = y, color = "fatigued")) +  # Plot fatigued
  geom_point(data = fixed_effects_fati[2:5,], aes(x = x, y = y, color = "fatigued")) +
  geom_errorbar(data = fixed_effects_fati[2:5,], aes(x = x, ymin = ymin, ymax = ymax, color = "fatigued"), width = errorbar_width_skill)
  
p_skill_training   # print ggplot to R Studio Viewer

### control day
#### model
DskillD2 <- subset(Dskill,Dskill$day==2)    # create day 2 subset
modelSkillD2 <- lmer(skillp~group*BN+(1|ID), data=DskillD2)   # fit model
tableSkillD2 <- coef(summary(modelSkillD2))
tableSkillD2    # print model summary to console
  # Save the table as a CSV file
write.csv(tableSkillD2, "tableSkillD2.csv", row.names = TRUE)

#### predict
 # predict fixed effects for controls
intercept <- tableSkillD2["(Intercept)", "Estimate"]
slope <- tableSkillD2["BN", "Estimate"]
se <- tableSkillD2["BN", "Std. Error"]
fixed_effects_con <- data.frame(
  x = c(0, 0.5, 1.5, 2.5, 3.5, 4),               # X values for the line
  y = intercept + slope * c(0, 0.5, 1.5, 2.5, 3.5, 4),  # Corresponding Y values for the line
  ymin = intercept + slope * c(0, 0.5, 1.5, 2.5, 3.5, 4) - 1.96 * se,  # Lower bound
  ymax = intercept + slope * c(0, 0.5, 1.5, 2.5, 3.5, 4) + 1.96 * se   # Upper bound (for a 95% confidence interval)
)

 # predict fixed effects for group 2
intercept <- tableSkillD2["(Intercept)", "Estimate"] + tableSkillD2["group2", "Estimate"]
slope <- tableSkillD2["BN", "Estimate"] + tableSkillD2["group2:BN", "Estimate"]
se <- tableSkillD2["group2:BN", "Std. Error"]
fixed_effects_g2 <- data.frame(
  x = c(0, 0.5, 1.5, 2.5, 3.5, 4),               # X values for the line
  y = intercept + slope * c(0, 0.5, 1.5, 2.5, 3.5, 4),  # Corresponding Y values for the line
  ymin = intercept + slope * c(0, 0.5, 1.5, 2.5, 3.5, 4) - 1.96 * se,  # Lower bound
  ymax = intercept + slope * c(0, 0.5, 1.5, 2.5, 3.5, 4) + 1.96 * se   # Upper bound (for a 95% confidence interval)
)

 # predict fixed effects for group 3
intercept <- tableSkillD2["(Intercept)", "Estimate"] + tableSkillD2["group3", "Estimate"]
slope <- tableSkillD2["BN", "Estimate"] + tableSkillD2["group3:BN", "Estimate"]
se <- tableSkillD2["group3:BN", "Std. Error"]
fixed_effects_g3 <- data.frame(
  x = c(0, 0.5, 1.5, 2.5, 3.5, 4),               # X values for the line
  y = intercept + slope * c(0, 0.5, 1.5, 2.5, 3.5, 4),  # Corresponding Y values for the line
  ymin = intercept + slope * c(0, 0.5, 1.5, 2.5, 3.5, 4) - 1.96 * se,  # Lower bound
  ymax = intercept + slope * c(0, 0.5, 1.5, 2.5, 3.5, 4) + 1.96 * se   # Upper bound (for a 95% confidence interval)
)
  
#### plot
p_skill_control <- ggplot()+
  ylim(y_limits_skill) +
  labs(x = "session", y = "skill") +
  scale_x_continuous(breaks = c(0.5, 1.5, 2.5, 3.5), labels = c(1, 2, 3, 4))+
  mytheme +
  geom_line(data = fixed_effects_con, aes(x = x, y = y, color = "CON")) +  # Plot control
  geom_point(data = fixed_effects_con[2:5,], aes(x = x, y = y, color = "CON")) +
  geom_errorbar(data = fixed_effects_con[2:5,], aes(x = x, ymin = ymin, ymax = ymax, color = "CON"), width = errorbar_width_skill) +
  geom_line(data = fixed_effects_g2, aes(x = x, y = y, color = "FSD")) +  # Plot fatigued
  geom_point(data = fixed_effects_g2[2:5,], aes(x = x, y = y, color = "FSD")) +
  geom_errorbar(data = fixed_effects_g2[2:5,], aes(x = x, ymin = ymin, ymax = ymax, color = "FSD"), width = errorbar_width_skill) +
  geom_line(data = fixed_effects_g3, aes(x = x, y = y, color = "FRD")) +  # Plot fatigued
  geom_point(data = fixed_effects_g3[2:5,], aes(x = x, y = y, color = "FRD")) +
  geom_errorbar(data = fixed_effects_g3[2:5,], aes(x = x, ymin = ymin, ymax = ymax, color = "FRD"), width = errorbar_width_skill)
  
p_skill_control   # print ggplot to R Studio Viewer

# 3. CREATE FIGURES
## training / result 1
figure_training <- p_fe_training + guides(colour = "none") + p_skill_training + plot_layout(guides = "collect") & theme(legend.position = "bottom")

figure_training

ggsave("figure_training.png", plot = figure_training, width = 6*2, height = 6, units = "cm", dpi = 300)

## followup / result 2
figure_control <- p_fe_control + guides(colour = "none") + p_skill_control + plot_layout(guides = "collect") & theme(legend.position = "bottom")

figure_control

ggsave("figure_control.png", plot = figure_control, width = 6*2, height = 6, units = "cm", dpi = 300)

## plot raw variability data
D <- D %>% mutate(fatigued = ifelse(group == 1, 0, 1))    # add binary fatigue identifier

### Lines by Fatigue State with 95% Confidence Interval
#### Training
ggplot(data = subset(D,D$day==1), aes(x = training, y = distance, group = factor(fatigued), color = factor(fatigued))) +
  geom_smooth() + 
  labs(x = "session", y = "variability") +
  scale_x_continuous(breaks = c(0.125, 0.375, 0.625, 0.875), labels = c(1, 2, 3, 4)) +
  mytheme +
  scale_color_discrete(labels = c("CON", "Fatigued")) +
  ggtitle("Lines by Fatigue State with 95% Confidence Interval during Training")

#### Followup
ggplot(data = subset(D,D$day==2), aes(x = training, y = distance, group = factor(group), color = factor(group))) +
  geom_smooth() + 
  labs(x = "session", y = "variability") +
  scale_x_continuous(breaks = c(0.125, 0.375, 0.625, 0.875), labels = c(1, 2, 3, 4)) +
  mytheme +
  scale_color_discrete(labels = c("CON", "FSD", "FRD")) +
  ggtitle("Lines by Group with 95% Confidence Interval during Follow-up")
  
### Whisker Plots by Fatigue State w/o outliers
#### Training
ggplot(data = subset(D,D$day==1), aes(x = factor(block), y = distance, fill = factor(fatigued))) +
  geom_boxplot(outlier.shape = NA) +
  ylim(0, 75) + 
  labs(x = "session", y = "variability") +
  mytheme +
  scale_fill_discrete(labels = c("CON", "Fatigued"))  +
  ggtitle("Whisker Plots by Fatigue State w/o outliers during Training")
  
#### Followup
ggplot(data = subset(D,D$day==2), aes(x = factor(block), y = distance, fill = factor(group))) +
  geom_boxplot(outlier.shape = NA) +
  ylim(0, 75) + 
  labs(x = "session", y = "variability") +
  mytheme +
  scale_fill_discrete(labels = c("CON", "FSD", "FRD"))  +
  ggtitle("Whisker Plots by Fatigue State w/o outliers during Followup")


## method figures
library(png)

 # Load PNG images
img1 <- readPNG("image-electrodes.png")
img2 <- readPNG("image-transducer.png")
img3 <- readPNG("image-taskview.png")
img4 <- readPNG("image-forceprofile.png")

 # Create ggplots for each image
image1 <- ggplot() +
  annotation_custom(rasterGrob(img1), xmin = 0, xmax = 1, ymin = 0, ymax = 1) +
  ggtitle("(a)")
image2 <- ggplot() +
  annotation_custom(rasterGrob(img2), xmin = 0, xmax = 1, ymin = 0, ymax = 1) +
  ggtitle("(b)")
image3 <- ggplot() +
  annotation_custom(rasterGrob(img3), xmin = 0, xmax = 1, ymin = 0, ymax = 1) +
  ggtitle("(c)")
image4 <- ggplot() +
  annotation_custom(rasterGrob(img4), xmin = 0, xmax = 1, ymin = 0, ymax = 1) +
  ggtitle("(d)")
  
 # combine imgaes 2x2
figure_methods <- image1 + image2 + image3 + image4

figure_methods

ggsave("figure_methods.png", plot = figure_methods, width = 17, height = 14, units = "cm", dpi = 600)

 # Load PNG images
img1 <- readPNG("image2_distribution_wide.png")
img2 <- readPNG("image2_sphere_wide.png")
img3 <- readPNG("image2_distribution_narrow.png")
img4 <- readPNG("image2_sphere_narrow.png")
img5 <- readPNG("image2_interpretation.png")

 # Create ggplots for each image
image1 <- ggplot() +
  annotation_custom(rasterGrob(img1), xmin = 0, xmax = 1, ymin = 0, ymax = 1) +
  theme_minimal()
image2 <- ggplot() +
  annotation_custom(rasterGrob(img2), xmin = 0, xmax = 1, ymin = 0, ymax = 1) +
  theme_minimal()
image3 <- ggplot() +
  annotation_custom(rasterGrob(img3), xmin = 0, xmax = 1, ymin = 0, ymax = 1) +
  theme_minimal()
image4 <- ggplot() +
  annotation_custom(rasterGrob(img4), xmin = 0, xmax = 1, ymin = 0, ymax = 1) +
  theme_minimal()
image5 <- ggplot() +
  annotation_custom(rasterGrob(img5), xmin = 0, xmax = 1, ymin = 0, ymax = 1) +
  theme_minimal()

 # combine images
layout <- plot_layout(    # Create a 2-2-1 grid layout
  ncol = 3,
  nrow = 2,
)

  # Arrange the plots in the layout
figure_shape <- image1 / image3 | image2 / image4 | image5

figure_shape

ggsave("figure_shape.png", plot = figure_shape, width = 12, height = 8, units = "cm", dpi = 300)


# 4. CORRELATIONS
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



# 5. SHAPE of VARIABILITY
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



# 6. DRIVERS of VARIABILITY CHANGE
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



# 7. MAXIMUM EMG AMPLITUDE
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