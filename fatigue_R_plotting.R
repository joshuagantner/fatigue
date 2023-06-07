# Peripheral fatigues detrimental effect on motor training - underlying mechanisms
#  - Plotting
#
# Author: Joshua Gantner
# eMail:  josh.gantner@gmail.com

# 0. SETUP
# set working directory
setwd('/Users/joshuagantner/Library/CloudStorage/OneDrive-UniversitätZürichUZH/Files/Studium/Masterarbeit/0 v9')
# load packages - in case of missing package, install with 'install.packages("packagename")'
library(ggplot2)
library(tidyr)
library(ggthemes) 
# set theme - prefered themes: theme_classic(), theme_stata(), theme_hc()
theme_set(theme_classic())
mytheme <- theme(legend.position = "bottom", 
                 legend.margin = margin(-8, 1, 1, 1),
                 legend.key.size = unit(0.2, 'cm'), 
                 legend.text = element_text(size=8))
line_width = 1

# 1. PLOT 2-DAY MODEL
# modelFull
tableFull <- data.frame(
  time = c(0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9),
  CON = c(38.94, 36.82, 34.70, 32.58, 30.46, 28.34, 26.22, 24.10, 21.98, 30.62, 29.29, 27.95, 26.61, 25.28, 23.94, 22.60, 21.27, 19.93),
  FSD = c(40.18, 39.02, 37.86, 36.70, 35.55, 34.39, 33.23, 32.07, 30.92, 30.53, 28.73, 26.94, 25.15, 23.36, 21.56, 19.77, 17.98, 16.19),
  FRD = c(40.21, 40.20, 40.18, 40.17, 40.15, 40.14, 40.12, 40.11, 40.09, 34.43, 31.52, 28.61, 25.70, 22.79, 19.88, 16.97, 14.05, 11.14)
)
# Reshape data to long format
table_long <- gather(tableFull, key = "group", value = "value", -time)

# plot full model day 1
table_long_d1 <- subset(table_long, table_long$time<=4)
plotFullD1 <- ggplot(table_long_d1, aes(x=time, y=value, group=group, color=group)) +
  geom_line(linewidth = line_width) +
  ylim(10,42)+
  labs(x = "session", y = "variability") +
  scale_x_continuous(breaks = c(0.5, 1.5, 2.5, 3.5), labels = c(1, 2, 3, 4))+
  #ggtitle("training day") +
  guides(color = guide_legend(title = NULL)) +
  mytheme
ggsave("plotFullD1.png", plot = plotFullD1, width = 6, height = 5, units = "cm", dpi = 300)


# plot full model day 2
table_long_d2 <- subset(table_long, table_long$time>=5)
plotFullD2 <- ggplot(table_long_d2, aes(x=time, y=value, group=group, color=group)) +
  geom_line(linewidth = line_width) +
  ylim(10,42)+
  labs(x = "session", y = "variability") +
  scale_x_continuous(breaks = c(5.5, 6.5, 7.5, 8.5), labels = c(1, 2, 3, 4))+
  #ggtitle("control day") +
  guides(color = guide_legend(title = NULL),
         ) +
  mytheme
ggsave("plotFullD2.png", plot = plotFullD2, width = 6, height = 5, units = "cm", dpi = 300)

# 2. PLOT 1-DAY MODELS
# training day
tableD1 <- data.frame(
  time = c(0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4),
  CON = c(31.33, 29.80, 28.27, 26.74, 25.21, 23.68, 22.15, 20.62, 19.09),
  fatigued = c(33.47, 33.10, 32.73, 32.36, 32.00, 31.63, 31.26, 30.89, 30.52)
)
# Reshape data to long format
table_long <- gather(tableD1, key = "group", value = "value", -time)
# plot
plotSingleD1 <- ggplot(table_long, aes(x=time, y=value, group=group, color=group)) +
  geom_line(linewidth = line_width) +
  ylim(15,35)+
  labs(x = "session", y = "variability") +
  scale_x_continuous(breaks = c(0.5, 1.5, 2.5, 3.5), labels = c(1, 2, 3, 4))+
  ##ggtitle("training day") +
  guides(color = guide_legend(title = NULL)) +
  mytheme
ggsave("plotSingleD1.png", plot = plotSingleD1, width = 6, height = 5, units = "cm", dpi = 300)

