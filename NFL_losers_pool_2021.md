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

## Data pre-processing

```r
pacman::p_load(data.table, ggplot2, ggalt, dplyr, knitr, kableExtra)

path <- "https://projects.fivethirtyeight.com/nfl-api/nfl_elo_latest.csv"
week1 <- as.Date("2021-09-09")

dt <- fread(path)

# calculate week, get proj loser and prob of loss. 
total_weeks <- 13
time_period <- seq(3, total_weeks, 1)

dt[, loser:=ifelse(qbelo_prob1 > qbelo_prob2, team2, team1)]
dt[, p_win:=ifelse(qbelo_prob1 > qbelo_prob2, qbelo_prob2, qbelo_prob1)]
dt[, week:=floor(as.numeric(difftime(date, week1, units="days")) / 7) + 1]

cols <- c("week", "loser", "p_win")
dt <- dt[, .(week, loser, p_win)]

dt <- dt[week %in% time_period]

# remove past picks
past_picks <- c("DAL")
dt <- dt[!loser %in% past_picks]
```

## Visualize the possible picks per week
To get a sense of the data we are working with, below is a heatmap of the win 
probabilities for each underdog across the entire season. 


```r
ggplot(dt, aes(week, loser, fill=p_win)) + 
  geom_tile() + 
  scale_fill_viridis_c("Pr(Win)") + 
  theme_bw() + 
  labs(title = "Pr(Win | underdog), week X team") + 
  xlim(3, 13)
```

![](README_figs/README-unnamed-chunk-3-1.png)<!-- -->

```r
ggplot() + 
  geom_point(data = dt, aes(x=week, y=p_win), alpha=0.8, color="gray") + 
  coord_flip() + 
  labs(title = "Candidate picks per week", 
       x = "Week Number", 
       y = "Win Probability")
```

![](README_figs/README-unnamed-chunk-3-2.png)<!-- -->

## Identifying the optimal time to pick each team
We want to identify the optimal pick per week given the set of probabilities 
each team has of losing their weekly game subject to the constraint of only 
being able to pick each team once. 

Possible approaches: 

1.  Pick the lowest probability of winning each week
2.  Pick the lowest probability of winning each team
3.  Pick the team-week combination based on the oppertunity 
cost of not making the best pick that week
4.  Small changes in picks from Approach 3.

# Comparing approaches
Note: 

- we want to compare each approach based on previous picks already made.
- last year, the contest ran for 13 weeks. Therefore, we will optimize picks 
only for the first 13 weeks. 
  - Optionally, the process should be repeated using only 8 or 10 weeks. 
  This is meant to put greater weight on outlasting other competitors. 
- There are rebuys in weeks 1 and 2, so we will not include these weeks in the 
model.
- I will try and generalize the approaches as individual functions, this will 
allow for ease testing different cases. 

## Approach 1: 
Simply pick the team with the lowest probability starting week 3.


```r
by_week <- function(past_picks, past_weeks){
  
  total_weeks <- 13
  start_week <- 3

  # loop through filling in each week
  for(i in start_week:total_weeks){
    pick <- dt[!loser %in% past_picks & week == i]
    pick <- pick[order(week, p_win)]
    pick <- pick[, .SD[1]]
    
    past_weeks <- append(past_weeks, pick$week)
    past_picks <- append(past_picks, pick$loser)
  
  }
  
  # make into readable table
  picks <- setDT(data.frame(week = past_weeks, loser = past_picks))
  picks <- merge(picks, dt, on = week)
  
  return(picks)
    
}

past_picks <- c("DAL")
past_weeks <- c(1)

picks1 <- by_week(past_picks, past_weeks)


kable(picks1, digits = 2) %>%
  kable_classic(full_width = F)
```

<table class=" lightable-classic" style='font-family: "Arial Narrow", "Source Sans Pro", sans-serif; width: auto !important; margin-left: auto; margin-right: auto;'>
 <thead>
  <tr>
   <th style="text-align:right;"> week </th>
   <th style="text-align:left;"> loser </th>
   <th style="text-align:right;"> p_win </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.18 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> HOU </td>
   <td style="text-align:right;"> 0.12 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.24 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.26 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> CHI </td>
   <td style="text-align:right;"> 0.17 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.15 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.20 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:left;"> NYJ </td>
   <td style="text-align:right;"> 0.29 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:left;"> IND </td>
   <td style="text-align:right;"> 0.29 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:left;"> MIN </td>
   <td style="text-align:right;"> 0.33 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:left;"> DEN </td>
   <td style="text-align:right;"> 0.24 </td>
  </tr>
