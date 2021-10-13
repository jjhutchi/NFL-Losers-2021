---
title: "NFL Losers Pool 2021 Exploration"
author: "Jordan Hutchings"
date: "08/09/2021"
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

## TODOs: 
1. Clean code to provide some viz, then do analysis
2. Separate entry 1 and entry 2 picks
3. Consider the number of weeks with the number of remaining players - 
   how many weeks out should I include?



## Visualizations 
Below we can see a heatmap of all the win probabilities throughout the season. 
Teams like Houston, and Washington have a low likelihood of winning in many 
games in the season. This motivates our problem as we can only pick them each 
once. The teams are ordered by average likelihood of winning, we can see Houston, 
Detroit, and Jacksonville are the three lowest teams. There is an opportunity to 
out play my competitors by picking these teams in the best possible week, i.e. 
holding off until Week 4 to pick Houston.

![](README_figs/README-unnamed-chunk-3-1.png)<!-- -->

Below is a plot of the choice set of underdogs in each game. We can see there 
is a finite set of picks per week, with each week having differing probabilities. 
Ideally, we are looking for the path through these points that minimizes our 
chances of losing from the competition.

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

The table below shows the optimal picks following each approach, past weeks are 
filled with the set picks I made. We can see there is a slight improvement when 
moving from the naiive approaches to Approach 3.

<table class=" lightable-classic" style='font-family: "Arial Narrow", "Source Sans Pro", sans-serif; width: auto !important; margin-left: auto; margin-right: auto;'>
<caption>Comparison of approaches</caption>
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
   <td style="text-align:left;"> 6 </td>
   <td style="text-align:left;"> PHI </td>
   <td style="text-align:right;"> 0.290 </td>
   <td style="text-align:left;"> PHI </td>
   <td style="text-align:right;"> 0.290 </td>
   <td style="text-align:left;"> PHI </td>
   <td style="text-align:right;"> 0.290 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 7 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.107 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.107 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.107 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 8 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.202 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.202 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.202 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 9 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.134 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.134 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.134 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 10 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.229 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.229 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.229 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> Mean </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.193 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.193 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.193 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> SD </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.074 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.074 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.074 </td>
  </tr>
</tbody>
</table>
## Discounting future games

We have been working off a $\beta = 1$ for each model. Below are the changes 
from using different values of $\beta$. Future discounting will place a higher 
weight on upcoming weeks. This will not change the By Week model but will 
have an impact on the By Probability and By Oppertunity Cost. The overall average 
probability of winning a game will increase as we are discounting future games. 
What matters now though is how much more probability we are shifting away from 
future weeks and to upcoming weeks. Therefore, we should no longer evaluate 
from the average risk per week, and instead the likelihood of reaching a given week. 

## Calculating probability of making a given week

Since the game outcomes are binary 
we can also calculate the proportion of times we reach a given week 
as the following, recall $Pr(w_i)$ is the probability of the pick winning 
in week $i$, or losing in week $i$.

$$ Pr(W \leq w) = \Pi_{i = 1}^w (1 - Pr(w_i))  $$

![](README_figs/README-unnamed-chunk-6-1.png)<!-- --><table class=" lightable-classic" style='font-family: "Arial Narrow", "Source Sans Pro", sans-serif; width: auto !important; margin-left: auto; margin-right: auto;border-bottom: 0;'>
<caption>Likelihood of reaching a given week by model</caption>
 <thead>
  <tr>
   <th style="text-align:right;"> Week </th>
   <th style="text-align:right;"> Opp Cost, Beta = 1 </th>
   <th style="text-align:right;"> Opp Cost, Beta = 0.9 </th>
   <th style="text-align:right;"> Opp Cost, Beta = 0.7 </th>
   <th style="text-align:right;"> By Prob, Beta = 1 </th>
   <th style="text-align:right;"> By Prob, Beta = 0.9 </th>
   <th style="text-align:right;"> By Prob, Beta = 0,7 </th>
   <th style="text-align:right;"> By Week </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 0.71 </td>
   <td style="text-align:right;"> 0.71 </td>
   <td style="text-align:right;"> 0.71 </td>
   <td style="text-align:right;"> 0.71 </td>
   <td style="text-align:right;"> 0.71 </td>
   <td style="text-align:right;"> 0.71 </td>
   <td style="text-align:right;"> 0.71 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 0.63 </td>
   <td style="text-align:right;"> 0.63 </td>
   <td style="text-align:right;"> 0.63 </td>
   <td style="text-align:right;"> 0.63 </td>
   <td style="text-align:right;"> 0.63 </td>
   <td style="text-align:right;"> 0.63 </td>
   <td style="text-align:right;"> 0.63 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 0.51 </td>
   <td style="text-align:right;"> 0.51 </td>
   <td style="text-align:right;"> 0.51 </td>
   <td style="text-align:right;"> 0.51 </td>
   <td style="text-align:right;"> 0.51 </td>
   <td style="text-align:right;"> 0.51 </td>
   <td style="text-align:right;"> 0.51 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 0.44 </td>
   <td style="text-align:right;"> 0.44 </td>
   <td style="text-align:right;"> 0.44 </td>
   <td style="text-align:right;"> 0.44 </td>
   <td style="text-align:right;"> 0.44 </td>
   <td style="text-align:right;"> 0.40 </td>
   <td style="text-align:right;"> 0.44 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 0.34 </td>
   <td style="text-align:right;"> 0.34 </td>
   <td style="text-align:right;"> 0.34 </td>
   <td style="text-align:right;"> 0.34 </td>
   <td style="text-align:right;"> 0.34 </td>
   <td style="text-align:right;"> 0.32 </td>
   <td style="text-align:right;"> 0.34 </td>
  </tr>