# control day
tableD2 <- data.frame(
  time = c(5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9),
  CON = c(21.39, 20.91, 20.43, 19.95, 19.46, 18.98, 18.50, 18.02, 17.54),
  FSD = c(23.54, 23.06, 22.58, 22.10, 21.62, 21.14, 20.66, 20.18, 19.69),
  FRD = c(30.60, 29.23, 27.86, 26.49, 25.13, 23.76, 22.39, 21.02, 19.65)
)
# Reshape data to long format
table_long <- gather(tableD2, key = "group", value = "value", -time)
# plot
plotSingleD2 <- ggplot(table_long, aes(x=time, y=value, group=group, color=group)) +
  geom_line(linewidth = line_width) +
  ylim(15,35)+
  labs(x = "session", y = "variability") +
  scale_x_continuous(breaks = c(5.5, 6.5, 7.5, 8.5), labels = c(1, 2, 3, 4))+
  #ggtitle("control day") +
  guides(color = guide_legend(title = NULL)) +
  mytheme
ggsave("plotSingleD2.png", plot = plotSingleD2, width = 6, height = 5, units = "cm", dpi = 300)

# 3. PLOT SKILL
# training day
skillD1 <- data.frame(
  time = c(0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4),
  CON = c(-0.02358741, 0.004983495, 0.0335544, 0.062125305, 0.09069621, 0.119267115, 0.14783802, 0.176408925, 0.20497983),
  FSD = c(-0.01261371, -0.001093545, 0.01042662, 0.021946785, 0.03346695, 0.044987115, 0.05650728, 0.068027445, 0.07954761),
  FRD = c(-0.000366, 0.011735815, 0.02383763, 0.035939445, 0.04804126, 0.060143075, 0.07224489, 0.084346705, 0.09644852)
)
# Reshape data to long format
table_long <- gather(skillD1, key = "group", value = "value", -time)
# plot
plotSkillD1 <- ggplot(table_long, aes(x=time, y=value, group=group, color=group)) +
  geom_line(linewidth = line_width) +
  ylim(-0.03,0.4)+
  labs(x = "session", y = "skill") +
  scale_x_continuous(breaks = c(0.5, 1.5, 2.5, 3.5), labels = c(1, 2, 3, 4))+
  ##ggtitle("training day") +
  guides(color = guide_legend(title = NULL)) +
  mytheme
ggsave("plotSkillD1.png", plot = plotSkillD1, width = 6, height = 5, units = "cm", dpi = 300)

# control day
skillD2 <- data.frame(
  time = c(5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9),
  CON = c(-0.01219876, 0.033286775, 0.07877231, 0.124257845, 0.16974338, 0.215228915, 0.26071445, 0.306199985, 0.35168552),
  FSD = c(0.04819877, 0.061085735, 0.0739727, 0.086859665, 0.09974663, 0.112633595, 0.12552056, 0.138407525, 0.15129449),
  FRD = c(0.03084196, 0.05524547, 0.07964898, 0.10405249, 0.128456, 0.15285951, 0.17726302, 0.20166653, 0.22607004)
)
# Reshape data to long format
table_long <- gather(skillD2, key = "group", value = "value", -time)
# plot
plotSkillD2 <- ggplot(table_long, aes(x=time, y=value, group=group, color=group)) +
  geom_line(linewidth = line_width) +
  ylim(-0.03,0.4)+
  labs(x = "session", y = "skill") +
  scale_x_continuous(breaks = c(5.5, 6.5, 7.5, 8.5), labels = c(1, 2, 3, 4))+
  #ggtitle("control day") +
  guides(color = guide_legend(title = NULL)) +
  mytheme
ggsave("plotSkillD2.png", plot = plotSkillD2, width = 6, height = 5, units = "cm", dpi = 300)

# training day | fatigued collective
skillD1f <- data.frame(
  time = c(0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4),
  CON = c(-0.02358741,	0.004983495,	0.0335544,	0.062125305,	0.09069621,	0.119267115,	0.14783802,	0.176408925,	0.20497983),
  fatigued = c(-0.0064518,	0.005355385,	0.01716257,	0.028969755,	0.04077694,	0.052584125,	0.06439131,	0.076198495,	0.08800568)
)
# Reshape data to long format
table_long <- gather(skillD1f, key = "group", value = "value", -time)
# plot
plotSkillD1f <- ggplot(table_long, aes(x=time, y=value, group=group, color=group)) +
  geom_line(linewidth = line_width) +
  ylim(-0.03,0.4)+
  labs(x = "session", y = "skill") +
  scale_x_continuous(breaks = c(0.5, 1.5, 2.5, 3.5), labels = c(1, 2, 3, 4))+
  ##ggtitle("training day") +
  guides(color = guide_legend(title = NULL)) +
  mytheme
ggsave("plotSkillD1f.png", plot = plotSkillD1f, width = 6, height = 5, units = "cm", dpi = 300)
