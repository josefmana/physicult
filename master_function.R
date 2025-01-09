#
# This is a script used to define the primary function for running targets pipeline
# and presenting results.
#

analyse_body_composition <- function(
    
  show = 12, # How many days back to show of moving averages?
  step = 14, # How many days use for the time window for moving average calculations?
  lag = 30, # How big lag (in days) to use for gain scores calculations?
  df = 33, # How many degrees of freedom to use for the basis spline in the top plot?
  plot_x = "weight", # What variable ought to be plotted on x-axis of the bottom plot?
  plot_y = "chest_cm", # What variable ought to be plotted on y-axis of the bottom plot?
  cap_top = "Evolution of bodyweight (points) with trend fitted via basis spines (line)",
  cap_bottom = "Comparison of selected measure (ordinate) betweeen bulk/cut cycles (colour) conditional on weight (abscissa).\nGenerally, lines to the left and up compared to previous cyclec imply success.",
  add_new_line = T,
  new_line = c(
    place        = NA,
    weight_kg    = NA,
    phase        = NA,
    waist_cm     = NA,
    chest_cm     = NA,
    neck_cm      = NA,
    R_thigh_cm   = NA,
    R_calf_cm    = NA,
    L_thigh_cm   = NA,
    L_calf_cm    = NA,
    R_arm_cm     = NA,
    R_forearm_cm = NA,
    L_arm_cm     = NA,
    L_forearm_cm = NA
  )
    
) {
  
  #
  # read current data
  data <- read.csv("body_comp.csv", sep = ",")
  
  #
  # if there is a call for a new line, add it
  if (add_new_line == T) write.table(
    
    x = rbind(
      
      data,
      c(
        day = with( # find out which day should be added
          data,
          case_when(
            tail(day, 1) == "Mon" ~ "Tue",
            tail(day, 1) == "Tue" ~ "Wed",
            tail(day, 1) == "Wed" ~ "Thu",
            tail(day, 1) == "Thu" ~ "Fri",
            tail(day, 1) == "Fri" ~ "Sat",
            tail(day, 1) == "Sat" ~ "Sun",
            tail(day, 1) == "Sun" ~ "Mon"
          )
        ),
        date = (as.Date( tail(data$date, 1) ) + 1) %>% as.character(),
        new_line
      )
      
      
    ),
    
    file = "body_comp.csv",
    quote = F,
    row.names = F,
    sep = ","
    
  )
  

  #
  # write captions to the plot
  cap1 <- paste0("Top: ", cap_top)
  cap2 <- paste0("Bottom: ", cap_bottom)
  
  #
  # set-up a file with settings
  write.table(
    x = rbind(
      c(var = "show", val = show, meaning = "How many days back to show of moving averages?"),
      c(var = "step", val = step, meaning = "How many days use for the time window for moving average calculations?"),
      c(var = "lag", val = lag, meaning = "How big lag (in days) to use for gain scores calculations?"),
      c(var = "df", val = df, meaning = "How many degrees of freedom to use for the basis spline in the top plot?"),
      c(var = "plot_x", val = plot_x, meaning = "What variable ought to be plotted on x-axis of the bottom plot?"),
      c(var = "plot_y", val = plot_y, meaning = "What variable ought to be plotted on y-axis of the bottom plot?")
    ),
    file = "settings.csv",
    sep = ";",
    row.names = F,
    quote = F
  )
  
  #
  # run the pipeline
  tar_make()
  
  #
  # read settings in an appropriate format
  tar_load("settings")
  
  #
  # show table with moving averages & gain scores
  tar_load("gains_summary")
  print(tail(gains_summary, settings$show), n = settings$show) # function output #1
  
  #
  # print the message regarding current phase
  tar_load("message")
  cat(message) # function output #2
  
  #
  # plot it
  plt_A <- tar_read("raw_plot")
  plt_B <- tar_read_raw( paste0(settings$plot_x,"_plots") )[[settings$plot_y]]
  plt <- plt_A / plt_B + plot_annotation( caption = paste(cap1, cap2, sep = "\n") )
  print(plt) # function output #3

}
