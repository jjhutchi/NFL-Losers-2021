---
title: "NFL Losers Pool 2021 Exploration Continued..."
author: "Jordan Hutchings"
date: "13/09/2021"
output: 
  html_document:
    keep_md: true
---




## Make picks based on oppertunity cost

Data pre-processing using `data.table`

```r
pacman::p_load(data.table, ggplot2, ggalt, dplyr, knitr, kableExtra)

# Data preprocessing ----------------------------------------------------------
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
```

## algorithm to make the best pick

```r
dt <- dt[order(week, p_win)]

past_weeks <- c(1)
past_picks <- c("DAL")

# pick the lowest win probability per week with the highest 
# opportunity cost if not picked.
tmp <- dt[!week %in% past_weeks & !loser %in% past_picks, ]
tmp[, oc:=shift(p_win, 1, type="lead") - p_win, by = week]
tmp <- tmp[, .SD[1], week]
tmp <- tmp[order(-oc)]
pick <- tmp[, .SD[1]]

past_weeks <- append(past_weeks, pick$week)
past_picks <- append(past_picks, pick$pick)
```

The above code will make the pick on a one-off basis. Next, we need to make the 
code so that it will fill in all the weekly picks. 


```r
past_weeks <- c(1)
past_picks <- c("DAL")

start_week <- 3
total_weeks <- 13

for(i in start_week:total_weeks){
  
  tmp <- dt[!week %in% past_weeks & !loser %in% past_picks, ]
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
```

The above code systematically prints out the best pick per week using the opportunity 
cost of the next best team in a given week. 

There is some concern that this hits a local but not global minimum total win 
probability. In order to test this, I will remove weekly picks, adding them 
back into the pool of teams that can be selected, and will compute the best 
picks with the teams now available for selection. Ideally, this will cover 
slight modifications to the possible picks. We will rank the picks based on the 
total probability.

I make a vector called `drop` which will contain given weeks, these weeks and 
their corresponding teams will be dropped from the `past_week` and `past_picks` 
vectors. Then we will fill in those weeks with teams from the remaining pool 
of possible using the opportunity cost approach. 

We can calculate the total number of possible drops we can make in $N$ weeks 
as the following: 

$$ \sum_{i=0}^N\binom{N}{i} = 2^N $$

There are some obvious cases we can discard, i.e. when $i=0$ or $i=14$ we will 
reach our initial solution, therefore, we actually have
$$ \sum_{i=1}^{N-1}\binom{N}{i} = 2^N - 2 $$ cases to check.

We can make use of the binomial nature here in determining whether to drop weeks 
or not in our loop. 

For example, we can count to the number of choices using binary, and use the 
binary representation to filter out rows in our initial dataset.

Suppose there are 5 weeks, $2^5 = 32$ therefore, there are $32$ cases to check. 
Each of the 32 binary representations will cover all the permutations of possible 
solutions to the equation $\sum_{i=0}^5\binom{5}{i}$. We can also begin at $i=1$ 
and stop at $i=5$ in this case to avoid the situations which bring us back to 
our initial solution.


```r
number2binary <- function(number, noBits) {
       binary_vector <- rev(as.numeric(intToBits(number)))
       if(missing(noBits)) {
          return(binary_vector)
       } else {
          binary_vector[-(1:(length(binary_vector) - noBits))]
       }
}

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

We can see that by converting a binary string to logical, we are able to subset 
rows from our data.table of picks. Now, we have a method to systematically check 
each result of our algorithm if we put teams back into the pool. 


```r
test_filter <- c(rep(c(1, 0), 5), 1)
test_filter <- as.logical(test_filter)

picks[test_filter] # should keep every other row.
```

```
##    week loser     p_win
## 1:    3   NYJ 0.2135926
## 2:    5   MIA 0.2563329
## 3:    7   CHI 0.1731908
## 4:    9   ATL 0.2026499
## 5:   11   DET 0.1898022
## 6:   13   JAX 0.1413606
```

## Looking for better solutions


```r
cases <- 2^(total_weeks-2)

obj <- sum(picks$p_win) # total sum of inital solution

op <- picks

