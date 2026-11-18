data {
  int                    n_years;         // n years
  int                    n_obs;           // number of spawner count obs
  int                    n_groups;         // number of groups 
  
  array[n_obs] int<lower=1, upper=n_years> year;
  array[n_obs] int day;
  array[n_obs] int live_counts;
  
  array[n_obs] int<lower=1, upper=n_groups> group;
  
  int<lower=1> n_survey_error_groups;
  array[n_obs] int<lower=1, upper=n_survey_error_groups> survey_error_group_id;
  
  int<lower=0, upper=1> outlier_model;
  
  //priors
  // abundance priors
  vector<lower=0>[n_groups] abundance_prior_mean;
  vector<lower=0>[n_groups] abundance_prior_sdlog;
  
  // arrival date
  real arrival_prior_mean;
  real<lower=0> arrival_prior_sd;
  
  // arrival spread
  real spread_prior_mean;
  real<lower=0> spread_prior_sd;
  
  // exit lag
  real exit_lag_prior_mean;
  real<lower=0> exit_lag_prior_sd;
  
  // annual timing variation priors
  real<lower=0> arrival_sigma_prior_mean;
  real<lower=0> arrival_sigma_prior_sd;
  
  real<lower=0> arrival_spread_sigma_prior_mean;
  real<lower=0> arrival_spread_sigma_prior_sd;
  
  real<lower=0> exit_lag_sigma_prior_mean;
  real<lower=0> exit_lag_sigma_prior_sd;
  
  real<lower=0> exit_spread_sigma_prior_mean;
  real<lower=0> exit_spread_sigma_prior_sd;
  
  // observation dispersion
  real count_dispersion_prior_mean;
  real<lower=0> count_dispersion_prior_sd;
}

parameters {
  // grand mean timing parameters
  vector[4] timing_mu;
  
  // persistent group effects
  array[n_groups] vector[4] group_effect_raw;
  
  cholesky_factor_corr[4] L_Omega_group;
  vector<lower=0>[4] timing_sigma_group;
  
  // annual timing effects
  matrix[n_years, 4] year_effect_raw;
  
  cholesky_factor_corr[4] L_Omega_year;
  vector<lower=0>[4] timing_sigma_year;
  
  // group-year timing deviations
  array[n_years, n_groups] vector[4] group_year_dev_raw;
  
  vector<lower=0>[4] timing_sigma_group_year;
  
  // abundance
  matrix[n_years, n_groups] log_run;
  
  // observation error
  vector<lower=1>[n_survey_error_groups] live_phi;
  
  // outlier model
  real<lower=0, upper=1> p_outlier;
  real<lower=1> outlier_multiplier;
}