</tbody>
</table>

## Approach 2: 
Pick the lowest probability for each team, rather than starting in week 3 as 
we did in Approach 1, we pick by the lowest overall win probability.

We can iterate through picking the lowest absolute probability, then add that 
team and week and remove from the list of contenders. 


```r
by_prob <- function(past_picks, past_weeks){
  
  total_weeks <- 13
  start_week <- 3
  
  for(i in start_week:total_weeks){
    
    pick <- dt[week %in% c(start_week:total_weeks)]
    pick <- pick[!loser %in% past_picks & !week %in% past_weeks]
    pick <- pick[order(p_win)]
    pick <- pick[, .SD[1]]
    
    past_weeks <- append(past_weeks, pick$week)
    past_picks <- append(past_picks, pick$loser)
    
  }
  
  # make into readable table
  picks <- setDT(data.frame(week = past_weeks, loser = past_picks))
  picks <- merge(picks, dt, on = week)
  
  return(picks)

}

past_picks <- c("DAL")
past_weeks <- c(1)

picks2 <- by_prob(past_picks, past_weeks)

kable(picks2, digits = 2) %>%
  kable_classic(full_width = F)
```

<table class=" lightable-classic" style='font-family: "Arial Narrow", "Source Sans Pro", sans-serif; width: auto !important; margin-left: auto; margin-right: auto;'>
 <thead>
  <tr>
   <th style="text-align:right;"> week </th>
   <th style="text-align:left;"> loser </th>
   <th style="text-align:right;"> p_win </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.18 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> HOU </td>
   <td style="text-align:right;"> 0.12 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> MIA </td>
   <td style="text-align:right;"> 0.26 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> PHI </td>
   <td style="text-align:right;"> 0.34 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.15 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.15 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.20 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:left;"> NYJ </td>
   <td style="text-align:right;"> 0.29 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:left;"> IND </td>
   <td style="text-align:right;"> 0.29 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:left;"> MIN </td>
   <td style="text-align:right;"> 0.33 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.14 </td>
  </tr>
</tbody>
</table>

## Approach 3: 

By picking teams based on the opportunity cost, we are able to pick the best 
team-week pairing in terms of the cost of not picking that pair. For example, 
picking the lowest team in week 1 may mean having to take a larger delta for 
the same team in week 4. 

To do this, we calculate the difference in probabilities from the best weekly 
pick, and the next best. We then rank these differences and pick the overall 
greatest difference. We then remove the week and team from the pool, and repeat.

It is worth considering if this is optimal, there maybe a situation where 
the opportunity cost in one week is worth the gains across multiple weeks. 

This is done below in Approach 4. 


```r
by_oc <- function(past_picks, past_weeks){

  start_week <- 3
  total_weeks <- 13
  
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
  
  # make into readable table
  picks <- setDT(data.frame(week = past_weeks, loser = past_picks))
  picks <- merge(picks, dt, on = week)
  
  return(picks)
  
}

past_weeks <- c(1)
past_picks <- c("DAL")

picks3 <- by_oc(past_picks, past_weeks)

kable(picks3, digits = 2) %>%
  kable_classic(full_width = F)
```

<table class=" lightable-classic" style='font-family: "Arial Narrow", "Source Sans Pro", sans-serif; width: auto !important; margin-left: auto; margin-right: auto;'>
 <thead>
  <tr>
   <th style="text-align:right;"> week </th>
   <th style="text-align:left;"> loser </th>
   <th style="text-align:right;"> p_win </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> NYJ </td>
   <td style="text-align:right;"> 0.21 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> HOU </td>
   <td style="text-align:right;"> 0.12 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> MIA </td>
   <td style="text-align:right;"> 0.26 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.21 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> CHI </td>
   <td style="text-align:right;"> 0.17 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.15 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.20 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:left;"> CAR </td>
   <td style="text-align:right;"> 0.31 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.19 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:left;"> MIN </td>
   <td style="text-align:right;"> 0.33 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.14 </td>
  </tr>
</tbody>
</table>

