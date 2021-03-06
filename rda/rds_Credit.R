rm(list = ls())
dev.off()
devtools::load_all()
source("R/ksfilter.R")
pacman::p_load(data.table)
pacman::p_load(magrittr)
pacman::p_load(genefilter)
pacman::p_load(tidyverse)
pacman::p_load(latex2exp)
pacman::p_load(glmnet)
pacman::p_load(splines)
pacman::p_load(doParallel)
pacman::p_load(splines)
pacman::p_load(foreach)
pacman::p_load(doMC)

library(ISLR)
data("Credit")
Credit
data("Default")
Default
Credit$Ethnicity %>% table

c_dat <- Credit %>%
  dplyr::select(-ID) %>%
  mutate(Student = ifelse(Student=="No",0,1),
         Gender = ifelse(Gender=="Male",0,1),
         Married = ifelse(Married=="No",0,1),
         Ethnicity = ifelse(Ethnicity=="Caucasian", 0, ifelse(Ethnicity=="Asian",1,2))) %>% as.matrix()

# dput(colnames(c_dat))
preds <- c("Income", "Limit", "Rating", "Cards", "Age", "Education", #"Gender",
           "Student", "Married", "Ethnicity")
evar <- "Student"

X <- c_dat[,setdiff(preds,evar)]
E <- c_dat[,evar,drop=F]
Y <- c_dat[,"Balance",drop = F]

fitls <- lm(Balance ~ ., data = Credit)
summary(fitls)
sum(abs(coef(fitls)[-1]))

fitnet <- glmnet(x = c_dat[,c(preds, "Gender")], y = Y)

plot(fitnet, xvar = "lambda")
fit_lasso <- cv.glmnet(x = c_dat[,c(preds, "Gender")], y = Y)
plot(fit_lasso)
fit_lasso$cvm[which(fit_lasso$lambda.min==fit_lasso$lambda)]
coef(fit_lasso)
colSums(abs(coef(fitnet)[-1,]), na.rm = TRUE)


f.basis <- function(i) splines::bs(i, df = 3)
system.time(
  fit <- sail(x = X, y = Y, e = E, basis = f.basis, alpha = 0.5, verbose = 2,
              strong = FALSE)
)

X[, "Cards"] %>% splines::bs()
preds_expand <- c("Income", "Limit", "Rating", "Cards", "Age", "Education")

fmla <- reformulate(c(sapply(preds_expand, function(i) sprintf("bs(%s)",i)),
                      "Married", "Ethnicity","Gender"), intercept = FALSE)

model_mat <- model.matrix(fmla, data = as.data.frame(c_dat))
head(model_mat)

registerDoMC(cores = 8)
system.time(
  fit <- sail(x = model_mat, y = Y, e = E,
              strong = FALSE,
              alpha = 0.5,
              verbose = 2,
              expand = FALSE,
              group = attr(model_mat,"assign"))
)

plot(fit)

system.time(
  cvfit <- cv.sail(x = model_mat, y = Y, e = E,
                   parallel = TRUE,
                   strong = TRUE,
                   # dfmax = 30,
                   nfolds = 5,
                   alpha = 0.5,
                   verbose = 2,
                   expand = FALSE,
                   group = attr(model_mat,"assign"))
)

plot(cvfit)
predict(cvfit, type = "nonzero", s="lambda.min")
cvfit$cvm[which(cvfit$lambda.min==cvfit$lambda)]







plot(fit)
fmla <- as.formula(paste0("~0+",paste(colnames(X), collapse = "+"), "+ E +",paste(colnames(X),":E", collapse = "+") ))
Xmat <- model.matrix(fmla, data = data.frame(X,E))
head(Xmat)

pacman::p_load(doParallel)
doParallel::registerDoParallel(cores = 5)
getDoParWorkers()

complete.cases(X) %>% sum
fit_sail <- funshim(x = X, y = Y, e = E, df = 3, maxit = 1000, nlambda.gamma = 10, nlambda.beta = 10,
                    nlambda = 100,
                    lambda.factor = 0.001,
                    thresh = 1e-4, center=T, normalize=F, verbose = T)
