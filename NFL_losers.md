---
title: "NFL Losers Pool 2021 Exploration"
author: "Jordan Hutchings"
date: "08/09/2021"
output: 
  html_document:
    keep_md: true
---




Our annual NFL losers pool runs by each enterant having to pick one team per week. 
The objective is to pick one team to lose each week, if your team wins, you are 
out of the pool. The catch is that once a team is picked it cannot be picked 
again. 

My approach is simple, use the NFL forecast data from [FiveThirtyEight](https://projects.fivethirtyeight.com/2021-nfl-predictions/games/) 
and optimize my picks to minimize the total win probability across the season. 


```r
source("pick_functions.R")
pacman::p_load(data.table, ggplot2, ggalt, dplyr, knitr, kableExtra)

# Setup ---- 
path <- "https://projects.fivethirtyeight.com/nfl-api/nfl_elo_latest.csv"
week1 <- as.Date("2021-09-09")
total_weeks <- 10
start_week <- 3
time_period <- c(start_week:total_weeks)
past_picks <- c("DAL")
past_weeks <- c(1)

dt <- read_data(path)
```

Below we can see a heatmap of all the win probabilities throughout the season. 
Teams like Houston, and Washington have a low lieklihood of winning in many 
games in the season. This motivates our problem as we can only pick them each 
once. 


```r
dt %>% 
  tidyr::pivot_longer(cols = c("loser", "winner"), values_to = "team") %>%
  mutate(p = ifelse(name == "loser", p_win, p_win_winner)) %>%
  select(-c("p_win", "p_win_winner")) %>%
  ggplot(aes(week, team, fill=p)) + 
  geom_tile() + 
  scale_fill_viridis_c("Pr(Win)") + 
  theme_classic() + 
  labs(title = "Weekly Win Probabilities Heatmap by team", 
       x = "Week Number", 
       y = "Team") + 
  scale_x_continuous(expand = c(0, 0))
```

![](README_figs/README-unnamed-chunk-3-1.png)<!-- -->

We can also limit our choices to the forecasted underdog, as there are more teams 
than weeks we should never need to pick a favourite. 

```r
ggplot() + 
  geom_point(data = dt, aes(x=week, y=p_win), alpha=0.8, color="gray", size = 3) + 
  coord_flip() + 
  labs(title = "Candidate picks per week", 
       x = "Week Number", 
       y = "Win Probability") + 
  theme_classic(12)
```

![](README_figs/README-unnamed-chunk-4-1.png)<!-- -->

## Different approaches to consider

Below I compare two naive strategies with a more rigorous approach. 
We begin in Week 3, as Weeks 1 and 2 are rebuy weeks. These picks are made 
picking the lowest probability remaining after removing weeks 3 - 10.

Approaches:  
1. Pick the lowest team by week, starting in the first week.  
2. Pick the lowest win probability across all weeks.  
3. Pick the team-week pairing with the greatest opportunity cost. In other words, 
if the team isn't picked, how much of a percentage is given up. 

Each of the above approaches allow for future discounting. I.e. 
$$ Pr(Win | Week = w) = Pr(Win) * \beta^{(w - \underline{w})}$$ where 
$\underline{w}$ is the start week. 


```r
wk <- by_week(past_picks, past_weeks, beta = 1)
pr <- by_prob(past_picks, past_weeks, beta = 1)
oc <- by_oc(past_picks, past_weeks, beta = 1)

tbl <- left_join(wk, pr, by="week", suffix=c("_1", "_2"))
tbl <- left_join(tbl, oc, by="week", suffix=c("", "_3"))
names <- c("Week", rep(c("Team", "ProbWin"),3))
names(tbl) <- names

avg_1 <- mean(as.numeric(wk$p_win))
avg_2 <- mean(as.numeric(pr$p_win))
avg_3 <- mean(as.numeric(oc$p_win))
avg_row <- data.frame("Mean", "", avg_1, "", avg_2, "", avg_3)
names(avg_row) <- names(tbl)

sd_1 <- sd(as.numeric(wk$p_win))
sd_2 <- sd(as.numeric(pr$p_win))
sd_3 <- sd(as.numeric(oc$p_win))
sd_row <- data.frame("SD", "", sd_1, "", sd_2, "", sd_3)
names(sd_row) <- names(tbl)


tbl <- rbind(tbl, avg_row)
tbl <- rbind(tbl, sd_row)

kbl(tbl, digits=3) %>%
  kable_classic(full_width=F) %>%
  add_header_above(c(" " = 1, "Approach 1" = 2, "Approach 2" = 2, "Approach 3" = 2)) %>%
  row_spec(total_weeks-1, bold=T) %>%
  row_spec(total_weeks, bold=T)
```

<table class=" lightable-classic" style='font-family: "Arial Narrow", "Source Sans Pro", sans-serif; width: auto !important; margin-left: auto; margin-right: auto;'>
 <thead>
<tr>
<th style="empty-cells: hide;" colspan="1"></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">Approach 1</div></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">Approach 2</div></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">Approach 3</div></th>
</tr>
  <tr>
   <th style="text-align:left;"> Week </th>
   <th style="text-align:left;"> Team </th>
   <th style="text-align:right;"> ProbWin </th>
   <th style="text-align:left;"> Team </th>
   <th style="text-align:right;"> ProbWin </th>
   <th style="text-align:left;"> Team </th>
   <th style="text-align:right;"> ProbWin </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.176 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.176 </td>
   <td style="text-align:left;"> NYJ </td>
   <td style="text-align:right;"> 0.214 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> HOU </td>
   <td style="text-align:right;"> 0.124 </td>
   <td style="text-align:left;"> HOU </td>
   <td style="text-align:right;"> 0.124 </td>
   <td style="text-align:left;"> HOU </td>
   <td style="text-align:right;"> 0.124 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.243 </td>
   <td style="text-align:left;"> MIA </td>
   <td style="text-align:right;"> 0.256 </td>
   <td style="text-align:left;"> MIA </td>
   <td style="text-align:right;"> 0.256 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 6 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.261 </td>
   <td style="text-align:left;"> PHI </td>
   <td style="text-align:right;"> 0.343 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.210 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 7 </td>
   <td style="text-align:left;"> CHI </td>
   <td style="text-align:right;"> 0.173 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.153 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.153 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 8 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.155 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.155 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 9 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.203 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.203 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.203 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 10 </td>
   <td style="text-align:left;"> NYJ </td>
   <td style="text-align:right;"> 0.292 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.240 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.240 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> Mean </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.203 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.206 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.194 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> SD </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.057 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.071 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.046 </td>
  </tr>
</tbody>
</table>

## Monte Carlo Simulations
One of the best ways to understand the performance of each model is to simulate 
the Losers Pool with the given probabilities, and see how well each model preforms. 
Each season is simulated 100,000 times, and the proportions of times a given week 
is reached by each model is recorded. 


```r
N <- 100000
sim_wk <- call_sim(wk, N, lab = "By Week")
sim_pr <- call_sim(pr, N, lab = "By Probability")
sim_oc <- call_sim(oc, N, lab = "By Oppertunity Cost")


# Compare and plot 
data <- rbind(sim_wk, sim_pr, sim_oc)

ggplot(data, aes(x = week, y = cumprob, color = model)) + 
  geom_line(se = F) + 
  geom_point(alpha = 0.8) + 
  scale_x_continuous(expand = c(0, 0), limits = c(3, 12)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1)) + 
  labs(title = "Cumulative probability of reaching a given week",
       x = "Week number", 
       y = "Pr(X < x)") + 
  theme_classic(10)
```

```
## Warning: Ignoring unknown parameters: se
```

![](README_figs/README-unnamed-chunk-6-1.png)<!-- -->

We have been working off a $\beta = 1$ for each model. Below are the changes 
from using different values of $\beta$. Future discounting will place a higher 
weight on upcoming weeks. This will not change the By Week model but will 
have an impact on the By Probability and By Oppertunity Cost. As we can see above 
the Oppertunity Cost model is First Order Stochastic Dominated by the other two 
models up until Week 7. This is not ideal, as I need to make it to Week 7 to 
see the benefits of the model, which appears to be at a less than 50% chance. 


```r
oc9 <- by_oc(past_picks, past_weeks, beta = 0.9)
oc7 <- by_oc(past_picks, past_weeks, beta = 0.7)
oc5 <- by_oc(past_picks, past_weeks, beta = 0.5)

sim_oc_9 <- call_sim(oc9, N, lab = "By Oppertunity Cost, Beta = 0.9")
sim_oc_7 <- call_sim(oc7, N, lab = "By Oppertunity Cost, Beta = 0.7")
sim_oc_5 <- call_sim(oc5, N, lab = "By Oppertunity Cost, Beta = 0.5")

data <- rbind(sim_wk, sim_pr, sim_oc, sim_oc_9, sim_oc_7, sim_oc_5)

ggplot(data, aes(x = week, y = cumprob, color = model)) + 
  geom_line(se = F) + 
  geom_point(alpha = 0.8) + 
  scale_x_continuous(expand = c(0, 0), limits = c(3, 12)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1)) + 
  labs(title = "Cumulative probability of reaching a given week",
       x = "Week number", 
       y = "Pr(X < x)") + 
  theme_classic(10)
```

```
## Warning: Ignoring unknown parameters: se
```

![](README_figs/README-unnamed-chunk-7-1.png)<!-- -->

Now, including discount values of $\beta\in\{0.5, 0.7, 0.5\}$ in our
Oppertunity cost model gives us better performance in the earlier weeks. 

We can compare the models again in tabular format to identify the best set of picks. 


```r
tbl <- left_join(oc, oc9, by="week", suffix=c("_1", "_2"))
tbl <- left_join(tbl, oc5, by="week", suffix=c("", "_3"))
tbl <- left_join(tbl, wk, by="week", suffix=c("", "_3"))
tbl <- left_join(tbl, pr, by="week", suffix=c("", "_3"))
names <- c("Week", rep(c("Team", "ProbWin"),5))
names(tbl) <- names

avg_1 <- mean(as.numeric(oc$p_win))
avg_2 <- mean(as.numeric(oc9$p_win))
avg_3 <- mean(as.numeric(oc7$p_win))
avg_4 <- mean(as.numeric(wk$p_win))
avg_5 <- mean(as.numeric(pr$p_win))

avg_row <- data.frame("Mean", "", avg_1, "", avg_2, "", avg_3, "", avg_4, "", avg_5)
names(avg_row) <- names(tbl)

sd_1 <- sd(as.numeric(oc$p_win))
sd_2 <- sd(as.numeric(oc9$p_win))
sd_3 <- sd(as.numeric(oc7$p_win))
sd_4 <- sd(as.numeric(wk$p_win))
sd_5 <- sd(as.numeric(pr$p_win))
sd_row <- data.frame("SD", "", sd_1, "", sd_2, "", sd_3, "", sd_4, "", sd_5)
names(sd_row) <- names(tbl)


tbl <- rbind(tbl, avg_row)
tbl <- rbind(tbl, sd_row)

kbl(tbl, digits=3, caption = "Weekly Picks by Model") %>%
  kable_classic(full_width=F) %>%
  add_header_above(c(" " = 1, "OC, Beta = 1" = 2, "OC, Beta = 0.9" = 2, "OC, Beta = 0.7" = 2, 
                     "By Week" = 2, "By Probability" = 2)) %>%
  row_spec(total_weeks-1, bold=T) %>%
  row_spec(total_weeks, bold=T)
```

<table class=" lightable-classic" style='font-family: "Arial Narrow", "Source Sans Pro", sans-serif; width: auto !important; margin-left: auto; margin-right: auto;'>
<caption>Weekly Picks by Model</caption>
 <thead>
<tr>
<th style="empty-cells: hide;" colspan="1"></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">OC, Beta = 1</div></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">OC, Beta = 0.9</div></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">OC, Beta = 0.7</div></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">By Week</div></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">By Probability</div></th>
</tr>
  <tr>
   <th style="text-align:left;"> Week </th>
   <th style="text-align:left;"> Team </th>
   <th style="text-align:right;"> ProbWin </th>
   <th style="text-align:left;"> Team </th>
   <th style="text-align:right;"> ProbWin </th>
   <th style="text-align:left;"> Team </th>
   <th style="text-align:right;"> ProbWin </th>
   <th style="text-align:left;"> Team </th>
   <th style="text-align:right;"> ProbWin </th>
   <th style="text-align:left;"> Team </th>
   <th style="text-align:right;"> ProbWin </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> NYJ </td>
   <td style="text-align:right;"> 0.214 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.176 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.176 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.176 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.176 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> HOU </td>
   <td style="text-align:right;"> 0.124 </td>
   <td style="text-align:left;"> HOU </td>
   <td style="text-align:right;"> 0.124 </td>
   <td style="text-align:left;"> HOU </td>
   <td style="text-align:right;"> 0.124 </td>
   <td style="text-align:left;"> HOU </td>
   <td style="text-align:right;"> 0.124 </td>
   <td style="text-align:left;"> HOU </td>
   <td style="text-align:right;"> 0.124 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5 </td>
   <td style="text-align:left;"> MIA </td>
   <td style="text-align:right;"> 0.256 </td>
   <td style="text-align:left;"> MIA </td>
   <td style="text-align:right;"> 0.256 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.243 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.243 </td>
   <td style="text-align:left;"> MIA </td>
   <td style="text-align:right;"> 0.256 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 6 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.210 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.261 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.261 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.261 </td>
   <td style="text-align:left;"> PHI </td>
   <td style="text-align:right;"> 0.343 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 7 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.153 </td>
   <td style="text-align:left;"> CHI </td>
   <td style="text-align:right;"> 0.173 </td>
   <td style="text-align:left;"> CHI </td>
   <td style="text-align:right;"> 0.173 </td>
   <td style="text-align:left;"> CHI </td>
   <td style="text-align:right;"> 0.173 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.153 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 8 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.155 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.155 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.155 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.155 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.155 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 9 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.203 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.203 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.203 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.203 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.203 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 10 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.240 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.232 </td>
   <td style="text-align:left;"> NYJ </td>
   <td style="text-align:right;"> 0.292 </td>
   <td style="text-align:left;"> NYJ </td>
   <td style="text-align:right;"> 0.292 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.240 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> Mean </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.194 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.198 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.203 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.203 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.206 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> SD </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.046 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.049 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.057 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.057 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.071 </td>
  </tr>
</tbody>
</table>

We see now a $\beta = 0.7$ gets us back to our best pick per week approach, and 
it is the $\beta = 0.9$ that may be the better option. Where we trade off total 
average for a better liklihood of lasting in the event. 

## Dumbbell plot 

Our best two models are the $OC, Beta = 1$ and $OC, Beta = 0.9$. Below are the 
differences in the picks. 


```r
labs <- c("Week", "Team", "ProbWin")
names(oc) <- labs
names(oc9) <- labs
names(wk) <- labs
names(pr) <- labs


oc$Approach <- "OC, Beta = 1"
oc9$Approach <- "OC, Beta = 0.9"
wk$Approach <- "By Week"
pr$Approach <- "By Probability"


data <- rbind(oc, oc9, wk, pr)
data$Approach <- as.factor(data$Approach)


theme_set(theme_bw(12))

ggplot(data, aes(x=Week, y=ProbWin, color = Approach, shape = Approach)) + 
  geom_line(aes(group = Week), color="#e3e2e1", size = 2) +
  geom_point(size = 3) + 
  xlim(3, 11) +
  coord_flip() + 
  scale_color_viridis_d() + 
  labs(title = "Comparing weekly win probabilities per Approach", 
       x = "Week Number", 
       y = "Win Probability") + 
  theme_classic(10)
```

![](README_figs/README-unnamed-chunk-9-1.png)<!-- -->
