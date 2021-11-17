## Explore if we can make a model that minimizes the cumulative sum of weekly probablities. 
pacman::p_load(dplyr, data.table, ggplot2)
read_data = function(path, past_picks, all_weeks = FALSE){
  dt = data.table::fread(path)
  week1 <- as.Date("2021-09-09")
  
  # calculate week, get proj loser and prob of loss. 
  
  dt[, loser:=ifelse(qbelo_prob1 > qbelo_prob2, team2, team1)]
  dt[, winner:=ifelse(qbelo_prob1 > qbelo_prob2, team1, team2)]
  dt[, p_win:=ifelse(qbelo_prob1 > qbelo_prob2, qbelo_prob2, qbelo_prob1)]
  dt[, p_win_winner:=ifelse(qbelo_prob1 > qbelo_prob2, qbelo_prob1, qbelo_prob2)]
  dt[, week:=floor(as.numeric(difftime(date, week1, units="days")) / 7) + 1]
  dt[, loser_score:=ifelse(qbelo_prob1 > qbelo_prob2, score2, score1)]
  dt[, winner_score:=ifelse(qbelo_prob1 > qbelo_prob2, score1, score2)]
  dt = dt[, upset:=ifelse(loser_score > winner_score, TRUE, FALSE)]
  
  dt = dt[, .(week, loser, winner, p_win, p_win_winner, upset)]
  
  return(dt)
}

path = "https://projects.fivethirtyeight.com/nfl-api/nfl_elo_latest.csv"
df = read_data(path, all_weeks = TRUE)
df = tidyr::pivot_longer(df, cols = c("loser", "winner"), names_to = c("favourite"), values_to = ("team"))
df = mutate(df, p = case_when(
  favourite == "loser" ~ p_win, 
  favourite == "winner" ~ p_win_winner)) %>%
  select(week, team, p) %>%
  filter(week %in% 3:10)

# # algo ----
# write.csv(x = df, file = "for-excel-solver.csv")

# Genetic Learning Algorithm ----

# 1. Draw N groups of 8 teams at random. 
# 2. The order of draws corresponds to their selected weeks. 
# 3. Compute each group's score, the product of their lose probabilities. 
# 4. Take the best performer, and mutate 
#   - mutate...
#   - 
# 5. Compare child genertion to parent, if performs less, than keep parent. 

prob = setDT(df)[, .(w=mean(p)), by = c("team")]
teams = prob$team
prob = prob$w

# Compute the average win probability for a set of teams
score = function(chromosome){
  data = data.frame(cbind(chromosome, week = c(3:10)))
  data = merge(data, df, by.x = c("chromosome", "week"), by.y = c("team", "week"))
  if(nrow(data) < length(chromosome)){
    return(1) # team picked on by-week
  }
  return(mean(data$p))
}

ga = function(base){
  base = 0.5
  result = c()
  for(i in 1:100){
    chromosome = sample(teams, 8, replace = FALSE, prob = (1-prob))
    performance = score(chromosome)
    if(performance < base){
      base = performance
      top_chromosome = chromosome
      result = append(result, base)
    }
  }
  # only show result if one is found
  if(result){return(list(base, top_chromosome))}
}

# setup parameters
base = 0.4 # initial avg prob to beat
simple_ga = ga(base)


# Basic approach ----
# what happens if we take the lowest probability team per week
# then recursively drop teams any time one is duplicated, maybe something like 
# the sudoku recursion solver?

# we get Houston in weeks 4, 6, 7, and 8. The rest are unique. 
df %>%
  group_by(week) %>%
  arrange(p) %>%
  slice(1L)

# we want to compare outcomes from using houston in each possible slot
smaller_df = df %>%
  group_by(week) %>%
  arrange(p) %>%
  slice(1:3L)

# what about our GA on a subset of the three best teams per week?
prob = setDT(smaller_df)[, .(w=mean(p)), by = c("team")]
teams = prob$team
prob = prob$w

score = function(chromosome){
  data = data.frame(cbind(chromosome, week = c(3:10)))
  data = merge(data, df, by.x = c("chromosome", "week"), by.y = c("team", "week"))
  if(nrow(data) < length(chromosome)){
    return(1) # team picked on by-week
  }
  return(mean(data$p))
}

base = 0.5
result = c()
picks = list()
track = c()
N = 1000000
for(i in 1:N){
  chromosome = sample(teams, 8, replace = FALSE, prob = (1-prob))
  performance = score(chromosome)
  if(performance < base){
    base = performance
    top_chromosome = chromosome
    picks[[length(picks) + 1]] = chromosome
    result = append(result, base)
  }
  track = append(track, base) # to plot progress
}

plot = data.frame(prob = track)
plot$trial = 1:N

require(scales)
ggplot(plot, aes(x = trial, y = prob)) + 
  geom_point() + 
  scale_color_viridis_d() + 
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1), labels = percent) + 
  scale_x_continuous(trans='log10') +
  labs(title = "GA Model - Mean Weekly Win Probability",
       x = "Trial Number - Logs", 
       y = "Performance") + 
  theme_bw(12)