</tbody>
<tfoot>
<tr><td style="padding: 0; " colspan="100%"><span style="font-style: italic;">Note: </span></td></tr>
<tr><td style="padding: 0; " colspan="100%">
<sup></sup> Percentages represent the likelihood of reaching a given <br>           week based on the picks from each model.</td></tr>
</tfoot>
</table>

As expected, we have better chances earlier when using a discount value less than 
one for the Opportunity Cost model. Notice there is not much variation across 
differing beta values. 


```
## Warning in merge.data.table(..., by = c("week"), all.x = TRUE): column names
## 'loser.x', 'p_win.x', 'loser.y', 'p_win.y' are duplicated in the result
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
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 6 </td>
   <td style="text-align:left;"> PHI </td>
   <td style="text-align:right;"> 0.290 </td>
   <td style="text-align:left;"> PHI </td>
   <td style="text-align:right;"> 0.290 </td>
   <td style="text-align:left;"> PHI </td>
   <td style="text-align:right;"> 0.290 </td>
   <td style="text-align:left;"> PHI </td>
   <td style="text-align:right;"> 0.290 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 7 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.107 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.107 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.107 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.107 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 8 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.202 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.202 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.202 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.202 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 9 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.134 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.134 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.134 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.134 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 10 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.229 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.229 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.229 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.229 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> Mean </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.193 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.193 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.193 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.193 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> SD </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.074 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.074 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.074 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.074 </td>
  </tr>
</tbody>
</table>

We see now a $\beta = 0.7$ gets us back to our best pick per week approach, and 
it is the $\beta = 0.9$ that may be the better option. Where we trade off total 
average for a better liklihood of lasting in the event. 

## Dumbbell plot 

Our best two models are the $OC, Beta = 1$ and $OC, Beta = 0.9$. Below are the 
differences in the picks. 

![](README_figs/README-unnamed-chunk-8-1.png)<!-- -->

## Alterative weeks for optimal team picks
We can view other weeks of the recommended team below in a selection plot. 
Here the only alternative to picking HOU comes in the By Prob, Beta = 0.7 model 
which selects PIT. However, it is clear there is no future gain from this pick.

![](README_figs/README-unnamed-chunk-9-1.png)<!-- -->

## What is the next best possible pick?
If we remove the optimal pick from our choice set, what is the next best pick?
This is done so I can consider picking two different teams per week to hedge my 
bets. 

![](README_figs/README-unnamed-chunk-10-1.png)<!-- -->![](README_figs/README-unnamed-chunk-10-2.png)<!-- --><table class=" lightable-classic" style='font-family: "Arial Narrow", "Source Sans Pro", sans-serif; width: auto !important; margin-left: auto; margin-right: auto;'>
<caption>Recommended sets of picks</caption>
 <thead>
<tr>
<th style="empty-cells: hide;" colspan="1"></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">Optimal Pick</div></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">Next Best</div></th>
</tr>
  <tr>
   <th style="text-align:left;"> Week </th>
   <th style="text-align:left;"> Pick </th>
   <th style="text-align:right;"> ProbWin </th>
   <th style="text-align:left;"> Pick </th>
   <th style="text-align:right;"> ProbWin </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 6 </td>
   <td style="text-align:left;"> PHI </td>
   <td style="text-align:right;"> 0.290 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.292 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 7 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.107 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.107 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 8 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.202 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.202 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 9 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.134 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.134 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 10 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.229 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.229 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> Mean </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.193 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.193 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> SD </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.074 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.074 </td>
  </tr>
</tbody>
</table>


### Showing pick profiles on choice set
![](README_figs/README-unnamed-chunk-11-1.png)<!-- -->
The above analysis is not very supportive of not taking MIA in both picks next week. 
This analysis is flawed, as we rule out the first pick in each week. 

## Todos
* Make the choice plot with paths of optimal picks include picks from first N weeks.
* Make two sets of past picks for each stream of picks


## Looking back at ELO's performance
This section is a look back at the first 5 weeks of NFL projections. I am curious how 
well the forecasts are performing, and plan to plot the estimated win rate against the 
actual bserved win rate. In order to do this, I will be bucketing the probabilities into 
N discrete groups, then comuting the win percentage per group. Ideally plotting the 
forecast win rate against actual win rates should provide a 45 degree line. 


```r
# get data for all weeks
dt <- data.table::fread(path)
dt[, loser:=ifelse(qbelo_prob1 > qbelo_prob2, team2, team1)]
dt[, winner:=ifelse(qbelo_prob1 > qbelo_prob2, team1, team2)]
dt[, loser_score:=ifelse(qbelo_prob1 > qbelo_prob2, score2, score1)]
dt[, winner_score:=ifelse(qbelo_prob1 > qbelo_prob2, score1, score2)]
dt[, p_win:=ifelse(qbelo_prob1 > qbelo_prob2, qbelo_prob2, qbelo_prob1)]
dt[, p_win_winner:=ifelse(qbelo_prob1 > qbelo_prob2, qbelo_prob1, qbelo_prob2)]
dt[, week:=floor(as.numeric(difftime(date, week1, units="days")) / 7) + 1]
dt <- dt[!is.na(winner_score), ]
dt[, win:= as.numeric(winner_score > loser_score)]
dt[, win_bucket:= round(p_win_winner, 1)]
dt <- dt[, .(win, win_bucket)]

