#!/usr/bin/env python3

import csv
import sys
import pandas as pd
from pandas import DataFrame
from pandas import Grouper
import seaborn as sns
from matplotlib import pyplot
import matplotlib.cm as cm

jobs = sys.argv[1].split(",")
prefix = sys.argv[2].split(",")

fileformat = ".pdf"

print("Plotting the job: " + str(sys.argv[1]))
print("Plotting with prefix: " + str(sys.argv[2]))


# Color map
colorMap = { "md_file_create": cm.tab10(0),
"md_file_delete": cm.tab10(1),
"md_mod": cm.tab10(2),
"md_other": cm.tab10(3),
"md_read": cm.tab10(4),
"read_bytes": cm.tab10(5),
"read_calls": cm.tab10(6),
"write_bytes": cm.tab10(7),
"write_calls": cm.tab10(8)
}

markerMap = { "md_file_create": "^",
"md_file_delete": "v",
"md_other": ".",
"md_mod": "<",
"md_read": ">",
"read_bytes": "h",
"read_calls": "H",
"write_bytes": "D",
"write_calls": "d"
}

linestyleMap = { "md_file_create": ":",
"md_file_delete": ":",
"md_mod": ":",
"md_other": ":",
"md_read": ":",
"read_bytes": "--",
"read_calls": "--",
"write_bytes": "-.",
"write_calls": "-."
}

# Plot the timeseries
def plot(prefix, header, row):
  x = { h : d for (h, d) in zip(header, row)}
  jobid = x["jobid"]
  del x["jobid"]
  result = []
  for k in x:
    timeseries = x[k].split(":")
    timeseries = [ float(x) for x in timeseries]
    if sum(timeseries) == 0:
      continue
    timeseries = [ [k, x, s] for (s,x) in zip(timeseries, range(0, len(timeseries))) ]
    result.extend(timeseries)

  if len(result) == 0:
    print("Empty job! Cannot plot!")
    return

  data = DataFrame(result, columns=["metrics", "segment", "value"])
  groups = data.groupby(["metrics"])
  metrics = DataFrame()
  labels = []
  colors = []
  style = []
  for name, group in groups:
    style.append(linestyleMap[name] + markerMap[name])
    colors.append(colorMap[name])
    if name == "md_file_delete":
      name = "file_delete"
    if name == "md_file_create":
      name = "file_create"
    try:
      metrics[name] = pd.Series([x[2] for x in group.values])
    except:
      print("Error processing %s with" % jobid)
      print(group.values)
      return

    labels.append(name)

  fsize = (8, 1 + 1.1 * len(labels))
  fsizeFixed = (8, 2)
  fsizeHist = (8, 6.5)

  pyplot.close('all')

  if len(labels) < 4 :
    ax = metrics.plot(legend=True, sharex=True, grid = True,  sharey=True, markersize=10, figsize=fsizeFixed, color=colors, style=style)
    ax.set_ylabel("Value")
  else:
    ax = metrics.plot(subplots=True, legend=False, sharex=True, grid = True,  sharey=True, markersize=10, figsize=fsize, color=colors, style=style)
    for (i, l) in zip(range(0, len(labels)), labels):
      ax[i].set_ylabel(l)

  pyplot.xlabel("Segment number")
  pyplot.savefig(prefix + "timeseries" + jobid + fileformat, bbox_inches='tight', dpi=150)

  # Create a facetted grid
  #g = sns.FacetGrid(tips, col="time", margin_titles=True)
  #bins = np.linspace(0, 60, 13)
  #g.map(plt.hist, "total_bill", color="steelblue", bins=bins)
  ax = metrics.hist(grid = True, sharey=True, figsize=fsizeHist, bins=15, range=(0, 15))
  pyplot.xlim(0, 15)
  pyplot.savefig(prefix + "hist" + jobid + fileformat, bbox_inches='tight', dpi=150)


  # Plot first 30 segments
  if len(timeseries) <= 50:
    return

  if len(labels) < 4 :
    ax = metrics.plot(legend=True, xlim=(0,30), sharex=True, grid = True,  sharey=True, markersize=10, figsize=fsizeFixed, color=colors, style=style)
    ax.set_ylabel("Value")
  else:
    ax = metrics.plot(subplots=True, xlim=(0,30), legend=False, sharex=True, grid = True,  sharey=True, markersize=10, figsize=fsize, color=colors, style=style)
    for (i, l) in zip(range(0, len(labels)), labels):
      ax[i].set_ylabel(l)

  pyplot.xlabel("Segment number")
  pyplot.savefig(prefix + "timeseries" + jobid + "-30" + fileformat, bbox_inches='tight', dpi=150)

### end plotting function



#with open('job-io-datasets/datasets/job_codings.csv') as csv_file: # EB: old codings
with open('./datasets/job_codings_v4.csv') as csv_file: # EB: v3 codings moved to this repo
    csv_reader = csv.reader(csv_file, delimiter=',')
    line_count = 0
    for row in csv_reader:
      if line_count == 0:
        header = row
        line_count += 1
        continue
      job = row[0].strip()
      if not job in jobs:
        continue
      else:
        index = jobs.index(job)
        plot(prefix[index] + "-ks-" + str(index), header, row)