coef(fit_sail)


fit <- cv.funshim(x = X, y = Y, e = E, df = 3, maxit = 1000, nlambda.gamma = 10, nlambda.beta = 10,
                  nlambda = 100,
                  lambda.factor = 0.001, nfolds = 5,
                  thresh = 1e-4, center=T, normalize=F, verbose = T)

saveRDS(fit, file = "data/cvfit_credit_data_df3_interaction_with_student.rds")

coef(fit, s = "lambda.1se")
coef(fit, s = "lambda.min")

plot(fit)
coef(fit)[nonzero(coef(fit)),,drop=F]
lambda_type <- "lambda.1se"
trop <- RSkittleBrewer::RSkittleBrewer("trop")

fit$funshim.fit$x



# MGCV --------------------------------------------------------------------

pacman::p_load(mgcv)

fit_gam <- gam.fit()


# Credit Data Main Effects ------------------------------------------------
fit <- readRDS(file = "~/git_repositories/sail/data/cvfit_credit_data_df3_interaction_with_student.rds")
lambda_type <- "lambda.1se"
trop <- RSkittleBrewer::RSkittleBrewer("trop")

class(fit)
class(fit) <- "cv.sail"

dev.off()
png("/home/sahir/Dropbox/jobs/hec/talk/credit_sail_main.png", width=14,height=8,units="in",res=150)
pdf("/home/sahir/Dropbox/jobs/hec/talk/credit_sail_main.pdf", width=14,height=8)
par(mfrow=c(2,5), tcl=-0.5, family="serif", omi=c(0.2,0.2,0,0))
i = "X1";j = "Income"
colnames(X)
par(mai=c(0.55,0.6,0.1,0.2))
plot(X[,j], fit$funshim.fit$design[,paste(i,seq_len(fit$funshim.fit$df), sep = "_")] %*%
       coef(fit, s = lambda_type)[paste(i,seq_len(fit$funshim.fit$df), sep = "_"),,drop=F],
     pch = 19,
     ylab = "Balance",
     xlab = TeX(sprintf("$%s$",j)),
     col = trop[1],
     bty="n",
     xaxt="n",
     # cex.lab = 1.6,
     cex.lab = 2,
     cex.axis = 2,
     cex = 1.5)#,
     # ylim = c(min.length.top, max.length.top))
axis(1, cex.axis = 2, at = c(10,50,100,150,190), labels = c(10,50,100,150,190))

# points(DT$x[,i], fit$design[,paste(i,seq_len(DT$df), sep = "_")] %*% true.coefs[,i,drop=F], pch = 19, col = trop[2])
# legend("bottomright", c("Truth","Estimated"), col = trop[2:1], pch = 19, cex = 1.5, bty = "n")

for(i in paste0("X",2:5)) {
  j <- switch(i,
              "X2" = "Limit", "X3" = "Rating", "X4" = "Cards", "X5" = "Age")
  plot(X[,j], fit$funshim.fit$design[,paste(i,seq_len(fit$funshim.fit$df), sep = "_")] %*%
         coef(fit, s = lambda_type)[paste(i,seq_len(fit$funshim.fit$df), sep = "_"),,drop=F],
       pch = 19,
       ylab = "",
       xlab = TeX(sprintf("$%s$",j)),
       col = trop[1],
       bty="n",
       yaxt="n",
       xaxt="n",
       # cex.lab = 1.6,
       cex.lab = 2,
       cex.axis = 2,
       cex = 1.5)#,
       # ylim = range(fit$funshim.fit$design[,paste(i,seq_len(fit$funshim.fit$df), sep = "_")] %*%
                      # coef(fit, s = lambda_type)[paste(i,seq_len(fit$funshim.fit$df), sep = "_"),,drop=F]))
  # points(DT$x[,i], fit$design[,paste(i,seq_len(DT$df), sep = "_")] %*% true.coefs[,i,drop=F], pch = 19, col = trop[2])
  axis(1, labels = T, cex.axis = 2)
  axis(2, labels = T, cex.axis = 2)
}