dt %>%
  group_by(win_bucket) %>%
  summarize(p = mean(win), 
            n = n()) %>%
  ggplot(aes(x = win_bucket, y = p)) + 
  geom_point() + 
  geom_abline(slope = 1, linetype = "dotted") + 
  xlim(0, 1) + 
  ylim(0, 1) + 
  labs(title = "Weeks 1 - 5, actual versus observed outcomes", 
       x = "Forecasted win rate", 
       y = "Observed win rate") + 
  theme_bw()
```

![](README_figs/README-unnamed-chunk-12-1.png)<!-- -->

### repeat on historical data


```r
hist_data <- "https://projects.fivethirtyeight.com/nfl-api/nfl_elo.csv"
hdt <- fread(hist_data)

hdt %>%
  group_by(season) %>%
  summarise(sum(is.na(qbelo_prob1))) # begins in 1950
```

```
## # A tibble: 102 × 2
##    season `sum(is.na(qbelo_prob1))`
##     <int>                     <int>
##  1   1920                        90
##  2   1921                        66
##  3   1922                        74
##  4   1923                        88
##  5   1924                        80
##  6   1925                       104
##  7   1926                       116
##  8   1927                        72
##  9   1928                        56
## 10   1929                        70
## # … with 92 more rows
```

```r
# clean data 
hdt[, loser:=ifelse(qbelo_prob1 > qbelo_prob2, team2, team1)]
hdt[, winner:=ifelse(qbelo_prob1 > qbelo_prob2, team1, team2)]
hdt[, loser_score:=ifelse(qbelo_prob1 > qbelo_prob2, score2, score1)]
hdt[, winner_score:=ifelse(qbelo_prob1 > qbelo_prob2, score1, score2)]
hdt[, p_win:=ifelse(qbelo_prob1 > qbelo_prob2, qbelo_prob2, qbelo_prob1)]
hdt[, p_win_winner:=ifelse(qbelo_prob1 > qbelo_prob2, qbelo_prob1, qbelo_prob2)]
hdt <- hdt[!is.na(winner_score), ]
hdt[, win:= as.numeric(winner_score > loser_score)]
hdt[, win_bucket:= round(p_win_winner, 1)]

hdt <- hdt[, .(win, win_bucket, season)]

hdt %>%
  # filter(season >= 2000) %>%
  group_by(win_bucket) %>%
  summarise(p = mean(win), n = n(), se = sd(win)) %>%
  ggplot(aes(x = win_bucket, y = p)) + 
  geom_errorbar(aes(x = win_bucket, ymin = p - 1.65*se, ymax = p + 1.65*se)) + 
  geom_point() + 
  geom_abline(slope = 1) + 
  labs(title = "Historical game - favourite win rates", 
       x = "Forecasted win rate", 
       y = "Observed win rate") + 
  theme_bw()
```

![](README_figs/README-unnamed-chunk-13-1.png)<!-- -->