transformed parameters{
  array[n_years, n_groups] vector[4] timing;
  
  array[n_groups] vector[4] group_effect;
  array[n_years] vector[4] year_effect;
  
  matrix[n_years, n_groups] arrival;
  matrix[n_years, n_groups] arrival_spread;
  matrix[n_years, n_groups] exit_lag;
  matrix[n_years, n_groups] exit_spread;
  
  matrix[4,4] L_Sigma_group = diag_pre_multiply(timing_sigma_group, L_Omega_group);
  matrix[4,4] L_Sigma_year = diag_pre_multiply(timing_sigma_year, L_Omega_year);
  
  vector[n_obs] live_mu;
  
  for (r in 1:n_groups) {
    group_effect[r] =  L_Sigma_group * group_effect_raw[r];
  }
  
  for(y in 1:n_years){
    year_effect[y] = L_Sigma_year * (year_effect_raw[y]');
  }
  
  for (y in 1:n_years) {
    for (r in 1:n_groups) {
      timing[y,r] = timing_mu + 
      group_effect[r] + 
      year_effect[y] +  
      timing_sigma_group_year .* group_year_dev_raw[y,r];
      
      arrival[y,r] = timing[y,r][1];
      arrival_spread[y,r] = exp(timing[y,r][2]) + 1;
      exit_lag[y,r] = exp(timing[y,r][3]) + 1;
      exit_spread[y,r] =  exp(timing[y,r][4]) + 1;
    }
  }
  
  //process model
  for (i in 1:n_obs) {
    real mean_arrival = arrival[year[i], group[i]];
    real arrival_spread_i = arrival_spread[year[i], group[i]];
    real exit_lag_i = exit_lag[year[i], group[i]];
    real exit_spread_i = exit_spread[year[i], group[i]];
    
    real entered = normal_cdf(day[i] | mean_arrival, arrival_spread_i);
    real exited = normal_cdf(day[i] | mean_arrival + exit_lag_i, exit_spread_i);
    real log_p = log(fmin(fmax(entered * (1 - exited), 1e-5), 1.0));
    real log_mu =log_run[year[i], group[i]] + log_p;
    
    live_mu[i] = exp(log_mu);
  }
  
}

model {
  timing_mu[1] ~ normal(arrival_prior_mean, arrival_prior_sd);
  timing_mu[2] ~ normal(spread_prior_mean, spread_prior_sd);
  timing_mu[3] ~ normal(exit_lag_prior_mean, exit_lag_prior_sd);
  timing_mu[4] ~ normal(spread_prior_mean, spread_prior_sd);
  
  timing_sigma_group[1] ~ lognormal(log(arrival_sigma_prior_mean), arrival_sigma_prior_sd);
  timing_sigma_group[2] ~ lognormal(log(arrival_spread_sigma_prior_mean), arrival_spread_sigma_prior_sd);
  timing_sigma_group[3] ~ lognormal(log(exit_lag_sigma_prior_mean), exit_lag_sigma_prior_sd);
  timing_sigma_group[4] ~ lognormal(log(exit_spread_sigma_prior_mean), exit_spread_sigma_prior_sd);
  
  
  
  timing_sigma_year[1] ~ lognormal(log(arrival_sigma_prior_mean), arrival_sigma_prior_sd);
  timing_sigma_year[2] ~ lognormal(log(arrival_spread_sigma_prior_mean), arrival_spread_sigma_prior_sd);
  timing_sigma_year[3] ~ lognormal(log(exit_lag_sigma_prior_mean), exit_lag_sigma_prior_sd);
  timing_sigma_year[4] ~ lognormal(log(exit_spread_sigma_prior_mean), exit_spread_sigma_prior_sd);
  
  timing_sigma_group_year[1] ~ lognormal(log(arrival_sigma_prior_mean), arrival_sigma_prior_sd);
  timing_sigma_group_year[2] ~  lognormal(log(arrival_spread_sigma_prior_mean), arrival_spread_sigma_prior_sd);
  timing_sigma_group_year[3] ~ lognormal(log(exit_lag_sigma_prior_mean), exit_lag_sigma_prior_sd);
  timing_sigma_group_year[4] ~ lognormal(log(exit_spread_sigma_prior_mean), exit_spread_sigma_prior_sd);
  
  L_Omega_group ~ lkj_corr_cholesky(2);
  L_Omega_year ~ lkj_corr_cholesky(2);
  
  to_vector(year_effect_raw) ~ std_normal();
  
  for (r in 1:n_groups) {
    group_effect_raw[r] ~ std_normal();
  }
  
  for (y in 1:n_years) {
    for (r in 1:n_groups) {
      group_year_dev_raw[y,r] ~ std_normal();
    }
  }
  
  // simple PDD
  for (y in 1:n_years) {
    for (r in 1:n_groups) {
      log_run[y, r] ~ normal(log(abundance_prior_mean[r]), abundance_prior_sdlog[r]);
    }
  }
  
  log(live_phi) ~ normal(count_dispersion_prior_mean, count_dispersion_prior_sd);  
  p_outlier ~ beta(1, 20);
  outlier_multiplier ~ lognormal(log(10), 0.5);
  
  //likelihood
  for (n in 1:n_obs) {
    if (outlier_model == 1) {
      
      real lp_regular = neg_binomial_2_lpmf(live_counts[n] | live_mu[n], live_phi[survey_error_group_id[n]]);
      
      real lp_outlier = neg_binomial_2_lpmf(live_counts[n] | live_mu[n], live_phi[survey_error_group_id[n]] / outlier_multiplier);
      
      target += log_mix(p_outlier, lp_outlier, lp_regular);
      
    } else {
      live_counts[n] ~ neg_binomial_2(live_mu[n], live_phi[survey_error_group_id[n]]);
    }
  }
}

generated quantities {
  
  vector[n_obs] p_is_outlier;
  
  if (outlier_model == 1) {
    
    for (n in 1:n_obs) {
      
      real lp_regular = neg_binomial_2_lpmf(live_counts[n] | live_mu[n], live_phi[survey_error_group_id[n]]);
      
      real lp_outlier = neg_binomial_2_lpmf(live_counts[n] | live_mu[n], live_phi[survey_error_group_id[n]] / outlier_multiplier);
      
      p_is_outlier[n] = exp(log(p_outlier) + lp_outlier -
      log_sum_exp(log(p_outlier) + lp_outlier,
      log1m(p_outlier) + lp_regular));
    }
  } else {
    p_is_outlier = rep_vector(0, n_obs);
  }
}