i = "X6";j = "Education"
colnames(X)
par(mai=c(0.55,0.6,0.1,0.2))
plot(X[,j], fit$funshim.fit$design[,paste(i,seq_len(fit$funshim.fit$df), sep = "_")] %*%
       coef(fit, s = lambda_type)[paste(i,seq_len(fit$funshim.fit$df), sep = "_"),,drop=F],
     pch = 19,
     ylab = "Balance",
     xlab = "Years of Education",
     col = trop[1],
     bty="n",
     xaxt="n",
     cex.lab = 2,
     cex.axis = 2,
     cex = 1.5)#,
# ylim = c(min.length.top, max.length.top))
axis(1, labels = T, cex.axis = 2)
# points(DT$x[,i], fit$design[,paste(i,seq_len(DT$df), sep = "_")] %*% true.coefs[,i,drop=F], pch = 19, col = trop[2])
# legend("bottomright", c("Truth","Estimated"), col = trop[2:1], pch = 19, cex = 1.5, bty = "n")


# for(i in paste0("X",7:8)) {
  # j <- switch(i,
              # "X7" = "Married", "X8" = "Ethnicity")
  j = "Married";i="X7"
  plot(X[,j], fit$funshim.fit$design[,paste(i,seq_len(fit$funshim.fit$df), sep = "_")] %*%
         coef(fit, s = lambda_type)[paste(i,seq_len(fit$funshim.fit$df), sep = "_"),,drop=F],
       pch = 19,
       ylab = "",
       xlab = TeX(sprintf("$%s$",j)),
       col = trop[1],
       bty="n",
       yaxt="n",
       xaxt="n",
       cex.lab = 2,
       cex.axis = 2,
       cex = 1.5)#,
  # ylim = c(min.length.top, max.length.top))
  # points(DT$x[,i], fit$design[,paste(i,seq_len(DT$df), sep = "_")] %*% true.coefs[,i,drop=F], pch = 19, col = trop[2])
  axis(1, labels = c("No","Yes"), cex.axis = 2, at = c(0,1))
  axis(2, labels = T, cex.axis = 2)
# }

  j = "Ethnicity";i="X8"
  plot(X[,j], fit$funshim.fit$design[,paste(i,seq_len(fit$funshim.fit$df), sep = "_")] %*%
         coef(fit, s = lambda_type)[paste(i,seq_len(fit$funshim.fit$df), sep = "_"),,drop=F],
       pch = 19,
       ylab = "",
       xlab = TeX(sprintf("$%s$",j)),
       col = trop[1],
       bty="n",
       yaxt="n",
       xaxt="n",
       cex.lab = 2,
       cex.axis = 2,
       cex = 1.5)#,
  # ylim = c(min.length.top, max.length.top))
  # points(DT$x[,i], fit$design[,paste(i,seq_len(DT$df), sep = "_")] %*% true.coefs[,i,drop=F], pch = 19, col = trop[2])
  axis(1, labels = c("Caucasian", "Asian","African\nAmerican"), cex.axis = 2, at = c(0,1,2))
  axis(2, labels = T, cex.axis = 2)



i = "X_E";j = "Student"
colnames(X)
# par(mai=c(0.55,0.6,0.1,0.2))
plot(E, fit$funshim.fit$design[,"X_E"] %*%
       coef(fit, s = lambda_type)["X_E",,drop=F],
     pch = 19,
     ylab = "",
     xlab = TeX(sprintf("$%s$",j)),
     col = trop[1],
     bty="n",
     xaxt="n",
     cex.lab = 2,
     cex.axis = 2,
     cex = 1.5, ylim = c(0, 50))
axis(1, labels = c("No", "Yes"), cex.axis = 2, at = c(0,1))
dev.off()
# plot.new()
# legend("center", c("Student","Not a Student"), col = trop[2:1], pch = 19, cex = 2.5, bty = "n")



# Credit Data Interaction Effects -----------------------------------------


# png("/home/sahir/Dropbox/jobs/hec/talk/credit_sail_interactions.png", width=11,height=8,units="in",res=150)
pdf("/home/sahir/Dropbox/jobs/hec/talk/credit_sail_interactions.pdf", width=11,height=8)

