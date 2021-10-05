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



Below we can see a heatmap of all the win probabilities throughout the season. 
Teams like Houston, and Washington have a low lieklihood of winning in many 
games in the season. This motivates our problem as we can only pick them each 
once. 

![](README_figs/README-unnamed-chunk-3-1.png)<!-- -->

We can also limit our choices to the forecasted underdog, as there are more teams 
than weeks we should never need to pick a favourite. 
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
   <td style="text-align:left;"> 5 </td>
   <td style="text-align:left;"> MIA </td>
   <td style="text-align:right;"> 0.194 </td>
   <td style="text-align:left;"> MIA </td>
   <td style="text-align:right;"> 0.194 </td>
   <td style="text-align:left;"> MIA </td>
   <td style="text-align:right;"> 0.194 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 6 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.269 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.269 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.269 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 7 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.131 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.131 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.131 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 8 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.154 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.154 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.189 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 9 </td>
   <td style="text-align:left;"> MIN </td>
   <td style="text-align:right;"> 0.243 </td>
   <td style="text-align:left;"> MIN </td>
   <td style="text-align:right;"> 0.243 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.176 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 10 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.218 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.218 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.218 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> Mean </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.202 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.202 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.196 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> SD </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.052 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.052 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.046 </td>
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
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 0.81 </td>
   <td style="text-align:right;"> 0.81 </td>
   <td style="text-align:right;"> 0.81 </td>
   <td style="text-align:right;"> 0.81 </td>
   <td style="text-align:right;"> 0.81 </td>
   <td style="text-align:right;"> 0.74 </td>
   <td style="text-align:right;"> 0.81 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 0.59 </td>
   <td style="text-align:right;"> 0.59 </td>
   <td style="text-align:right;"> 0.59 </td>
   <td style="text-align:right;"> 0.59 </td>
   <td style="text-align:right;"> 0.59 </td>
   <td style="text-align:right;"> 0.54 </td>
   <td style="text-align:right;"> 0.59 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 0.51 </td>
   <td style="text-align:right;"> 0.51 </td>
   <td style="text-align:right;"> 0.51 </td>
   <td style="text-align:right;"> 0.51 </td>
   <td style="text-align:right;"> 0.51 </td>
   <td style="text-align:right;"> 0.47 </td>
   <td style="text-align:right;"> 0.51 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 0.42 </td>
   <td style="text-align:right;"> 0.42 </td>
   <td style="text-align:right;"> 0.42 </td>
   <td style="text-align:right;"> 0.43 </td>
   <td style="text-align:right;"> 0.43 </td>
   <td style="text-align:right;"> 0.39 </td>
   <td style="text-align:right;"> 0.43 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 0.34 </td>
   <td style="text-align:right;"> 0.34 </td>
   <td style="text-align:right;"> 0.34 </td>
   <td style="text-align:right;"> 0.33 </td>
   <td style="text-align:right;"> 0.33 </td>
   <td style="text-align:right;"> 0.30 </td>
   <td style="text-align:right;"> 0.33 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 0.27 </td>
   <td style="text-align:right;"> 0.27 </td>
   <td style="text-align:right;"> 0.27 </td>
   <td style="text-align:right;"> 0.26 </td>
   <td style="text-align:right;"> 0.26 </td>
   <td style="text-align:right;"> 0.24 </td>
   <td style="text-align:right;"> 0.26 </td>
  </tr>
</tbody>
<tfoot>
<tr><td style="padding: 0; " colspan="100%"><span style="font-style: italic;">Note: </span></td></tr>
<tr><td style="padding: 0; " colspan="100%">
<sup></sup> Percentages represent the likelihood of reaching a given <br>           week based on the picks from each model.</td></tr>
</tfoot>
</table>

As expected, we have better chances earlier when using a discount value less than 
one for the Opportunity Cost model. 

<table class=" lightable-classic" style='font-family: "Arial Narrow", "Source Sans Pro", sans-serif; width: auto !important; margin-left: auto; margin-right: auto;'>
<caption>Weekly Picks by Model</caption>
 <thead>