## Approach 4: 
Can we improve on Approach 3 by randomly removing Approach 3 picks, then picking 
by the opportunity cost? The idea here is that our initial opportunity cost 
approach doesn't look deep enough to identify the optimal solution, but 
through randomly removing picks, we can identify a better week to make a pick. 

We will measure the output of the model by the total sum of the weekly win 
probabilities, with better selections having a lower sum. 

we will maintain only some of the initial picks, filling in the remaining 
spots with the optimal remaining picks. 

There is a finite number of cases where we keep some of the initial picks. 
Lets assume we run the model on weeks 3 to 13, then there are 11 possible week 
team pairs that can be dropped. In this case, there are a total of 2046 possible 
cases we can check: 

$$ \sum_{i=1}^{10}\binom{11}{i} = 2046$$

Notice we can either drop any of 1 to 10 of the initial starting values. Suppose 
we run the opportunity cost algorithm with 5 of 11 weeks picked, there are a 
total of $\binom{11}{5}$ ways of leaving 5 of the 11 weeks in the model. We are 
starting at the case of $\binom{11}{0}$ where all the spots are filled.

This approach generalizes to $ \sum_{i=1}^{W-1}\binom{W}{i} $ for $W$ total weeks 
of picks remaining.

We can make use of the $2^N$ functional form here and systematically loop through 
binary representations of each of the cases, where $1$ means to keep the row, 
and $0$ removes it. 



```r
number2binary <- function(number, noBits) {
   binary_vector <- rev(as.numeric(intToBits(number)))
   if(missing(noBits)) {
     return(binary_vector)
   } else {
     binary_vector[-(1:(length(binary_vector) - noBits))]
   }
}

# example of cases over 5 weeks to chose from
weeks <- 5
end <- 2^weeks

for(i in 1:end - 1){
  print(number2binary(i, weeks))
}
```

```
## [1] 0 0 0 0 0
## [1] 0 0 0 0 1
## [1] 0 0 0 1 0
## [1] 0 0 0 1 1
## [1] 0 0 1 0 0
## [1] 0 0 1 0 1
## [1] 0 0 1 1 0
## [1] 0 0 1 1 1
## [1] 0 1 0 0 0
## [1] 0 1 0 0 1
## [1] 0 1 0 1 0
## [1] 0 1 0 1 1
## [1] 0 1 1 0 0
## [1] 0 1 1 0 1
## [1] 0 1 1 1 0
## [1] 0 1 1 1 1
## [1] 1 0 0 0 0
## [1] 1 0 0 0 1
## [1] 1 0 0 1 0
## [1] 1 0 0 1 1
## [1] 1 0 1 0 0
## [1] 1 0 1 0 1
## [1] 1 0 1 1 0
## [1] 1 0 1 1 1
## [1] 1 1 0 0 0
## [1] 1 1 0 0 1
## [1] 1 1 0 1 0
## [1] 1 1 0 1 1
## [1] 1 1 1 0 0
## [1] 1 1 1 0 1
## [1] 1 1 1 1 0
## [1] 1 1 1 1 1
```

### Look for better solutions

If better solutions are found, they are saved to their own `trial_i.csv` file.

```r
check_other_solns <- function(picks){
  
  base_picks <- picks
  
  start_week <- 2
  total_weeks <- 13
  
  cases <- 2^(total_weeks - start_week)
  crit <- sum(base_picks$p_win)
  
  results <- list()
  
  for(i in 1:cases){
    
    drop <- as.logical(number2binary(i, nrow(base_picks)))
    dt_d <- base_picks[drop]
    
    past_weeks <- c(dt_d$week)
    past_picks <- c(dt_d$loser)
    
    start <- length(past_weeks)
    end <- total_weeks-2
    
    for(j in start:end){
    
      tmp <- dt[!week %in% past_weeks & !loser %in% past_picks, ]
      tmp <- tmp[order(week, p_win)]
      tmp[, oc:=shift(p_win, 1, type="lead") - p_win, by = week]
      tmp <- tmp[, .SD[1], week]
      tmp <- tmp[order(-oc)]
      pick <- tmp[, .SD[1]]
      
      past_weeks <- append(past_weeks, pick$week)
      past_picks <- append(past_picks, pick$loser)
      
    }
    
    # make into readable table
    picks <- setDT(data.frame(week = past_weeks, loser = past_picks))
    picks <- merge(picks, dt, on = week)
    
    # get total probability from new case
    test <- sum(picks$p_win)
    
    # save results into table
    picks$trial <- i
    results[[i]] <- picks
    
    # save better lineups to separate folder 
    if(test < crit){
      crit <- test
      print(paste("Better solution found, case: ", i))
      fwrite(picks, file = paste0("cases/trial_", i, ".csv"))
    }
    
  }
  
  # get results table
  trial_results <- do.call(rbind.data.frame, results)
    
  return(trial_results)
  
}

# loop through each of the picks

a1 <- check_other_solns(picks1)
```

