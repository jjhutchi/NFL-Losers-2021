---
title: "NFL Losers Pool 2021"
author: "Jordan Hutchings"
date: "12/10/2021"
output: 
  html_document:
    keep_md: true
---



Our annual NFL losers pool runs by each entrant having to pick one team per week. 
The objective is to pick one team to lose each week, if your team wins, you are 
out of the pool. The catch is that once a team is picked it cannot be picked 
again. 

I am taking a fairly simple approach to making my picks this year. 
Download and use the NFL forecast data from 
[FiveThirtyEight](https://projects.fivethirtyeight.com/2021-nfl-predictions/games/) 
to optimize my picks to give the best probability of lasting deep into the season. 


```r
source("pick_functions.R")
pacman::p_load(data.table, ggplot2, ggalt, dplyr, knitr, kableExtra, googlesheets4)

# Setup ---- 
path <- "https://projects.fivethirtyeight.com/nfl-api/nfl_elo_latest.csv"
week1 <- as.Date("2021-09-09")
total_weeks <- 12
start_week <- max(ceiling(as.numeric(( Sys.Date() - as.Date("2021-09-09") )) / 7) + 1, 3) # little janky
time_period <- c(start_week:total_weeks)

# past picks ----
past_weeks <- c(1, 2, 3, 4, 5, 6)
past_picks1 <- c("DAL", "TEN", "NYJ", "HOU", "MIA", "WSH")
past_picks2 <- c("CHI", "TEN", "WSH", "HOU", "DET", "PHI") 

read_data <- function(path, past_picks, all_weeks = FALSE){
  dt <- data.table::fread(path)
  
  # calculate week, get proj loser and prob of loss. 
  
  dt[, loser:=ifelse(qbelo_prob1 > qbelo_prob2, team2, team1)]
  dt[, winner:=ifelse(qbelo_prob1 > qbelo_prob2, team1, team2)]
  dt[, p_win:=ifelse(qbelo_prob1 > qbelo_prob2, qbelo_prob2, qbelo_prob1)]
  dt[, p_win_winner:=ifelse(qbelo_prob1 > qbelo_prob2, qbelo_prob1, qbelo_prob2)]
  dt[, week:=floor(as.numeric(difftime(date, week1, units="days")) / 7) + 1]
  
  dt <- dt[, .(week, loser, winner, p_win, p_win_winner)]
  
  if(!all_weeks){
    dt <- dt[week %in% time_period]
    dt <- dt[!loser %in% past_picks]
  }
  
  return(dt)
}

df1 <- read_data(path, past_picks1)
df2 <- read_data(path, past_picks2)
```

## Visualizations

Below we can see a heatmap of all the win probabilities throughout the season. 
Teams like Houston, and Washington have a low likelihood of winning in many 
games in the season. This motivates our problem as we can only pick them each 
once. The teams are ordered by average likelihood of winning, we can see Houston, 
Detroit, and Jacksonville are the three lowest teams. There is an opportunity to 
out play my competitors by picking these teams in the best possible week, i.e. 
holding off until Week 4 to pick Houston.

![](README_figs/README-unnamed-chunk-3-1.png)<!-- -->

## Historical accuracy of ELO ratings
We can plot the average outcome of each historical game bucketing by the 
probability of each team winning. We can keep only the favourites, as this 
is the same as looking at 1 - the probability of the underdogs. 


```r
hist_data <- "https://projects.fivethirtyeight.com/nfl-api/nfl_elo.csv"
hdt <- fread(hist_data)

# hdt %>%
#   group_by(season) %>%
#   summarise(sum(is.na(qbelo_prob1))) # begins in 1950

hdt %>%
  mutate(loser_score = ifelse(qbelo_prob1 > qbelo_prob2, score2, score1), 
         winner_score = ifelse(qbelo_prob1 > qbelo_prob2, score1, score2), 
         p_win_winner = ifelse(qbelo_prob1 > qbelo_prob2, qbelo_prob1, qbelo_prob2), 
         win = as.numeric(winner_score > loser_score), 
         win_bucket = round(p_win_winner, 2)
         ) %>%
  filter(!is.na(winner_score)) %>%
  # filter(season >= 2000) %>%
  group_by(win_bucket) %>%
  summarise(p = mean(win), n = n(), se = sd(win)) %>%
  ggplot(aes(x = win_bucket, y = p)) + 
  geom_point() + 
  geom_smooth(alpha = 0.7, linetype = "dashed", se=F) + 
  geom_abline(slope = 1) + 
  annotate("text", x = 0.5, y = 0.49, label = "y = x", hjust = 0) + 
  annotate("text", x = 0.5, y = 0.6, label = "Line of \nbest fit", hjust = 0, color = "blue") + 
  labs(title = "The historical oucome observation lines up well with the projected outcomes", 
       x = "Forecasted win rate", 
       y = "Observed win rate") + 
  theme_bw(12)
```

```
## `geom_smooth()` using method = 'loess' and formula 'y ~ x'
```

![](README_figs/README-unnamed-chunk-4-1.png)<!-- -->

## Optimal picks

We make the picks based on the opportunity cost of not picking a team in a given 
week. Meaning, we pick teams based on the cost of not making the best pick in a 
given week. 


```r
make_pick <- function(dt, past_picks, past_weeks, start_week = 3, total_weeks = 13, beta = 1){
  
  for(i in start_week:total_weeks){
    
    pick <- dt[week %in% c(start_week:total_weeks)]
    pick <- pick[!loser %in% past_picks & !week %in% past_weeks]
    pick[, value:= p_win * beta^(week - start_week)]
    pick <- pick[order(value)]
    pick <- pick[, .SD[1]]
    
    past_weeks <- append(past_weeks, pick$week)
    past_picks <- append(past_picks, pick$loser)
    
  }
  
  picks <- setDT(data.frame(week = past_weeks, loser = past_picks))
  picks <- merge(picks, dt, on = week)
  picks <- picks[, .(week, loser, p_win)]
  
  picks
}

path_1 <- make_pick(df1, past_picks1, past_weeks, beta = 0.8)
path_2 <- make_pick(df2, past_picks2, past_weeks, beta = 0.8)

tbl <- merge(path_1, path_2, by = "week")
names(tbl) <- c("Week", rep(c("Team", "ProbWin"), 2))

kbl(tbl, digits=3, caption = "Optimal Picks per Week") %>%
  kable_classic(full_width=F) %>%
  add_header_above(c(" " = 1, "First Set of Picks" = 2, "Second Set of Picks" = 2))
```

<table class=" lightable-classic" style='font-family: "Arial Narrow", "Source Sans Pro", sans-serif; width: auto !important; margin-left: auto; margin-right: auto;'>
<caption>Optimal Picks per Week</caption>
 <thead>
<tr>
<th style="empty-cells: hide;" colspan="1"></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">First Set of Picks</div></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">Second Set of Picks</div></th>
</tr>
  <tr>
   <th style="text-align:right;"> Week </th>
   <th style="text-align:left;"> Team </th>
   <th style="text-align:right;"> ProbWin </th>
   <th style="text-align:left;"> Team </th>
   <th style="text-align:right;"> ProbWin </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> CHI </td>
   <td style="text-align:right;"> 0.165 </td>
   <td style="text-align:left;"> CIN </td>
   <td style="text-align:right;"> 0.211 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.202 </td>
   <td style="text-align:left;"> MIA </td>
   <td style="text-align:right;"> 0.124 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.134 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.134 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.229 </td>
   <td style="text-align:left;"> NYJ </td>
   <td style="text-align:right;"> 0.153 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.137 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.158 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:left;"> OAK </td>
   <td style="text-align:right;"> 0.257 </td>
   <td style="text-align:left;"> OAK </td>
   <td style="text-align:right;"> 0.257 </td>
  </tr>
</tbody>
</table>

## Alternative picks
Given the cluster of teams to choose in week 6, what do other possible picks that 
are not PHI look like?


```r
past_picks <- past_picks1
past_weeks <- c(1:6)
dt <- df1
beta <- 0.1
for(i in start_week:total_weeks){
  
  pick <- dt[week %in% c(start_week:total_weeks)]
  pick <- pick[!(week == 6 & loser == "PHI"), ] # drop PHI pick in week 1
  pick <- pick[!loser %in% past_picks & !week %in% past_weeks]
  pick[, value:= p_win * beta^(week - start_week)]
  pick <- pick[order(value)]
  pick <- pick[, .SD[1]]
  
  past_weeks <- append(past_weeks, pick$week)
  past_picks <- append(past_picks, pick$loser)
  
}

picks <- setDT(data.frame(week = past_weeks, loser = past_picks))
picks <- merge(picks, dt, on = week)
alt_picks_1 <- picks[, .(week, loser, p_win)]

past_picks <- past_picks2
past_weeks <- c(1:6)
dt <- df2
beta <- 1
for(i in start_week:total_weeks){
  
  pick <- dt[week %in% c(start_week:total_weeks)]
  pick <- pick[!(week == 6 & loser == "PHI"), ] # drop PHI pick in week 1
  pick <- pick[!loser %in% past_picks & !week %in% past_weeks]
  pick[, value:= p_win * beta^(week - start_week)]
  pick <- pick[order(value)]
  pick <- pick[, .SD[1]]
  
  past_weeks <- append(past_weeks, pick$week)
  past_picks <- append(past_picks, pick$loser)
  
}

picks <- setDT(data.frame(week = past_weeks, loser = past_picks))
picks <- merge(picks, dt, on = week)
alt_picks_2 <- picks[, .(week, loser, p_win)]

alt_picks_1 # Go with WSH
```

```
##    week loser     p_win
## 1:    7   CHI 0.1648587
## 2:    8   NYG 0.2016777
## 3:    9   MIN 0.2144844
## 4:   10   JAX 0.1858644
## 5:   11   DET 0.1372072
## 6:   12   OAK 0.2573265
```

```r
alt_picks_2 # keep PHI
```

```
##    week loser     p_win
## 1:    7   CIN 0.2107118
## 2:    8   MIA 0.1243680
## 3:    9   JAX 0.1342876
## 4:   10   NYJ 0.1526965
## 5:   11   NYG 0.1580791
## 6:   12   OAK 0.2573265
```

## Survival Rate

Given the Boolean nature of our predictions, we can compute the likelihood 
of reaching a given week based on our pick paths. 

```r
cumprob <- function(picks, inc_weeks = FALSE){
  p <- purrr::accumulate((1-picks$p_win), function(x, y)  x * y)
  weeks <- picks$Week
  if(inc_weeks){ out <- data.frame(p, weeks) } 
  else { out <- data.frame(p) }
  
  out
}

models <- list(path_1, path_2, alt_picks_1)
results <- lapply(models, function(x) cumprob(x))
results <- do.call(cbind.data.frame, results)
results$week <- seq(start_week, total_weeks, 1)
names(results) <- c("Path_1", "Path_2", "Alt_1", "Week")

results %>%
  tidyr::pivot_longer(cols = -Week, names_to = "Model", values_to = "p") %>%
  ggplot(aes(x = Week, y = p, color = Model)) +
  geom_line() + 
  geom_point(alpha = 0.8) + 
  scale_x_continuous(expand = c(0, 0), limits = c(start_week, total_weeks)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1)) + 
  scale_color_viridis_d() + 
  labs(title = "Probability of reaching a given week",
       x = "Week number", 
       y = "Pr(W < w)") + 
  theme_bw(12)
```

![](README_figs/README-unnamed-chunk-7-1.png)<!-- -->

## Comparing the weekly trade-offs between picks


```r
p1 <- path_1
p2 <- path_2
a1 <- alt_picks_1
p1$Approach <- "Path 1"
p2$Approach <- "Path 2"
a1$Approach <- "Week 1 Alt."
data <- rbind(p1, p2, a1)

ggplot(data, aes(x=week, y=p_win, color = Approach, label = loser)) + 
  geom_line(aes(group = week), color="#e3e2e1", size = 2) +
  geom_point(data = plot_data, aes(x=week, y=p_win, color = "All Choices"), size = 3, alpha = 0.4) +
  geom_point(size = 3, alpha = 0.8) + 
  geom_text(color = "black", nudge_x = 0.2) + 
  xlim(start_week, 12.5) +
  coord_flip() + 
  scale_color_viridis_d() + 
  labs(title = "Comparing weekly win probabilities per Path", 
       x = "Week Number", 
       y = "Win Probability", 
       color = "Choice Set") + 
  theme_bw(12)
```

```
## Warning: Removed 186 rows containing missing values (geom_point).
```

![](README_figs/README-unnamed-chunk-8-1.png)<!-- -->

## Showing the choice set


```r
pre1 <- cbind(c(1:(start_week - 1)), past_picks1, "Path 1")
pre2 <- cbind(c(1:(start_week - 1)), past_picks2, "Path 2")

pre <- data.frame(rbind(pre1, pre2))
names(pre) <- c("week", "loser", "Approach")
pre$week <- as.numeric(pre$week)
pre <- left_join(pre, plot_data, by = c("week", "loser"))
pre <- select(pre, c("week", "loser", "p_win", "Approach"))
data <- rbind(pre, data)
data$forecast <- data$week > start_week

ggplot(subset(plot_data, week < 13), aes(x = week, y = p_win)) + 
  geom_vline(xintercept = start_week, linetype = "dashed", alpha = 0.8) +
  geom_point(size = 2, color = "grey", alpha = 0.6) + 
  geom_line(data = data, mapping = aes(x = week, y = p_win, color = Approach)) + 
  coord_flip() + 
  xlim(1, 12) + 
  annotate("text", x = start_week + 0.05, y = 0, label="forecast \nhistorical", hjust = 0, color = "darkgrey") + 
  labs(title = "Choice set path", 
       y = "Win Probability", 
       x = "Week Number", 
       color = "Choice Set") + 
  scale_color_viridis_d() + 
  theme_bw(12)
```

![](README_figs/README-unnamed-chunk-9-1.png)<!-- -->


## Team Ownership
We can track the picks made by other competitors and use this information to 
pick teams with low ownership in upcoming weeks. 

We could assume each player picks the best team in terms of probability each 
week based on their remaining picks, and optimize based on this information. 

This could be done by splitting `ownership` based on the player, then computing 
their optimal path. This can be done either by assuming they play my strategy, 
or that they are picking the lowest probability team each week. 

Lets begin with them also playing my strategy each week.

<!-- This code seems to be off somehow, my picks are very close to the worst. -->

<!-- ```{r} -->
<!-- ownership <- "https://docs.google.com/spreadsheets/d/1sajv1HXDqzjG2bXwx927MTP_TUKRWsjVSvKAwnaWZcs/edit?usp=sharing" -->
<!-- own <- googlesheets4::read_sheet(ownership) -->
<!-- own <- tidyr::pivot_longer(own, cols = contains("Week"), names_to = "Week", values_to = "Pick")  -->

<!-- sim_picks <- function(player){ -->
<!--   data <- read_data(path, past_picks = player$Pick) -->
<!--   picks <- make_pick(data, player$Pick, past_weeks, beta = 1) -->
<!--   lab <- unique(player$Player)[1] -->
<!--   picks$Player <- lab -->
<!--   print(paste("Sim picks for:", lab)) -->
<!--   picks -->
<!-- } -->
<!-- split_own <- split(own, own$Player) -->
<!-- split_own <- purrr::map_dfr(split_own, sim_picks) -->

<!-- split_cumprob <- split(split_own, split_own$Player) -->
<!-- split_cumprob <- lapply(split_cumprob, cumprob) -->
<!-- split_cumprob <- do.call(cbind.data.frame, split_cumprob) -->
<!-- split_cumprob$week <- c(start_week:total_weeks) -->
<!-- names(split_cumprob) <- c(unique(own$Player), "Week") -->

<!-- split_cumprob %>% -->
<!--   tidyr::pivot_longer(cols = -"Week", names_to = "Player", values_to = "p") %>% -->
<!--   mutate(Player = reorder(Player, p)) %>% -->
<!--   ggplot(aes(x = Week, y = p, color = Player)) + -->
<!--   geom_line() +  -->
<!--   geom_point(alpha = 0.8) +  -->
<!--   scale_x_continuous(expand = c(0, 0), limits = c(start_week, total_weeks)) + -->
<!--   scale_y_continuous(expand = c(0, 0), limits = c(0.1, 0.75)) +  -->
<!--   labs(title = "Probability of reaching a given week assuming all teams play with OC strategy", -->
<!--        x = "Week number",  -->
<!--        y = "Pr(W < w)") +  -->
<!--   scale_color_viridis_d() +  -->
<!--   theme_bw(12) -->

<!-- split_own %>% -->
<!--   group_by(Player) %>% -->
<!--   summarise(avg = mean(p_win)) %>% -->
<!--   arrange(desc(avg)) -->
<!-- ``` -->

<!-- ## add ownership percent to table of picks -->

<!-- We can look to see which of our picks are open to other competitors. As we  -->
<!-- can see below, there is a high likelihood all those who haven't already  -->
<!-- picked Detroit in Week 7 will take Cincinnati as they have yet to be picked by  -->
<!-- anyone.  -->

<!-- ```{r} -->
<!-- teams <- unique(plot_data$loser) -->
<!-- players_left <- length(unique(own$Player)) - 2 # not include myself -->
<!-- team_list <- c() -->
<!-- percent_list <- c() -->
<!-- for(t in teams){ -->
<!--   tmp <- subset(own, Pick == t & Player != "Hutch 1" & Player != "Hutch 2") -->
<!--   count <- nrow(tmp) -->
<!--   percent <- (17 - count) / 17 -->
<!--   percent_list <- append(percent_list, percent) -->
<!--   team_list <- append(team_list, t) -->
<!-- } -->

<!-- available <- data.table(loser = team_list, avail_pct = percent_list) -->

<!-- path_1 <- left_join(path_1, available, by = "loser") -->
<!-- path_2 <- left_join(path_2, available, by = "loser") -->

<!-- tbl <- merge(path_1, path_2, by = "week") -->
<!-- names(tbl) <- c("Week", rep(c("Team", "ProbWin", "Availability"), 2)) -->

<!-- kbl(tbl, digits=3, caption = "Optimal Picks per Week, with Team Availability") %>% -->
<!--   kable_classic(full_width=F) %>% -->
<!--   add_header_above(c(" " = 1, "First Set of Picks" = 3, "Second Set of Picks" = 3)) -->
<!-- ``` -->


# Next steps
1. What can I do knowing the ownership percentages?  
2. Tidy the code up, pretty sloppy. See what I'd like to keep. 
