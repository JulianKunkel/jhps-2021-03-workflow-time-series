#!/usr/bin/env Rscript

# Parse job from command line
args = commandArgs(trailingOnly = TRUE)
filename = args[1]

library(ggplot2)
library(dplyr)
require(scales)
library(stringi)
library(stringr)

# Turn to TRUE to print individual job images
plotjobs = TRUE

# Color scheme
plotcolors <- c("#CC0000", "#FFA500", "#FFFF00", "#008000", "#9999ff", "#000099")

if (! exists("filename")){
  filename = "./datasets/job_similarities_5024292.csv"
  filename = "./datasets/job_similarities_7488914.csv" # for manual execution
}
print(filename)
jobID = str_extract(filename, regex("[0-9]+"))

data = read.csv(filename)
# Columns are: jobid alg_id alg_name similarity

#data$alg_id = as.factor(data$alg_id) # EB: falsche Spalte?
data$alg_name = as.factor(data$alg_name) # EB: im Script wird diese Spalte benutzt
cat("Job count:")
cat(nrow(data))

# empirical cumulative density function (ECDF)
data$sim = data$similarity*100
ggplot(data, aes(sim, color=alg_name, group=alg_name)) + stat_ecdf(geom = "step") + xlab("Similarity in %") + ylab("Fraction of jobs") + theme(legend.position=c(0.9, 0.5),  legend.title = element_blank()) + scale_color_brewer(palette = "Set2") # + scale_x_log10() +
ggsave("ecdf.png", width=8, height=2.5)

# histogram for the jobs
ggplot(data, aes(sim), group=alg_name) + geom_histogram(color="black", binwidth=2.5) + aes(fill = alg_name) + facet_grid(alg_name ~ ., switch = 'y') + xlab("Similarity in %") + scale_y_continuous(limits=c(0, 100), oob=squish)  +   scale_color_brewer(palette = "Set2") + ylab("Count (cropped at 100)") + theme(legend.position = "none") + stat_bin(binwidth=2.5, geom="text", adj=1.0, angle = 90, colour="black", size=3, aes(label=..count.., y=0*(..count..)+95))
ggsave("hist-sim.png", width=6, height=5)

#ggplot(data, aes(similarity, color=alg_name, group=alg_name)) + stat_ecdf(geom = "step") + xlab("SIM") + ylab("Fraction of jobs") + theme(legend.position=c(0.9, 0.4))  + scale_color_brewer(palette = "Set2") + xlim(0.5, 1.0)
#ggsave("ecdf-0.5.png", width=8, height=3)

print("Similarity > 0.5")
e = data %>% filter(similarity >= 0.5)
print(summary(e))

# load job information, i.e., the time series per job
jobData = read.csv("./datasets/job_codings_v3.csv") # EB: liegt jetzt Repo. v3 hat die korrekten hexadezimalen Codings
metadata = read.csv("./datasets/job_metadata.csv") # EB: is ebenfalls im Repo
metadata$user_id = as.factor(metadata$user_id)
metadata$group_id = as.factor(metadata$group_id)

plotJobs = function(algorithm, jobs){
    # print the job timelines
    r = e[ordered, ]

    if (plotjobs) {
      if(algorithm == "ks"){
        script = "./scripts/plot-job-timelines-ks.py"
      }else{
        script = "./scripts/plot-job-timelines.py"
      }
      prefix = do.call("sprintf", list("%s-%.4f-", level, r$similarity))
      call = sprintf("%s %s %s", script, paste(r$jobid, collapse=","), paste(prefix, collapse=","))
      print(call)
      system(call)
    }

    system(sprintf("./scripts/extract-conf-data.sh %s > jobs-%s.txt", paste(r$jobid, collapse=" "), level))
  }

# Store the job ids in a table, each column is one algorithm
dim = length(levels(data$alg_name))
count = 100
result = matrix(1:(dim*count), nrow=count, ncol=dim) # will contain the job ids for the count best jobs
colnames(result) = levels(data$alg_name)
result.userid = tibble() # will contain the userid for the count best jobs