```
## [1] "Better solution found, case:  1"
## [1] "Better solution found, case:  2"
```

```r
a2 <- check_other_solns(picks2)
```

```
## [1] "Better solution found, case:  1"
```

```r
a3 <- check_other_solns(picks3)

a1$start <- "Approach 1"
a2$start <- "Approach 2"
a3$start <- "Approach 3"

check_plot <- rbind(a1, a2, a3)
```

We only need to check Approach 3 above, as Approaches 1 and 2 will always result 
in Approach 3 in the case where we remove all of their choices. Approaches 1 and 2 
move towards the optimal solution, Approach 3 remains at the optimal solution, 
and therefore doesn't change when we plot the trial totals.


```r
totals <- check_plot[, .(total=sum(p_win)), .(trial, start)]
ggplot(totals, aes(x=trial, y=total)) + 
  geom_point() + 
  theme_bw() + 
  labs(title = "Total probability by trial", 
       x = "Trial Number", 
       y = "Total Probability") + 
  facet_wrap(.~start)
```

![](README_figs/README-unnamed-chunk-9-1.png)<!-- -->

## Visualize differences across models

### Dumbbell plot of Approaches 1, 2, and 3

```r
labs <- c("Week", "Team", "ProbWin")
names(picks1) <- labs
names(picks2) <- labs
names(picks3) <- labs

picks1$Approach <- 1
picks2$Approach <- 2
picks3$Approach <- 3

data <- rbind(picks1, picks2, picks3)
data$Approach <- as.factor(data$Approach)


theme_set(theme_bw(12))

ggplot(data, aes(x=Week, y=ProbWin, color = Approach, shape = Approach)) + 
  geom_line(aes(group = Week), color="#e3e2e1", size = 2) +
  geom_point(size = 3) + 
  xlim(3, 13) +
  coord_flip() + 
  scale_color_viridis_d() + 
  labs(title = "Comparing weekly win probabilities per Approach", 
       x = "Week Number", 
       y = "Win Probability")
```

![](README_figs/README-unnamed-chunk-10-1.png)<!-- -->


```r
ggplot() + 
  geom_point(data = dt, aes(x=week, y=p_win), alpha=0.3, color="black") + 
  geom_point(data = data, 
             aes(x=Week, y=ProbWin, color = Approach, shape = Approach), 
             size = 3, 
             alpha = 0.7) +
  scale_color_viridis_d() + 
  coord_flip() + 
  labs(title = "Selection plot - candidate and picks made by approach", 
       x = "Week Number", 
       y = "Win Probability")
```

![](README_figs/README-unnamed-chunk-11-1.png)<!-- -->


### Table of by week picks
We can see that Approach 3 has a lower probability on average, with a drastically 
lower probability of winning in week 4, as with Approach 2. Something that was 
overlooked in Approach 1. 

I've also included the standard deviation across all the weeks. Since the 
probability of making it to the following week is dependent on successfully losing 
the game the week prior, our probabilities multiply by week. We will get the 
largest probability of success when our probabilities are all similar to each other, 
i.e. have a smaller standard deviation. 

Looking at the first two moments, it is clear that Approach 3 provides the best 
pick. 


