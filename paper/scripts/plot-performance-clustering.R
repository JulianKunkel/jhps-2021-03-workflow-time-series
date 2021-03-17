#!/usr/bin/env Rscript
library(ggplot2)
library(dplyr)
require(scales)

# Plot the performance numbers of the clustering

data = read.csv("datasets/clustering_progress.csv")

e = data %>% filter(sim_param %in% c(0.1, 0.5, 0.99))
e$percent = paste("SIM =", as.factor(round(e$sim_param*100,0)), " %")

# Development when adding more jobs
ggplot(e, aes(x=jobs_done, y=elapsed, color=alg_name)) + geom_point() + facet_grid(percent ~ .) + ylab("Cummulative runtime in s") + xlab("Jobs processed") + scale_y_log10() + theme(legend.position = "bottom")
ggsave("fig/runtime-cummulative.png", width=6, height=4.5)

# Bar chart for the maximum
e = data %>% filter(jobs_done >= (jobs_total - 9998))
e$percent = as.factor(round(e$sim_param*100,0))
ggplot(e, aes(y=elapsed, x=percent, fill=alg_name)) + geom_bar(stat="identity") + facet_grid(. ~ alg_name, switch = 'y') + scale_y_log10()  + theme(legend.position = "none") + ylab("Runtime in s") + xlab("Minimum similarity in %") + geom_text(aes(label = round(elapsed,0), angle = 90, y=0*(elapsed)+20))
ggsave("fig/runtime-overview.png", width=7, height=2)
