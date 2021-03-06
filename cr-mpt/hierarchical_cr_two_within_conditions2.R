# Hierarchical simplified conjoint recognition model
# with random participant intercept, heterogeneous
# parameter variance across conditions, and participant-
# condition interaction term

data {
  dimx <- dim(x)
  n_subject <- dimx[1]
  n_c1 <- dimx[2] # Number of conditions in factor 1
  n_c2 <- dimx[3] # Number of conditions in factor 2
  n_param <- 3 # V, G, & b
  wish_df <- n_param + 1 # Resulting degrees of freedom for inverse Wishart distribution
}

model {

  # Data generating model ---------------------------------------------------

  for(i in 1:n_subject) {
    for(c1 in 1:n_c1) {
      for(c2 in 1:n_c2) {

        ## Targets
        x[i, c1, c2, 1] ~ dbin(V[i, c1, c2] + (1 - V[i, c1, c2]) * (G[i, c1, c2] + (1 - G[i, c1, c2]) * b[i]), n_items[1])

        ## Lures
        x[i, c1, c2, 2] ~ dbin(G[i, c1, c2] + (1 - G[i, c1, c2]) * b[i], n_items[1])
      }
    }

    ## New distractors
    y[i] ~ dbin(b[i], n_items[2])
  }

  # Parameter transformation ------------------------------------------------

  for(i in 1:n_subject) {
    for(c1 in 1:n_c1) {
      for(c2 in 1:n_c2) {
        V[i, c1, c2] <- phi(V_hat[i, c1, c2])
        G[i, c1, c2] <- phi(G_hat[i, c1, c2])
      }
    }
    b[i] <- phi(b_hat[i])
  }

  ## Assamble scaled additive participant effects on probit scale
  for(i in 1:n_subject) {
    for(c1 in 1:n_c1) {
      for(c2 in 1:n_c2) { # V = xi_part[1:(n_c1 + n_c2)]; G = xi_part[(n_c1 + n_c2 + 1):(n_param - 1)]
        V_hat[i, c1, c2] ~ dnorm(mu_V_hat[c1, c2] + xi_part_V[c1, c2] * delta_mu_hat_part[i, 1], tau_int[1])
        G_hat[i, c1, c2] ~ dnorm(mu_G_hat[c1, c2] + xi_part_G[c1, c2] * delta_mu_hat_part[i, 2], tau_int[2])
      }
    }
    b_hat[i] ~ dnorm(mu_b_hat + xi_part_b * delta_mu_hat_part[i, n_param], tau_int[n_param])
  }

  # Level 1 prior -----------------------------------------------------------

  ## Random participant deviations with mean 0
  for(i in 1:n_subject) {
    delta_mu_hat_part[i, 1:n_param] ~ dmnorm(rep(0, n_param), sigma_inv)
  }

  ## Participant-condition interaction
  for(i in 1:n_param) {
    sigma_int[i] ~ dunif(0, 100)
  }
  tau_int <- sigma_int^-2

  ## Scaling parameter (see Gelaman & Hill, 2007, Chapter 13 & 17)
  for(c1 in 1:n_c1) {
    for(c2 in 1:n_c2) {
      xi_part_V[c1, c2] ~ dunif(0, 100)
      xi_part_G[c1, c2] ~ dunif(0, 100)
    }
  }
  xi_part_b ~ dunif(0, 100)

  # Level 2 prior on condition means ----------------------------------------

  ## Condition means
  for(c1 in 1:n_c1) {
    for(c2 in 1:n_c2) {
      mu_V_hat[c1, c2] ~ dnorm(0, 1)
      mu_G_hat[c1, c2] ~ dnorm(0, 1)
    }
  }
  mu_b_hat ~ dnorm(0, 1)

  ## Parameter variance and correlations
  sigma_inv[1:n_param, 1:n_param] ~ dwish(I_part[1:n_param, 1:n_param], wish_df)
}
