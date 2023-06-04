# Peripheral fatigues detrimental effect on motor training - underlying mechanisms
#  - Plotting
#
# Author: Joshua Gantner
# eMail:  josh.gantner@gmail.com

# 0. SETUP
# set working directory
setwd('/Users/joshuagantner/Library/CloudStorage/OneDrive-UniversitätZürichUZH/Files/Studium/Masterarbeit/0 v9')
# load packages
library(ggplot2)
library(tidyr)

# 1. APPLY & PLOT 2-DAY MODEL
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
ggplot(table_long_d1, aes(x=time, y=value, group=group, color=group)) +
  geom_line() +
  labs(x = "time", y = "Variability", color = "Group") +
  ggtitle("training day (full model)") +
  theme_minimal()

# plot full model day 1
table_long_d2 <- subset(table_long, table_long$time>=5)
ggplot(table_long_d2, aes(x=time, y=value, group=group, color=group)) +
  geom_line() +
  labs(x = "time", y = "Variability", color = "Group") +
  ggtitle("control day (full model)") +
  theme_minimal()

# 2. APPLY & PLOT 1-DAY MODELS
# training day
tableD1 <- data.frame(
  time = c(0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4),
  CON = c(31.33, 29.80, 28.27, 26.74, 25.21, 23.68, 22.15, 20.62, 19.09),
  fatigued = c(33.47, 33.10, 32.73, 32.36, 32.00, 31.63, 31.26, 30.89, 30.52)
)
# Reshape data to long format
table_long <- gather(tableD1, key = "group", value = "value", -time)
# plot
ggplot(table_long, aes(x=time, y=value, group=group, color=group)) +
  geom_line() +
  labs(x = "time", y = "Variability", color = "Group") +
  ggtitle("training day (1-day model)") +
  theme_minimal()

# training day
tableD2 <- data.frame(
  time = c(5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9),
  CON = c(21.39, 20.91, 20.43, 19.95, 19.46, 18.98, 18.50, 18.02, 17.54),
  FSD = c(23.54, 23.06, 22.58, 22.10, 21.62, 21.14, 20.66, 20.18, 19.69),
  FRD = c(30.60, 29.23, 27.86, 26.49, 25.13, 23.76, 22.39, 21.02, 19.65)
)
# Reshape data to long format
table_long <- gather(tableD2, key = "group", value = "value", -time)
# plot
ggplot(table_long, aes(x=time, y=value, group=group, color=group)) +
  geom_line() +
  labs(x = "time", y = "Variability", color = "Group") +
  ggtitle("control day (1-day model)") +
  theme_minimal()