<tr>
<th style="empty-cells: hide;" colspan="1"></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">OC, Beta = 1</div></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">OC, Beta = 0.9</div></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">OC, Beta = 0.7</div></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">By Week</div></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">Prob, Beta = 1</div></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">Prob, Beta = 0.9</div></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">Prob, Beta = 0.7</div></th>
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
   <th style="text-align:left;"> Team </th>
   <th style="text-align:right;"> ProbWin </th>
   <th style="text-align:left;"> Team </th>
   <th style="text-align:right;"> ProbWin </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 5 </td>
   <td style="text-align:left;"> MIA </td>
   <td style="text-align:right;"> 0.194 </td>
   <td style="text-align:left;"> MIA </td>
   <td style="text-align:right;"> 0.194 </td>
   <td style="text-align:left;"> MIA </td>
   <td style="text-align:right;"> 0.194 </td>
   <td style="text-align:left;"> MIA </td>
   <td style="text-align:right;"> 0.194 </td>
   <td style="text-align:left;"> MIA </td>
   <td style="text-align:right;"> 0.194 </td>
   <td style="text-align:left;"> MIA </td>
   <td style="text-align:right;"> 0.194 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.261 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 6 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.269 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.269 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.269 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.269 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.269 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.269 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.269 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 7 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.131 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.131 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.131 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.131 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.131 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.131 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.131 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 8 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.189 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.189 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.189 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.154 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.154 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.154 </td>
   <td style="text-align:left;"> MIA </td>
   <td style="text-align:right;"> 0.163 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 9 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.176 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.176 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.176 </td>
   <td style="text-align:left;"> MIN </td>
   <td style="text-align:right;"> 0.243 </td>
   <td style="text-align:left;"> MIN </td>
   <td style="text-align:right;"> 0.243 </td>
   <td style="text-align:left;"> MIN </td>
   <td style="text-align:right;"> 0.243 </td>
   <td style="text-align:left;"> MIN </td>
   <td style="text-align:right;"> 0.243 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 10 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.218 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.218 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.218 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.218 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.218 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.218 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.199 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> Mean </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.196 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.196 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.196 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.202 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.202 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.202 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.211 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> SD </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.046 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.046 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.046 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.052 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.052 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.052 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.056 </td>
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
 <thead>
<tr>
<th style="empty-cells: hide;" colspan="1"></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">Optimal Pick</div></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="2"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">Next Best</div></th>
</tr>
  <tr>
   <th style="text-align:left;"> week </th>
   <th style="text-align:left;"> loser </th>
   <th style="text-align:right;"> p_win </th>
   <th style="text-align:left;"> loser </th>
   <th style="text-align:right;"> p_win </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 5 </td>
   <td style="text-align:left;"> MIA </td>
   <td style="text-align:right;"> 0.194 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.261 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 6 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.269 </td>
   <td style="text-align:left;"> WSH </td>
   <td style="text-align:right;"> 0.269 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 7 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.131 </td>
   <td style="text-align:left;"> DET </td>
   <td style="text-align:right;"> 0.131 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 8 </td>
   <td style="text-align:left;"> NYG </td>
   <td style="text-align:right;"> 0.189 </td>
   <td style="text-align:left;"> MIA </td>
   <td style="text-align:right;"> 0.163 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 9 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.176 </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:right;"> 0.176 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 10 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.218 </td>
   <td style="text-align:left;"> ATL </td>
   <td style="text-align:right;"> 0.218 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> Mean </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.196 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.203 </td>
  </tr>
  <tr>
   <td style="text-align:left;font-weight: bold;"> SD </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.046 </td>
   <td style="text-align:left;font-weight: bold;">  </td>
   <td style="text-align:right;font-weight: bold;"> 0.055 </td>
  </tr>
</tbody>
</table>

The above analysis is not very supportive of not taking MIA in both picks next week. 
This analysis is flawed, as we rule out the first pick in each week. 

