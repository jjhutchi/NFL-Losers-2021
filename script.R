pacman::p_load(data.table, tidyverse, knitr, kableExtra, ggalt)

# Data preprocessing ----------------------------------------------------------
path <- "https://projects.fivethirtyeight.com/nfl-api/nfl_elo_latest.csv"
week1 <- as.Date("2021-09-09")

df <- fread(path)

# calculate week, get proj loser and prob of loss. 
total_weeks <- 13
time_period <- seq(1, total_weeks, 1)

df <- df %>%
  mutate(loser = ifelse(qbelo_prob1 > qbelo_prob2, team2, team1),
         week = floor(as.numeric(difftime(date, week1, units="days")) / 7) + 1,
         p_win = ifelse(qbelo_prob1 > qbelo_prob2, qbelo_prob2, qbelo_prob1)) %>%
  select(week, loser, p_win) %>%
  filter(week %in% time_period)

# Calculate opportunity cost per pick -----------------------------------------

opp_cost <- function(data, weeks, teams){
  
  most_constrained <- function(data, weeks, teams){
    # select the team & week pair with the greatest opportunity cost
    tmp <- data %>% 
      filter(
        !loser %in% teams, 
        !week %in% weeks
      ) %>%
      group_by(week) %>%
      arrange(week, p_win) %>% 
      mutate(diff = lead(p_win, 1) - p_win) %>%
      slice(1L) %>%
      ungroup() %>%
      mutate(rank = rank(-diff)) %>%
      filter(rank == 1) %>%
      select(week, loser, p_win)
    
    return(tmp)
  }
  
  picks <- list()
  
  # make all weekly picks
  i <- 1
  while(i <= total_weeks){
    
    if(i<=length(teams)){
      # remove already picked weeks and teams
      pick <- data %>% 
        filter(week == i) %>%
        filter(loser == teams[i])
    } else {
      pick <- most_constrained(data, weeks, teams)
      teams <- append(teams, pick$loser)
      weeks <- append(weeks, pick$week)
    }
    
    picks[[i]] <- pick
    i = i + 1 
    
  }
  
  # bind picks together
  picks <- do.call(rbind.data.frame, picks)
  picks <- arrange(picks, week)
  
  labs <- c("Week", "Team", "ProbWin")
  names(picks) <- labs
  
  return(picks)
}

# Input previous picks and set weeks to solve over ----------------------------
teams <- c("DAL")
total_weeks <- 13
weeks <- c(seq(1, length(teams), 1))

picks <- opp_cost(df, weeks, teams)

# Print table of results
kable(picks, digits = 2) %>%
  kable_classic(full_width = F)

# Check other permutations of picks -------------------------------------------

obj <- sum(picks$ProbWin)

# keep only a sample of picks
tmp <- sample_n(picks, 3)
j <- length(tmp)

weeks <- tmp$Week
teams <- tmp$Team

# fill in the remainder of picks
picks <- list()

most_constrained <- function(data, weeks, teams){
  # select the team & week pair with the greatest opportunity cost
  tmp <- data %>% 
    filter(
      !loser %in% teams, 
      !week %in% weeks
    ) %>%
    group_by(week) %>%
    arrange(week, p_win) %>% 
    mutate(diff = lead(p_win, 1) - p_win) %>%
    slice(1L) %>%
    ungroup() %>%
    mutate(rank = rank(-diff)) %>%
    filter(rank == 1) %>%
    select(week, loser, p_win)
  
  return(tmp)
}

while(j <= total_weeks){
  print(j)
  if(j <= length(teams)){
    # remove already picked weeks and teams
    pick <- df %>% 
      filter(week == j) %>%
      filter(loser == teams[j])
  } else {
    pick <- most_constrained(df, weeks, teams)
    teams <- append(teams, pick$loser)
    weeks <- append(weeks, pick$week)
  }
  
  picks[[j]] <- pick
  j = j + 1 
  
}

picks <- do.call(rbind.data.frame, picks)
picks <- arrange(picks, week)

labs <- c("Week", "Team", "ProbWin")
names(picks) <- labs

picks <- rbind(picks, tmp)
picks <- arrange(picks, Week)

test <- sum(picks$ProbWin)

print(paste(test, obj, test<obj))

