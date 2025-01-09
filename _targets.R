# 
#
#

# Load packages required to define the pipeline:
library(targets)

# Set target options:
tar_option_set(
  packages = c(
    "here",
    "tidyverse",
    "splines"
  )
)

# Run the R scripts in the R/ folder with custom functions:
tar_source()

# List the targets:
list(
  
  #
  ## PREPARE DATA ----
  tar_target( # set-up path to settings
    name = settings_file,
    command = here("settings.csv"),
    format = "file"
  ),
  tar_target( # pre-process settings
    name = settings,
    command = read_settings(file = settings_file)
  ),
  tar_target( # colour palette
    name = palette,
    command = set_colours()
  ),
  tar_target( # set-up path to data
    name = data_file,
    command = here("body_comp.csv"),
    format = "file"
  ),
  tar_target( # read & prepare the data
    name = data,
    command = import_data(file = data_file, palette = palette)
  ),
  tar_target( # extract outcome names
    name = outcomes,
    command = extract_outcomes(data = data)
  ),
  
  #
  ## PLOT DATA ----
  tar_target( # prepare a plot of raw weight measures in time
    name = raw_plot,
    command = plot_weight(data = data, set = settings)
  ),
  tar_target( # prepare plots documenting each phase in each measure
    name = time_plots,
    command = plot_by_phase(data = data, pal = palette, outs = outcomes)
  ),
  tar_target( # prepare plots documenting each phase in each measure with respect to weight
    name = weight_plots,
    command = plot_by_phase(data = data, pal = palette, outs = outcomes, p = c("bulk", "cut"), x = "weight_kg", line = "loess")
  ),
  tar_target( # prepare plots documenting each phase in each measure with respect to waist size
    name = waist_plots,
    command = plot_by_phase(data = data, pal = palette, outs = outcomes, p = c("bulk", "cut"), x = "waist_cm", line = "loess")
  ),
  
  #
  ## SUMMARISE VIA MOVING AVERAGES ----
  tar_target( # calculate weight moving averages
    name = moving_averages,
    command = compute_averages(input = data$weight_kg, set = settings)
  ),
  tar_target( # locate phase changes in the data
    name = milestones,
    command = find_milestones(data = data, average = moving_averages)
  ),
  tar_target( # prepare a message summarising current phase
    name = message,
    command = get_message(milestones = milestones, set = settings)
  ),
  tar_target( # calculate gain scores
    name = gain_scores,
    command = extract_gains(x = moving_averages, set = settings)
  ),
  tar_target( # compare gain scores to observed scores and moving averages
    name = gains_summary,
    command = gain_table(data = data, gains = gain_scores, average = moving_averages)
  )
  
)