par(mfrow=c(2,3), tcl=-0.5, family="serif", omi=c(0.2,0.2,0,0))
i = "X1";j = "Income"
colnames(X)
par(mai=c(0.55,0.6,0.1,0.2))

lin_pred <- fit$funshim.fit$design[,paste(i,seq_len(fit$funshim.fit$df), sep = "_")] %*%
  coef(fit, s = lambda_type)[paste(i,seq_len(fit$funshim.fit$df), sep = "_"),,drop=F] +
  fit$funshim.fit$design[,"X_E",drop=F] %*%
  coef(fit, s = lambda_type)["X_E",,drop=F] +
  fit$funshim.fit$design[,paste0(paste(i,seq_len(fit$funshim.fit$df), sep = "_"),":X_E")] %*%
  coef(fit, s = lambda_type)[paste0(paste(i,seq_len(fit$funshim.fit$df), sep = "_"),":X_E"),,drop=F]

unexposed_index <- which(fit$funshim.fit$design[,"X_E"]==0)
exposed_index <- which(fit$funshim.fit$design[,"X_E"]==1)

e0 <- lin_pred[unexposed_index,]
e1 <- lin_pred[exposed_index,]
plot(X[,j], lin_pred,
     pch = 19,
     ylab = "Balance",
     xlab = TeX(sprintf("$%s$",j)),
     col = trop[1],
     bty="n",
     xaxt="n",
     type = "n",
     cex.lab = 2,
     cex.axis = 2,
     cex = 2)#,
# ylim = c(min.length.top, max.length.top))
axis(1, labels = T, cex.axis = 2)
points(X[exposed_index,j], e1, pch = 19, col = trop[2], cex = 1.5)
points(X[unexposed_index,j], e0, pch = 19, col = trop[1], cex = 1.5)
# legend("bottomleft", c("Student","Not a Student"), col = trop[2:1], pch = 19, cex = 1.5, bty = "n")


for(i in paste0("X",2:5)) {
  j <- switch(i,
              "X2" = "Limit", "X3" = "Rating", "X4" = "Cards", "X5" = "Age")

  lin_pred <- fit$funshim.fit$design[,paste(i,seq_len(fit$funshim.fit$df), sep = "_")] %*%
    coef(fit, s = lambda_type)[paste(i,seq_len(fit$funshim.fit$df), sep = "_"),,drop=F] +
    fit$funshim.fit$design[,"X_E",drop=F] %*%
    coef(fit, s = lambda_type)["X_E",,drop=F] +
    fit$funshim.fit$design[,paste0(paste(i,seq_len(fit$funshim.fit$df), sep = "_"),":X_E")] %*%
    coef(fit, s = lambda_type)[paste0(paste(i,seq_len(fit$funshim.fit$df), sep = "_"),":X_E"),,drop=F]

  unexposed_index <- which(fit$funshim.fit$design[,"X_E"]==0)
  exposed_index <- which(fit$funshim.fit$design[,"X_E"]==1)

  e0 <- lin_pred[unexposed_index,]
  e1 <- lin_pred[exposed_index,]
  plot(X[,j], lin_pred,
       pch = 19,
       ylab = if(i=="X4") "Balance" else "",
       xlab = TeX(sprintf("$%s$",j)),
       col = trop[1],
       bty="n",
       xaxt="n",
       type = "n",
       cex.lab = 2,
       cex.axis = 2,
       cex = 2,
       ylim = c(min(lin_pred), max(lin_pred)*1.08))
  axis(1, labels = T, cex.axis = 2)
  points(X[exposed_index,j], e1, pch = 19, col = trop[2], cex = 1.5)
  points(X[unexposed_index,j], e0, pch = 19, col = trop[1], cex = 1.5)
}

plot.new()
legend("center", c("Student","Not a Student"), col = trop[2:1], pch = 19, cex = 2.5, bty = "n")
dev.off()





# Credit Interaction Effect Without Legend --------------------------------

