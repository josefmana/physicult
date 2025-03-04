#
# THE SCRIPT RUNNING ANALYSIS OF THE BODY COMPOSITION DATA
#
# The script loads packages & runs the primary function governing analysis pipeline.
# The primary function is called 'analyse_body_composition', is called in the bottom
# of this script and can take in varying inputs as detailed below.
#
# Before summoning the workhorse of this code, i.e., the `analyse_body_composition()` function,
# several preparatory steps need to be taken including:
#
#   1. load required packages
#   2. set warnings off to clean the output
#   3. load the function itself
#
# Subsequently, the `analyse_body_composition()` can be run or re-run as often as desired.
# 
# `analyse_body_composition()` takes in the following inputs:
#
#   - 'show' controls how many days back to show of moving averages in results table, default is show = 12
#   - 'step' controls how many days to use for the time window for moving average calculations, default is step = 14
#   - 'lag' controls how big lag (in days) to use for gain scores calculations, default is lag = 30
#   - 'df' controls the wiggliness via degrees of freedom used in a basis spline regression of weight on time in the top plot, default is df = 33
#   - 'plot_x' selects variable to be plotted on abscissa (x-axis) of the bottom plot, default is plot_x = "weight"
#   - 'plot_y' selects variable to be plotted on ordinate (y-axis) of the bottom plot, default is plot_y = "chest_cm"
#   - 'cap_top' gives caption for the plot that will be printed in the bottom right as first reading "Top: cap_top"
#   - 'cap_bottom' gives caption for the plot that will be printed in the bottom right as second reding "Bottom: cap_bottom"  
#
# The 'show', 'step', 'lag' and 'df' arguments take in any single number.
# The 'cap_top' and 'cap_bottom' arguments take in any single string of text.
# The 'plot_x' argument takes in one of the following: c("time", "weight", "waist")
# The 'plot_y' argument takes in one of the following: c("weight_kg", "waist_cm", "chest_cm", "neck_cm", "R_thigh_cm",
#                                                        "R_calf_cm", "L_thigh_cm", "L_calf_cm", "R_arm_cm", L_arm_cm",
#                                                        "R_forearm_cm", "L_forearm_cm")
#

library(targets)   # to run the pipeline
library(tidyverse) # to add new data
library(patchwork) # to arrange plots

#
# prevent ggplot from showing warning messages under the results
options(warn = -1)

#
# read the function to be used
source("master_function.R")

#
# run the analysis
analyse_body_composition(

  show = 15,
  step = 14,
  lag = 30,
  df = 33,
  plot_x = "waist",
  plot_y = "chest_cm",
  cap_top = "Evolution of bodyweight (points) with trend fitted via basis spines (line)",
  cap_bottom = "Comparison of selected measure (ordinate) betweeen bulk/cut cycles (colour) conditional on weight (abscissa)
  Generally, lines to the left and up in the bottom plot compared to previous cycles imply success.",

  add_new_line = F,
  new_line = c(

    place        = "Prague",
    weight_kg    = 72.0,
    phase        = "bulk",
    waist_cm     = 77.3,
    chest_cm     = 112.7,
    neck_cm      = 34.7,
    R_thigh_cm   = NA,
    R_calf_cm    = NA,
    L_thigh_cm   = NA,
    L_calf_cm    = NA,
    R_arm_cm     = NA,
    R_forearm_cm = NA,
    L_arm_cm     = NA,
    L_forearm_cm = NA

  )

)

#
# The `analyse_body_composition()` can be re-run with different (or the same) specifications as often as desired.
#