for(i in 1:cases){
  drop <- as.logical(number2binary(i, total_weeks-2))
  dt_d <- picks[drop]
  
  past_weeks <- c(dt_d$week)
  past_picks <- c(dt_d$loser)
  
  start <- length(past_weeks)
  end <- total_weeks-2
  
  for(j in start:end){
  
    tmp <- dt[!week %in% past_weeks & !loser %in% past_picks, ]
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
  perf <- sum(picks$p_win)
  
  # save better lineups to separate folder 
  if(perf < obj){
    obj <- perf
    print(paste("Better solution found, case: ", i))
    fwrite(picks, file = paste0("cases/trial_", i, ".csv"))
  }
  
}
```

```
## [1] "Better solution found, case:  32"
## [1] "Better solution found, case:  1056"
```

## Compare the better results

Read in all the data sets

```r
fnames <- dir("cases/", pattern = "csv")

read_data <- function(z){
  dat <- fread(z)
  dat$file <- z
  return(dat)
}

datalist <- lapply(paste0("cases/", fnames), read_data)

data <- rbindlist(datalist, use.names = TRUE)

op$file <- "inital"
data <- rbind(data, op)
```

## Compare with plots


```r
ggplot2::ggplot(data, aes(x=week, y=p_win, color = file, shape = file)) + 
  geom_line(aes(group = week), color="#e3e2e1", size = 2) +
  geom_point(size = 3) + 
  xlim(3, 13) + 
  coord_flip() + 
  scale_color_viridis_d() + 
  labs(title = "Alternative approaces to the optimal picks", 
       x = "Week Number", 
       y = "Win Probability")
```

![](README_figs/README-unnamed-chunk-9-1.png)<!-- -->

```r
tbl <- dcast(data, week ~ file, value.var = "p_win")
tbl
```

```
##     week cases/trial_1056.csv cases/trial_32.csv    inital
##  1:    3            0.2135926          0.2135926 0.2135926
##  2:    4            0.1242331          0.1242331 0.3089509
##  3:    5            0.2563329          0.2563329 0.2563329
##  4:    6            0.3120104          0.3120104 0.2002378
##  5:    7            0.1731908          0.1731908 0.1731908
##  6:    8            0.1525813          0.1525813 0.1525813
##  7:    9            0.2026499          0.2026499 0.2026499
##  8:   10            0.2322563          0.3081115 0.3081115
##  9:   11            0.2497751          0.1898022 0.1898022
## 10:   12            0.3303418          0.3303418 0.3303418
## 11:   13            0.1413606          0.1413606 0.1413606
```

```r
first <- data[file == "inital"]
second <- data[file == "cases/trial_32.csv"]
third <- data[file == "cases/trial_1056.csv"]

tbl <- dplyr::left_join(first, second, by="week", suffix=c("_1", "_2"))
tbl <- dplyr::left_join(tbl, third, by="week", suffix=c("", "_3"))
tbl <- select(tbl, -c("file_1", "file_2", "file"))
names <- c("Week", rep(c("Team", "ProbWin"),3))
names(tbl) <- names

avg_1 <- mean(as.numeric(first$p_win))
avg_2 <- mean(as.numeric(second$p_win))
avg_3 <- mean(as.numeric(third$p_win))
avg_row <- data.frame("Mean", "", avg_1, "", avg_2, "", avg_3)
names(avg_row) <- names(tbl)

sd_1 <- sd(as.numeric(first$p_win))
sd_2 <- sd(as.numeric(second$p_win))
sd_3 <- sd(as.numeric(third$p_win))
sd_row <- data.frame("SD", "", sd_1, "", sd_2, "", sd_3)
names(sd_row) <- names(tbl)

tbl <- rbind(tbl, avg_row)
tbl <- rbind(tbl, sd_row)

kbl(tbl, digits=3) %>%
  kable_classic(full_width=F) %>%
  add_header_above(c(" " = 1, "Inital" = 2, "Trial 32" = 2, "Trial 1056" = 2)) %>%
  row_spec(total_weeks - 1, bold=T) %>%
  row_spec(total_weeks, bold=T)
```

<table class=" lightable-classic" style='font-family: "Arial Narrow", "Source Sans Pro", sans-serif; width: auto !important; margin-left: auto; margin-right: auto;'>
 <thead>
<tr>
<th style="empty-cells: hide;" colspan="1"></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">Inital</div></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">Trial 32</div></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">Trial 1056</div></th>
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
   <td style="text-align:left;"> NYJ </td>
   <td style="text-align:right;"> 0.214 </td>
   <td style="text-align:left;"> NYJ </td>
   <td style="text-align:right;"> 0.214 </td>
   <td style="text-align:left;"> NYJ </td>
   <td style="text-align:right;"> 0.214 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> OAK </td>
   <td style="text-align:right;"> 0.309 </td>
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
   <td style="text-align:left;"> MIA </td>
   <td style="text-align:right;"> 0.256 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 6 </td>
   <td style="text-align:left;"> HOU </td>
   <td style="text-align:right;"> 0.200 </td>
   <td style="text-align:left;"> OAK </td>
   <td style="text-align:right;"> 0.312 </td>
   <td style="text-align:left;"> OAK </td>
   <td style="text-align:right;"> 0.312 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 7 </td>
   <td style="text-align:left;"> CHI </td>
   <td style="text-align:right;"> 0.173 </td>
   <td style="text-align:left;"> CHI </td>
   <td style="text-align:right;"> 0.173 </td>
   <td style="text-align:left;"> CHI </td>
   <td style="text-align:right;"> 0.173 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 8 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.153 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.153 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.153 </td>
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
   <td style="text-align:left;"> CAR </td>
   <td style="text-align:right;"> 0.308 </td>
   <td style="text-align:left;"> CAR </td>
   <td style="text-align:right;"> 0.308 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.232 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 11 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.190 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.190 </td>
   <td style="text-align:left;"> DAL </td>
   <td style="text-align:right;"> 0.250 </td>
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
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.141 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.141 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.141 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> Mean </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.225 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.219 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.217 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> SD </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.066 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.073 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.067 </td>
  </tr>
</tbody>
</table>

As we can see, the latest trial solution found a lower total and had a similar 
standard deviation. These appear to be changes in the timing of Houston and Oakland.