png("/home/sahir/Dropbox/jobs/hec/talk/credit_sail_interactions_no_legend.png", width=11,height=8,units="in",res=150)

pdf("/home/sahir/Dropbox/jobs/hec/talk/credit_sail_interactions_no_legend.pdf", width=11,height=8)
par(mfrow=c(2,3), tcl=-0.5, family="serif", omi=c(0.2,0.2,0,0))
i = "X1";j = "Income"
colnames(X)
par(mai=c(0.55,0.6,0.1,0.2))

lin_pred <- fit$funshim.fit$design[,paste(i,seq_len(fit$funshim.fit$df), sep = "_")] %*%
  coef(fit, s = lambda_type)[paste(i,seq_len(fit$funshim.fit$df), sep = "_"),,drop=F] +
  fit$funshim.fit$design[,"X_E",drop=F] %*%
  coef(fit, s = lambda_type)["X_E",,drop=F] +
  fit$funshim.fit$design[,paste0(paste(i,seq_len(fit$funshim.fit$df), sep = "_"),":X_E")] %*%
  coef(fit, s = lambda_type)[paste0(paste(i,seq_len(fit$funshim.fit$df), sep = "_"),":X_E"),,drop=F]

unexposed_index <- which(fit$funshim.fit$design[,"X_E"]==0)
exposed_index <- which(fit$funshim.fit$design[,"X_E"]==1)

e0 <- lin_pred[unexposed_index,]
e1 <- lin_pred[exposed_index,]
plot(X[,j], lin_pred,
     pch = 19,
     ylab = "Balance",
     xlab = TeX(sprintf("$%s$",j)),
     col = trop[1],
     bty="n",
     xaxt="n",
     type = "n",
     cex.lab = 2,
     cex.axis = 2,
     cex = 2)#,
# ylim = c(min.length.top, max.length.top))
axis(1, labels = T, cex.axis = 2)
points(X[exposed_index,j], e1, pch = 19, col = trop[2], cex = 1.5)
points(X[unexposed_index,j], e0, pch = 19, col = trop[1], cex = 1.5)
# legend("bottomleft", c("Student","Not a Student"), col = trop[2:1], pch = 19, cex = 1.5, bty = "n")


for(i in paste0("X",2:5)) {
  j <- switch(i,
              "X2" = "Limit", "X3" = "Rating", "X4" = "Cards", "X5" = "Age")

  lin_pred <- fit$funshim.fit$design[,paste(i,seq_len(fit$funshim.fit$df), sep = "_")] %*%
    coef(fit, s = lambda_type)[paste(i,seq_len(fit$funshim.fit$df), sep = "_"),,drop=F] +
    fit$funshim.fit$design[,"X_E",drop=F] %*%
    coef(fit, s = lambda_type)["X_E",,drop=F] +
    fit$funshim.fit$design[,paste0(paste(i,seq_len(fit$funshim.fit$df), sep = "_"),":X_E")] %*%
    coef(fit, s = lambda_type)[paste0(paste(i,seq_len(fit$funshim.fit$df), sep = "_"),":X_E"),,drop=F]

  unexposed_index <- which(fit$funshim.fit$design[,"X_E"]==0)
  exposed_index <- which(fit$funshim.fit$design[,"X_E"]==1)

  e0 <- lin_pred[unexposed_index,]
  e1 <- lin_pred[exposed_index,]
  plot(X[,j], lin_pred,
       pch = 19,
       ylab = if(i=="X4") "Balance" else "",
       xlab = TeX(sprintf("$%s$",j)),
       col = trop[1],
       bty="n",
       xaxt="n",
       type = "n",
       cex.lab = 2,
       cex.axis = 2,
       cex = 2,
       ylim = c(min(lin_pred), max(lin_pred)*1.08))
  axis(1, labels = T, cex.axis = 2)
  points(X[exposed_index,j], e1, pch = 19, col = trop[2], cex = 1.5)
  points(X[unexposed_index,j], e0, pch = 19, col = trop[1], cex = 1.5)
}
plot.new()
text(0.4,0.4, labels = c("Which color\n represents\n a Student?"), cex = 2.5)
dev.off()




