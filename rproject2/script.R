#DATI FORNITI
Y <- c(7, 8, 9, 4, 7, 1, 8, 5, 6, 7, 0, 1, 6, 7, 9)
N <- sum(xtabs(~Y))

#DEFINISCO LE VARIABILI PER LAMBDA (parametri e iperparametri)
alpha0 <- 10 #totale mail arrivate in 
beta0 <- 3 #settimane
alpha1 <- alpha0 + sum(Y)
beta1 <- beta0 + N

# 1) Implementazione del modello
library(rstan)
data <- list(N, Y)

modPG <- '
data {
int N;
int Y[N];
int alpha0;
int beta0;
}
transformed data{

}

parameters {
real<lower=0> Lambda;

}
transformed parameters {

}
model {
Lambda ~ gamma(alpha0,beta0);
Y ~ poisson(Lambda);
}
'

require(rstan)
iniTime <- date()
mod <- stan_model(model_code = modPG)
endTime <- date();
c(iniTime = iniTime, endTime = endTime)

# 2) Ottieni un campione simulato dalla a-posteriori

#SAMPLING E GENERAZIONE DELLE CATENE A POSTERIORI
library(rstudioapi)
system.time(
  fit <<- sampling(mod,
                  data = data,
                  pars = c("Lambda"), #a noi interessa capire la distribuzione di Lambda, non di Y. 
                                      #Perch� dopo che si campiona lambda si capisce come distribuisce la Y
                  chains = 4,
                  iter = 25000,
                  warmup = 10000,
                  thin = 5,
                  cores = 4,
                  seed = 1997,
                  control = list(max_treedepth = 10,
                                adapt_delta = 0.8)
  )
)

testModel <- stan(model_code = modPG, data = data, iter = 100, chains = 4)

# 3) Esplora le diagnostiche di output e discuti i risultati

require(ggmcmc)
outSim <- ggs(fit)
print(outSim)

###traceplots
require(ggthemes)
ggs_traceplot(outSim) + theme_fivethirtyeight()

### Densita
ggs_density(outSim) + theme_solarized(light = TRUE)

### R cappello ovvero diagnostica di Gelman
ggs_Rhat(outSim) + xlab("R_hat")

### diagnostica di Geweke (solo per normali standardizzate)
ggs_geweke(outSim)

### diagnostica con Caterpillar
ggs_caterpillar(outSim)

#intervalli di credibilit?
ci(outSim)

# sintesi per coppie di parametri
ggs_pairs(outSim, lower = list(continuous = "density"))

# riassunti numeri e diagnostica
summary(fit)

# 4) Riassumi le caratteristiche principali della distribuzione a-posteriori

#   A vedere dal traceplot e dal density plot la sovrapposizione della 4 catene � buona. Magari dal density plot soprattutto si nota qualche discrepanza in pi�
#   Gelman invece mostra che non ci sono fattori di potenziale riduzione di scala per Lambda. Il che avalla la tesi sulla discreta bont� del modello.
#   Bont� avallata anche da Geweke, dato che tutte le catene sono comprese su valori Z fra -2 e 2
#   Il grafico Caterpillar mostra invece che la credibilit� di lambda � alta fra circa 4,5 e 6,25
#   gg_pairs non funziona per qualche motivo
#   La funzione summary() aiuta a monitorare numericamente quanto detto fin'ora: vale a dire che le catene si sovrappongono e non ci sono problemi con il modello.

# 5) Ottieni la distribuzione prededittiva della futura osservazione con un campione di dimensione 10k. 

modPGp <- '
data {
int N;
int Y[N];
}
parameters {
real<lower=0> Lambda;

}
transformed parameters {

}
model {
Lambda ~ gamma(95,18);
Y ~ poisson(Lambda);
}
generated quantities{
real Y_predict;
Y_predict = poisson_rng(Lambda);
}
'
iniTime <- date()
mod <- stan_model(model_code = modPGp)
endTime <- date();
c(iniTime = iniTime, endTime = endTime)

#campionamento
system.time(
  fit <<- sampling(mod,
                  data = data,
                  pars = c("Lambda", "Y_predict"),
                  chains = 4,
                  iter = 25000,
                  warmup = 10000,
                  thin = 5,
                  cores = 6,
                  seed = 1997,
                  control = list(max_treedepth = 10,
                  adapt_delta = 0.8)
  )
)

require(ggmcmc)
outSim <- ggs(fit)
print(outSim)

###traceplots
require(ggthemes)
ggs_traceplot(outSim) + theme_fivethirtyeight()

### Densita
ggs_density(outSim) + theme_solarized(light = TRUE)

### R cappello ovvero diagnostica di Gelman
ggs_Rhat(outSim) + xlab("R_hat")

### diagnostica di Geweke (solo per normali standardizzate)
ggs_geweke(outSim)

### diagnostica con Caterpillar
ggs_caterpillar(outSim)

#intervalli di credibilit?
ci(outSim)

# sintesi per coppie di parametri
ggs_pairs(outSim, lower = list(continuous = "density"))

# riassunti numeri e diagnostica
summary(fit)

#    Riassumi le sue caratteristiche.



# 6) Confronta i risultati ottenuti via simulazione MCMC con i risultati esatti sopra riportati

outSim = ggs(fit)
MailsOsservate <- c(mean(Y))
ggs_density(outSim, family = "Y_predict") + geom_vline(xintercept = MailsOsservate, color = "red") + geom_vline(xintercept = Y, color = "blue")

#    Mediamente arrivano 5,6 email al giorno. 
#    Il valore sta dentro alla distribuzione che risulta dal modello predittivo.
#    Si pu� dire che ci si pu� aspettare fra le 5 e le 6 email al giorno.
#    Guardando anche i valori osservati si pu� dire che in generale non ci sono "fughe" verso valori improbabili