# Extract the 100 most similar jobs into the table
for (level in levels(data$alg_name)){
    e = data %>% filter(alg_name == level)
    print(level)
    print(summary(e))
    ordered = order(e$similarity, decreasing=TRUE)[1:count]
    print(e[ordered,])
    # Extract the data for the jobs
    jobs = e[ordered,"jobid"]
    result[, level] = jobs

    # extract details about the jobs of a given algorithm
    tbl = jobData[jobData$jobid %in% jobs,]
    print(summary(tbl))
    md = metadata[metadata$jobid %in% jobs,]
    print(summary(md))
    md$value = 1
    userprofile = md %>% group_by(user_id) %>% summarise(count = sum(value))
    userprofile = userprofile[order(userprofile$count, decreasing=TRUE),]
    userprofile$userrank = 1:nrow(userprofile)
    result.userid = rbind(result.userid, cbind(level, userprofile))

    plotJobs(level, jobs)
}

colnames(result.userid) = c("alg_name", "user_id", "count", "userrank")

print(result.userid)

# Create stacked user table
ggplot(result.userid, aes(fill=userrank, y=count, x=alg_name)) + geom_bar(position="stack", stat="identity") + theme(legend.position = "none") + scale_fill_gradientn(colours=rainbow(5)) + ylab("Stacked user count") + xlab("Algorithm") # + scale_fill_gradient(low="blue", high="red", space ="Lab" ) + scale_fill_continuous(type = "viridis")

ggsave("user-ids.png", width=6, height=4)


# Compute intersection in a new table
res.intersect = matrix(1:(dim*dim), nrow=dim, ncol=dim)
colnames(res.intersect) = levels(data$alg_name)
rownames(res.intersect) = levels(data$alg_name)

tbl.intersect = expand.grid(first=levels(data$alg_name), second=levels(data$alg_name))
tbl.intersect$intersect = 0

for (l1 in levels(data$alg_name)){
  for (l2 in levels(data$alg_name)){
    res = length(intersect(result[,l1], result[,l2]))
    res.intersect[l1,l2] = res
    tbl.intersect[tbl.intersect$first == l1 & tbl.intersect$second == l2, ]$intersect = res
  }
}

print(res.intersect)

# Plot heatmap about intersection
ggplot(tbl.intersect, aes(first, second, fill=intersect)) + geom_tile() + geom_text(aes(label = round(intersect, 1))) + scale_fill_gradientn(colours = rev(plotcolors)) + xlab("") + ylab("")  + theme(legend.position = "bottom", legend.title = element_blank())
ggsave("intersection-heatmap.png", width=5, height=5)

# Collect the metadata of all jobs in a new table
res.jobs = tibble()
for (alg_name in levels(data$alg_name)){
  res.jobs = rbind(res.jobs, cbind(alg_name, metadata[metadata$jobid %in% result[, alg_name],]))
}

# Plot histogram of nodes per algorithm
jobRef = metadata[metadata$jobid == jobID,]$total_nodes
ggplot(res.jobs, aes(alg_name, total_nodes, fill=alg_name)) + geom_boxplot() + scale_y_continuous(trans = log2_trans(), breaks = trans_breaks("log2", function(x) 2^x), labels = trans_format("log2", math_format(2^.x))) + theme(legend.position = "none") + xlab("Algorithm") + ylab("Job node count")  + geom_hline(yintercept= jobRef, linetype="dashed", color = "red", size=0.5)
ggsave("jobs-nodes.png", width=6, height=4)

# Plot histogram of elapsed time per algorithm
jobRef = metadata[metadata$jobid == jobID,]$elapsed
ggplot(res.jobs, aes(alg_name, elapsed, fill=alg_name)) + geom_boxplot() + ylab("Job runtime in s") + xlab("Algorithm")  + theme(legend.position = "none") + ylim(0, max(res.jobs$elapsed)) + geom_hline(yintercept= jobRef, linetype="dashed", color = "red", size=0.5)
#  scale_y_continuous(trans = log2_trans(), breaks = trans_breaks("log10", function(x) 10^x), labels = trans_format("log10", math_format(10^.x)))
ggsave("jobs-elapsed.png", width=6, height=4)




# scale_y_continuous(trans = log2_trans(), breaks = trans_breaks("log2", function(x) 2^x), labels = trans_format("log2", math_format(2^.x)))

# stat_summary(aes(linetype = alg_id), fun.y=mean, geom="line")