```r
tbl <- left_join(picks1, picks2, by="Week", suffix=c("_1", "_2"))
tbl <- left_join(tbl, picks3, by="Week", suffix=c("", "_3"))
tbl <- select(tbl, -c("Approach_1", "Approach_2", "Approach"))
names <- c("Week", rep(c("Team", "ProbWin"),3))
names(tbl) <- names

avg_1 <- mean(as.numeric(picks1$ProbWin))
avg_2 <- mean(as.numeric(picks2$ProbWin))
avg_3 <- mean(as.numeric(picks3$ProbWin))
avg_row <- data.frame("Mean", "", avg_1, "", avg_2, "", avg_3)
names(avg_row) <- names(tbl)

sd_1 <- sd(as.numeric(picks1$ProbWin))
sd_2 <- sd(as.numeric(picks2$ProbWin))
sd_3 <- sd(as.numeric(picks3$ProbWin))
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
   <td style="text-align:left;"> CHI </td>
   <td style="text-align:right;"> 0.173 </td>
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
   <td style="text-align:left;"> NYJ </td>
   <td style="text-align:right;"> 0.292 </td>
   <td style="text-align:left;"> CAR </td>
   <td style="text-align:right;"> 0.308 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 11 </td>
   <td style="text-align:left;"> IND </td>
   <td style="text-align:right;"> 0.292 </td>
   <td style="text-align:left;"> IND </td>
   <td style="text-align:right;"> 0.292 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.190 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 12 </td>
   <td style="text-align:left;"> MIN </td>
   <td style="text-align:right;"> 0.330 </td>
   <td style="text-align:left;"> MIN </td>
   <td style="text-align:right;"> 0.330 </td>
   <td style="text-align:left;"> MIN </td>
   <td style="text-align:right;"> 0.330 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 13 </td>
   <td style="text-align:left;"> DEN </td>
   <td style="text-align:right;"> 0.235 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.141 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.141 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> Mean </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.226 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.224 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.209 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> SD </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.065 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.081 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.066 </td>
  </tr>
</tbody>
</table>

## What is the difference between the QB adjusted rating and the normal ELO rating?

We can simply plot each teams win probability in both cases, as a dumbbell chart. 


```r
# data preprocessing
dt <- fread(path)

# calculate week, get proj loser and prob of loss. 
total_weeks <- 13
time_period <- seq(3, total_weeks, 1)

dt[, week:=floor(as.numeric(difftime(date, week1, units="days")) / 7) + 1]

t1 <- dt[, .(team1, elo_prob1, qbelo_prob1, week)]
t2 <- dt[, .(team2, elo_prob2, qbelo_prob2, week)]

names <- c("Team", "elo_prob", "qbelo_prob", "week")
names(t1) <- names
names(t2) <- names

data <- rbind(t1, t2)

# plot data 
ggplot(data, aes(y=week, x=elo_prob, xend=qbelo_prob)) +
  geom_dumbbell(size=1, color="#e3e2e1",
                colour_x = "#5b8124", colour_xend = "#bad744") + 
  labs(title = "Comparing ELO and QBELO win probabilities")
```

![](README_figs/README-unnamed-chunk-13-1.png)<!-- -->

```r
  facet_wrap(.~Team)
```

```
## <ggproto object: Class FacetWrap, Facet, gg>
##     compute_layout: function
##     draw_back: function
##     draw_front: function
##     draw_labels: function
##     draw_panels: function
##     finish_data: function
##     init_scales: function
##     map_data: function
##     params: list
##     setup_data: function
##     setup_params: function
##     shrink: TRUE
##     train_scales: function
##     vars: function
##     super:  <ggproto object: Class FacetWrap, Facet, gg>
```
Pretty crowded, look to subsetting the data, or other plots. Kernel density plot?

## Discounting
Can also look into discounting the differences of future weeks. 


## Simulations
We can move to comparing different models by simulating the season based on 
binomial probabilities. We can estimate for a given set of probabilities 
the percentage of times a set of picks reaches a given week. 


```r
# simulations ----------------------------------------
sim <- function(teams){
  week <- 0 # index at zero. If win, move past week 1. 
  
  for(p in teams$ProbWin){
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
start_week <- 3
opp_cost <- call_sim(picks3, N, "Oppertunity Cost")
week <- call_sim(picks2, N, "Lowest per week")
prob <- call_sim(picks1, N, "Lowest probability overall")

# Compare models
data <- rbind(opp_cost, week, prob)

ggplot(data, aes(x = week, y = cumprob, color = model)) + 
  geom_line() + 
  geom_point(alpha = 0.8) + 
  scale_x_continuous(expand = c(0, 0), limits = c(min(data$week), max(data$week) + 1)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1)) + 
  labs(title = "Cumulative probability of reaching a given week",
       x = "Week number", 
       y = "Pr(X < x)") + 
  theme_classic(10)
```

![](README_figs/README-unnamed-chunk-14-1.png)<!-- -->

From the above plot, there is not a significant difference between the in terms of 
probabilities of lasting to a given week. I suppose this is understandable given 
how similar the weekly averages are. 
