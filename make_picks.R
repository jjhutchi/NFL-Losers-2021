# Data pre-processing -------------------

# Model Inputs 
total_weeks <- 10
time_period <- c(3:total_weeks)
past_picks <- c("DAL")
past_weeks <- c(1)

pacman::p_load(data.table, ggplot2, ggalt, dplyr, knitr, kableExtra)

path <- "https://projects.fivethirtyeight.com/nfl-api/nfl_elo_latest.csv"
week1 <- as.Date("2021-09-09")

dt <- fread(path)

# calculate week, get proj loser and prob of loss. 

dt[, loser:=ifelse(qbelo_prob1 > qbelo_prob2, team2, team1)]
dt[, p_win:=ifelse(qbelo_prob1 > qbelo_prob2, qbelo_prob2, qbelo_prob1)]
dt[, week:=floor(as.numeric(difftime(date, week1, units="days")) / 7) + 1]

cols <- c("week", "loser", "p_win")
dt <- dt[, .(week, loser, p_win)]

dt <- dt[week %in% time_period]

dt <- dt[!loser %in% past_picks]

# Approach functions ----------------------
join_picks <- function(past_weeks, past_picks){
  picks <- setDT(data.frame(week = past_weeks, loser = past_picks))
  picks <- merge(picks, dt, on = week)
  
  return(picks)
}

by_week <- function(past_picks, past_weeks, start_week = 3, total_weeks = 13){
  
  # loop through filling in each week
  for(i in start_week:total_weeks){
    pick <- dt[!loser %in% past_picks & week == i]
    pick <- pick[order(week, p_win)]
    pick <- pick[, .SD[1]]
    
    past_weeks <- append(past_weeks, pick$week)
    past_picks <- append(past_picks, pick$loser)
    
  }
  
  picks <- join_picks(past_weeks, past_picks)
  
  return(picks)
}

by_prob <- function(past_picks, past_weeks, start_week = 3, total_weeks = 13){
  
  for(i in start_week:total_weeks){
    
    pick <- dt[week %in% c(start_week:total_weeks)]
    pick <- pick[!loser %in% past_picks & !week %in% past_weeks]
    pick <- pick[order(p_win)]
    pick <- pick[, .SD[1]]
    
    past_weeks <- append(past_weeks, pick$week)
    past_picks <- append(past_picks, pick$loser)
    
  }
  
  picks <- join_picks(past_weeks, past_picks)
  
  return(picks)
}

by_oc <- function(past_picks, past_weeks, start_week = 3, total_weeks = 13){
  
  for(i in start_week:total_weeks){
    
    pick <- dt[week %in% c(start_week:total_weeks)]
    pick <- pick[!week %in% past_weeks & !loser %in% past_picks, ]
    pick <- pick[order(week, p_win)]
    pick[, oc:= shift(p_win, 1, type="lead") - p_win, by = week]
    pick <- pick[, .SD[1], week]
    pick <- pick[order(-oc)]
    pick <- pick[, .SD[1]]
    
    past_weeks <- append(past_weeks, pick$week)
    past_picks <- append(past_picks, pick$loser)
    
  }
  
  picks <- join_picks(past_weeks, past_picks)
  
  return(picks)
}

# Calculate picks -------------------------
picks1 <- by_week(past_picks, past_weeks)
picks2 <- by_prob(past_picks, past_weeks)
picks3 <- by_oc(past_picks, past_weeks)

# Descriptive Statistics ------------------

# Table
tbl <- merge(picks1, picks2, by = ("week"), suffixes = c("_week", "_prob"))
tbl <- merge(tbl, picks3, by = ("week"))

avg <- tbl[, lapply(.SD, mean, na.rm=TRUE), .SD]
avg <- avg[, 2:7]
avg <- cbind("Avg", avg)
names(avg) <- names(tbl)

sd <- tbl[, lapply(.SD, sd, na.rm=TRUE), .SD]
sd <- sd[, 2:7]
sd <- cbind("SD", sd)
names(sd) <- names(tbl)

tbl <- rbind(tbl, avg, sd)

names <- c("Week", rep(c("Pick", "Win%"), 3))
names(tbl) <- names


kbl(tbl, digits=3) %>%
  kable_classic(full_width=F) %>%
  add_header_above(c(" " = 1, "By Week" = 2, "By Prob" = 2, "By Opp. Cost" = 2)) %>%
  row_spec(nrow(tbl) - 1, bold = TRUE) %>%
  row_spec(nrow(tbl), bold = TRUE) 

# Plots
picks1$Approach <- "By Week"
picks2$Approach <- "By Probability"
picks3$Approach <- "By Opp. Cost"
data <- rbind(picks1, picks2, picks3)

ggplot() + 
  geom_point(data = dt, aes(x = week, y = p_win), 
             color = "grey", 
             alpha = 0.4) +
  geom_point(data = data,
             aes(x = week, y = p_win, color = Approach, shape = Approach),
             size = 3,
             alpha = 0.7) +
  scale_color_viridis_d() + 
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(title = "Weekly picks against possible picks", 
       y = "Win %", 
       x = "Week Number") + 
  coord_flip()
