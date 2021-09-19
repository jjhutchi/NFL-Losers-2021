source("pick_functions.R")

# setup ---- 
path <- "https://projects.fivethirtyeight.com/nfl-api/nfl_elo_latest.csv"
week1 <- as.Date("2021-09-09")
total_weeks <- 10
start_week <- 3
time_period <- c(start_week:total_weeks)
past_picks <- c("DAL")
past_weeks <- c(1)

dt <- read_data(path)
oc <- by_oc(past_picks, past_weeks, beta = 1)
oc9 <- by_oc(past_picks, past_weeks, beta = 0.9)
oc7 <- by_oc(past_picks, past_weeks, beta = 0.7)
wk <- by_week(past_picks, past_weeks)
pb <- by_prob(past_picks, past_weeks)

# simulations ----------------------------------------
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

get_proportion <- function(outcome){
  setDT(outcome)[order(-week)][, .(prop=.N / N), by=.(week)][, cumprob:=cumsum(prop)]
}

call_sim <- function(teams, N, lab){
  results <- list()
  for(i in 1:N){
    results[i] <- sim(teams)
  }
  results <- do.call(rbind.data.frame, results)
  names(results) <- c("week")
  
  results <- get_proportion(results)
  results$model <- lab
  results$week <- results$week + start_week
  results
}

N <- 100000
opp_cost <- call_sim(oc, N, "Oppertunity Cost")
opp_cost_9 <- call_sim(oc9, N, "Oppertunity Cost, beta = 0.9")
opp_cost_7 <- call_sim(oc7, N, "Oppertunity Cost, beta = 0.7")
week <- call_sim(wk, N, "Lowest per week")
prob <- call_sim(pb, N, "Lowest probability overall")

# Compare models
data <- rbind(opp_cost, week, prob, opp_cost_9, opp_cost_7)

ggplot(data, aes(x = week, y = cumprob, color = model)) + 
  geom_line(se = F) + 
  geom_point(alpha = 0.8) + 
  scale_x_continuous(expand = c(0, 0), limits = c(3, 12)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1)) + 
  labs(title = "Cumulative probability of reaching a given week",
       x = "Week number", 
       y = "Pr(X < x)") + 
  theme_classic(10)

  

