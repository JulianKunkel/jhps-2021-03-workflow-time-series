#!/usr/bin/env Rscript
library(ggplot2)
library(dplyr)
require(scales)

args = commandArgs(trailingOnly = TRUE)
file = "datasets/progress_4296426.csv" # for manual execution
file = args[1]
prefix = args[2]


# Plot the performance numbers of the analysis
data = read.csv(file)
levels(data$alg_name)[levels(data$alg_name) == "B-aggzeros"] = "B-aggz"
levels(data$alg_name)[levels(data$alg_name) == "Q-native"] = "Q-nat"
levels(data$alg_name)[levels(data$alg_name) == "Q-phases"] = "Q-phas"

e = data %>% filter(jobs_done >= (jobs_total - 9998))
e$time_per_100k = e$elapsed / (e$jobs_done / 100000)
ggplot(e, aes(alg_name, time_per_100k, fill=alg_name)) + geom_boxplot()  + theme(legend.position=c(0.2, 0.7)) + xlab("Algorithm") + ylab("Runtime in s per 100k jobs") + stat_summary(aes(label=round(..y..,0)), position = position_nudge(x = 0, y = 200), fun=mean, geom="text", size=4) + theme(legend.title = element_blank())
ggsave(paste(prefix, "-boxplot.png", sep=""), width=4, height=4)

# Development when adding more jobs
ggplot(data, aes(x=jobs_done, y=elapsed, color=alg_name)) + geom_point() + ylab("Cummulative runtime in s") + xlab("Jobs processed") + theme(legend.position = "bottom") #+ scale_x_log10() + scale_y_log10()
ggsave(paste(prefix, "-cummulative.png", sep=""), width=6, height=4.5)
