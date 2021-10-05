read_data <- function(path){
  dt <- data.table::fread(path)
  
  # calculate week, get proj loser and prob of loss. 
  
  dt[, loser:=ifelse(qbelo_prob1 > qbelo_prob2, team2, team1)]
  dt[, winner:=ifelse(qbelo_prob1 > qbelo_prob2, team1, team2)]
  dt[, p_win:=ifelse(qbelo_prob1 > qbelo_prob2, qbelo_prob2, qbelo_prob1)]
  dt[, p_win_winner:=ifelse(qbelo_prob1 > qbelo_prob2, qbelo_prob1, qbelo_prob2)]
  dt[, week:=floor(as.numeric(difftime(date, week1, units="days")) / 7) + 1]
  
  dt <- dt[, .(week, loser, winner, p_win, p_win_winner)]
  
  dt <- dt[week %in% time_period]

  dt <- dt[!loser %in% past_picks]
  
  return(dt)
}


join_picks <- function(past_weeks, past_picks){
  picks <- setDT(data.frame(week = past_weeks, loser = past_picks))
  picks <- merge(picks, dt, on = week)
  picks <- picks[, .(week, loser, p_win)]
  
  return(picks)
}

by_week <- function(past_picks, past_weeks, start_week = 3, total_weeks = 13, beta = 1){
  
  # loop through filling in each week
  for(i in start_week:total_weeks){
    pick <- dt[!loser %in% past_picks & week == i]
    pick[, value:= p_win * beta^(week - start_week)]
    pick <- pick[order(week, value)]
    pick <- pick[, .SD[1]]
    
    past_weeks <- append(past_weeks, pick$week)
    past_picks <- append(past_picks, pick$loser)
    
  }
  
  picks <- join_picks(past_weeks, past_picks)
  
  return(picks)
}

by_prob <- function(past_picks, past_weeks, start_week = 3, total_weeks = 13, beta = 1){
  
  for(i in start_week:total_weeks){
    
    pick <- dt[week %in% c(start_week:total_weeks)]
    pick <- pick[!loser %in% past_picks & !week %in% past_weeks]
    pick[, value:= p_win * beta^(week - start_week)]
    pick <- pick[order(value)]
    pick <- pick[, .SD[1]]
    
    past_weeks <- append(past_weeks, pick$week)
    past_picks <- append(past_picks, pick$loser)
    
  }
  
  picks <- join_picks(past_weeks, past_picks)
  
  return(picks)
}

by_oc <- function(past_picks, past_weeks, start_week = 3, total_weeks = 13, beta = 1){
  
  for(i in start_week:total_weeks){
    
    pick <- dt[week %in% c(start_week:total_weeks)]
    pick <- pick[!week %in% past_weeks & !loser %in% past_picks, ]
    pick <- pick[order(week, p_win)]
    pick[, oc:= shift(p_win, 1, type="lead") - p_win, by = week]
    pick[, oc:= oc * beta^(week - start_week)]
    pick <- pick[, .SD[1], week]
    pick <- pick[order(-oc)]
    pick <- pick[, .SD[1]]
    
    past_weeks <- append(past_weeks, pick$week)
    past_picks <- append(past_picks, pick$loser)
    
  }
  
  picks <- join_picks(past_weeks, past_picks)
  
  return(picks)
}

optimal_rebuy_picks <- function(dt, picks){
  
  dt <- fread(path)
  dt[, loser:=ifelse(qbelo_prob1 > qbelo_prob2, team2, team1)]
  dt[, p_win:=ifelse(qbelo_prob1 > qbelo_prob2, qbelo_prob2, qbelo_prob1)]
  dt[, week:=floor(as.numeric(difftime(date, week1, units="days")) / 7) + 1]
  
  cols <- c("week", "loser", "p_win")
  dt <- dt[, .(week, loser, p_win)]
  
  dt <- dt[!loser %in% past_picks]
  
  pick <- dt[!loser %in% picks1$loser]
  pick <- pick[order(week, p_win)]
  pick <- pick[, .SD[1], week][1:2]
  print(pick)
  
  return(pick)
  
}

# simulations ----------------------------------------


# Estimates the losers pool based on a set of picks
# For each week, draws a uniform variable, if rv is 
# less than teams win probability, the team wins, and 
# we return the total weeks until a win. Otherwise 
# we move to the next week. 
sim <- function(teams){
  week <- 0 # index at zero. If win, move past week 1. 
  
  for(p in teams$p_win){
    rng <- runif(1, 0, 1)
    
    # simulate outcome
    if(p < rng){
      # win, move to next week
      week <- week + 1
    } else{
      # lose, leave loop and return week
      return(week)
    }
  }
  # in case win each week
  return(week)
}

# Calculates the probability of a set of picks reaching
# a given week number.
get_proportion <- function(outcome){
  setDT(outcome)[order(-week)][, .(prop=.N / N), by=.(week)][, cumprob:=cumsum(prop)]
}

# Calls sim to simulate the losers pool season based 
# on a set of picks N times. Then calls the proportion 
# function to get the CDF of outcomes, updating week 
# indicies and adds a model label.
call_sim <- function(teams, N, lab){
  results <- list()
  for(i in 1:N){
    results[i] <- sim(teams)
  }
  results <- do.call(rbind.data.frame, results)
  names(results) <- c("week")
  
  results <- get_proportion(results)
  results$week <- results$week + start_week
  results$model <- lab
  results
}