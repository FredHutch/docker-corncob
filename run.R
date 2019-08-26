# Get the arguments passed in by the user

library(tidyverse)
library(corncob)
library(parallel)
args = commandArgs(trailingOnly=TRUE)

numCores = 4

if (length(args) != 3) {
  stop("Arguments: <READCOUNTS CSV> <METADATA CSV> <OUTPUT CSV>", call.=FALSE)
}

##  READCOUNTS CSV should have columns `sample` (first col) and `total` (last column).
##  METADATA CSV should have columns `name` (which matches up with `sample` from the recounts file),
##         and additional columns with covariates

##  corncob analysis (coefficients and p-values) are written to OUTPUT CSV on completion

print(sprintf("Reading in %s", args[2]))
metadata <- vroom::vroom(args[2], delim=",")
covariate_list <- colnames(metadata)
for(to_exclude in c("name", "Participant")){
  covariate_list <- covariate_list[which(covariate_list != to_exclude)]
}
print(covariate_list)

stopifnot("covariate" %in% colnames(metadata) == FALSE)

print(sprintf("Reading in %s", args[1]))
counts <- vroom::vroom(args[1], delim=",")
total_counts <- counts[,c("sample", "total")]
print("Merging total counts with metadata")
total_and_meta <- metadata %>% 
  right_join(total_counts, by = c("name" = "sample"))

#### Run rest using loop
print(sprintf("Starting to process %s columns", dim(counts)[2]))
corn_tib <- do.call(rbind, lapply(
  covariate_list,
  function(covariate){
  print(sprintf("Processing covariate %s", covariate))

  return(
    do.call(rbind, mclapply(
    c(2:(dim(counts)[2] - 1)),
    function(i){
      try_bbdml <- try(counts[,c(1, i)] %>%
                       rename(W = 2) %>%
                       right_join(total_and_meta, by = c("sample" = "name")) %>%
                       rename(covariate = covariate) %>%
                       select(sample, W, covariate, total) %>%
                       drop_na %>%
                       corncob::bbdml(formula = cbind(W, total - W) ~ covariate,
                                        phi.formula = ~ 1,
                                        data = .))
      
      if (class(try_bbdml) == "bbdml") {
        stopifnot(summary(try_bbdml)$coef %>% nrow == 3)
        return(summary(try_bbdml)$coef %>%
          as_tibble %>%
          mutate("parameter" = summary(try_bbdml)$coef %>% row.names) %>%
          rename("estimate" = Estimate,
                 "std_error" = `Std. Error`,
                 "p_value" = `Pr(>|t|)`) %>%
          select(-`t value`) %>%
          gather(key = type, ...=estimate:p_value) %>%
          mutate("cag" = names(counts)[i]) %>%
          add_column(., "covariate" = covariate))
      } else {
        return(
          tibble("parameter" = "all",
                 "type" = "failed", 
                 "value" = NA, 
                 "cag" = names(counts)[i], 
                 "covariate" = covariate)
        )
      }      
    },
    mc.cores = numCores
  )))}))

print(sprintf("Writing out %s rows to %s", nrow(corn_tib, args[3])))
write_csv(corn_tib, args[3])