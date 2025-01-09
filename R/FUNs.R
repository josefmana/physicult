#
# This script contains custom functions for calculations regarding
# the body composition data.
#

#
# SET-UP COLOUR PALETTE ----
set_colours <- function() c("#999999","#E69F00","#56B4E9","#009E73","#F0E442","#0072B2","#D55E00","#CC79A7")

#
# PREPARE SETTINGS ----
read_settings <- function(file) read.csv(file, sep = ";") %>%
  
  select(-meaning) %>%
  column_to_rownames("var") %>%
  t() %>%
  as.data.frame() %>%
  mutate( across(c("show","step","lag","df"), as.numeric) )

#
# IMPORT THE DATA ----
import_data <- function(file, palette) read.csv(file, sep = ",") %>%
  
  mutate(
    col = case_when( # colour-coding of places
      place == "Berlin" ~ palette[1],
      place == "Jestrabi" ~ palette[3],
      place == "Prague" ~ palette[2],
      place == "Moravicany" ~ palette[6],
      .default = palette[1]
    ),
    date = as.Date(date), # re-format dates
    year = year(date), # extract year
    month = month(date), # extract month
    cycle = case_when( # link cycles to phases and years
      year == 2022 & phase != "bulk" ~ "21/22",
      year == 2023 & phase != "bulk" ~ "22/23",
      year == 2024 & phase != "bulk" ~ "23/24",
      year == 2025 & phase != "bulk" ~ "24/25",
      year == 2022 & phase == "bulk" & month < 9 ~ "21/22",
      year == 2023 & phase == "bulk" & month < 7 ~ "22/23",
      year == 2024 & phase == "bulk" & month < 9 ~ "23/24",
      year == 2025 & phase == "bulk" & month < 9 ~ "24/25",
      year == 2022 & phase == "bulk" & month > 7 ~ "22/23",
      year == 2023 & phase == "bulk" & month > 6 ~ "23/24",
      year == 2024 & phase == "bulk" & month > 7 ~ "24/25"
    ),
    day_within_observation_period = 1:n(), # observation day
    neck_cm = as.numeric(neck_cm) # re-format
    
  ) %>%
  
  group_by(phase, cycle) %>%
  mutate(
    day_within_cycle = if_else( # day within a current cycle
      phase == "bulk" & cycle == "21/22",
      row_number() + 86,
      row_number()
    )
  ) %>%
  ungroup()

#
# EXTRACT OUTCOMES OF INTEREST ----
extract_outcomes <- function(data) data %>% select( ends_with("kg"), ends_with("cm") ) %>% names()

#
# PREPARE A PLOT FOR EVOLUTION OF WEIGHT IN TIME ----
plot_weight <- function(data, set) data %>%
  
  ggplot() +
  aes(x = date, y = weight_kg) +
  geom_point( aes(colour = phase), size = 5, alpha = .2) +
  geom_smooth(method = "lm", formula = y ~ splines::bs(x = x, df = set$df), linewidth = 1.25, colour = "black") +
  theme_bw(base_size = 14) +
  theme(legend.position = "bottom")

#
# PREPARE A PLOT STRATIFIED BY PHASE ----
plot_by_phase <- function(data, pal, outs, p = c("bulk", "cut", "maintain"), x = "day_within_cycle", line = "loess") lapply(
  
  set_names(outs),
  function(y) data %>%
    
    filter(phase %in% p) %>%
    ggplot() +
    aes(x = get(x), y = get(y), colour = cycle, fill = cycle) +
    geom_point(size = 3, alpha = .3) +
    geom_smooth(method = line, formula = y ~ x) +
    scale_colour_manual(values = pal[c(3,4,2,8)]) +
    scale_fill_manual(values = alpha(pal[c(3,4,2,8)], .15) ) +
    facet_wrap(~ phase, nrow = 1, scales = "free_x") +
    labs(y = y, x = x) +
    theme_bw(base_size = 14) +
    theme(plot.title = element_text(hjust = 0.5), legend.position = "bottom")
    
)

#
# CALCULATE MOVING AVERAGES ----
compute_averages <- function(input, set) sapply(
  
  1:( length(input)-set$step+1 ),
  function(i) c(
    M = mean(input[i:(i+set$step-1)], na.rm = T), # mean
    SD = sd(input[i:(i+set$step-1)], na.rm = T), # standard deviation
    SEM = sd(input[i:(i+set$step-1)], na.rm = T) / sum( !is.na( input[i:(i+set$step)] ) ) # SEM
  )
  
) %>%
  
  # format and append k-1 NAs to the bottom
  t() %>%
  rbind.data.frame( data.frame( M = rep(NA,set$step-1), SD = NA, SEM = NA ), . )

#
# GET RID OF NAs ----
na.comit <- function(x) x %>% na.omit() %>% c()

#
# FIND PHASE CHANGES ----
find_milestones <- function(data, average) data.frame(
  
  row = sapply( 2:nrow(data), function(i) if (data$phase[i-1] == data$phase[i]) NA else i ) %>% na.comit(),
  date = sapply( 2:nrow(data), function(i) if (data$phase[i-1] == data$phase[i]) NA else data$date[i] ) %>% na.comit(),
  phase = sapply( 2:nrow(data), function(i) if (data$phase[i-1] == data$phase[i]) NA else data$phase[i] ) %>% na.comit()
  
) %>%
  
  mutate(mov_av = average$M[row]) %>%
  mutate( date = as.Date(date, format = "%d/%m/%y") ) %>%
  add_row( # add current phase
    row = nrow(data),
    date = data$date[nrow(data)],
    phase = data$phase[nrow(data)],
    mov_av = average$M[nrow(data)]
  )

#
# EXTRACT GAIN SCORES ----
extract_gains <- function(x, set) rev(
  
  sapply(
    0:( (7*set$show) - 1 ) ,
    function(i)
      x$M[nrow(x) - i] - x$M[nrow(x) - i - set$lag]
  )
  
)

#
# PREPARE A TABLE DOCUMENTING GAIN SCORES ----
gain_table <- function(gains, data, average) tail( data, length(gains) ) %>%
  
  select(day, date, place, weight_kg, phase) %>%
  cbind( round( select( tail( average, length(gains) ), M, SD ), 2 ) ) %>%
  cbind( diff = round( gains, 2 ) ) %>%
  as_tibble() %>%
  mutate( speed = paste0( sprintf( "%.2f", round( 100 * diff/M, 2 ) ),"%" ) )

#
# PREPARE A MESSAGE REGARDING CURRENT PHASE ----
get_message <- function(milestones, set) with(
  
  milestones, {
    
    # prepare info fo a message to be printed
    cur_phase <- tail(phase, 1)
    cur_start <- tail(date, 2)[1] - 1
    cur_days <- as.numeric( difftime( tail(date, 1), tail(date, 2)[1] ) )
    cur_weeks <- round(cur_days / 7, 2)
    cur_years <- round(cur_days / 365, 2)
    cur_gain <- tail(mov_av, 1) - tail(mov_av, 2)[1]
    cur_change <- round(abs(cur_gain), 2)
    cur_rate <- round( (cur_gain / cur_days ) * 30, 2)
    cur_sign <- ifelse(sign(cur_gain) == 1, "gained", "lost")
    
    return(
      paste0(
        "\nCurrent ",cur_phase," phase started on ",cur_start," and is thus so far ",
        cur_days," days (",cur_weeks," weeks, ~",cur_years," years) long,\nduring which ",
        cur_change," kg (~ ",cur_rate," kg / month) of a ",set$step,"-day moving average was ",cur_sign,"."
      )
    )
    
  }
)
