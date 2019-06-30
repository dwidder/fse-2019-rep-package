library(readr)
library(dplyr)
library(tidyr)
library(car)
library(caret)
library(interplot)
library(pROC)
library(pscl)
library(stargazer)
library(xtable)

# Load data
data_to_model = read_csv("travis_leavers.csv")
data_to_model$left_travis = (data_to_model$abandoned_and_alive == 1)

target_ci = read_csv("cleaned_commit_status_context.csv")
nrow(target_ci)
names(target_ci)
table(target_ci$error) # error = 1 means abandoned all CIs


# How many projects gave up Travis CI
table(data_to_model$left_travis == 1)

## First, model abandoners (gave up CI completely)

# Set up quasi-experiment control and treatment groups
trt_a = subset(data_to_model[data_to_model$left_travis == TRUE,],
               slug %in% target_ci[target_ci$error == 1,]$slug)
nrow(trt_a)
ctrl_a = data_to_model[data_to_model$active == 1,]
nrow(ctrl_a)

# The groups are not too unbalanced, keep all controls
# abandoners_to_model = rbind(ctrl_a[sample(1:nrow(ctrl_a), 3*nrow(trt_a), replace=FALSE),], trt_a)
abandoners_to_model = rbind(ctrl_a, trt_a)
nrow(abandoners_to_model)
table(abandoners_to_model$left_travis)

# Sanity checks
summary(abandoners_to_model$project_age)
hist(abandoners_to_model$project_age)
summary(abandoners_to_model$last_build_duration)
hist(log(abandoners_to_model$last_build_duration))
summary(abandoners_to_model$commits)
hist(log(abandoners_to_model$commits))
summary(abandoners_to_model$contribs)
hist(log(abandoners_to_model$contribs))
summary(abandoners_to_model$job_count)
hist(abandoners_to_model$job_count)
hist(log(subset(abandoners_to_model, job_count<=30)$job_count))
summary(abandoners_to_model$PRs)
hist(log(abandoners_to_model$PRs+1))
table(abandoners_to_model$has_long_builds)
table(abandoners_to_model$new_user)
table(abandoners_to_model$lang_supported)
table(abandoners_to_model$commercial)
summary(abandoners_to_model$number_of_test_files)
table(abandoners_to_model$number_of_test_files > 500)
hist(log(subset(abandoners_to_model, job_count<=30 & number_of_test_files<=500)$number_of_test_files+1))
table(abandoners_to_model$has_rebuilds)
table(abandoners_to_model$low_activity)
table(abandoners_to_model$docker)
table(abandoners_to_model$influenced)

hist(abandoners_to_model$rebuild_fraction)
hist(log(abandoners_to_model[abandoners_to_model$rebuild_fraction<=0.12,]$rebuild_fraction+1))
table(abandoners_to_model$rebuild_fraction == 0)

# Model abandoners
logit_abandoners <- glm(left_travis  ~
                          log(project_age) +
                          log(last_build_duration) +
                          log(commits) +
                          log(contribs) +
                          log(job_count) +
                          log(PRs+1) +
                          log(number_of_test_files+1) +
                          has_long_builds + # Projects with more trivial builds and long builds likely to abandon
                          # new_user *
                          lang_supported + # Non supported langauges more likely to abandon
                          commercial + # Projects with significant commercial email involvement (3rd quartile) from one company(!) more likely to abandon
                          influenced + # If they connect to a previously abandoning project, they're more likely to abandon themselves.
                          new_user *
                          docker +
                          # has_rebuilds +
                          scale(log(rebuild_fraction+1)) +
                          low_activity,
                        data = subset(abandoners_to_model, 
                                      job_count <= 30 
                                      & number_of_test_files <= 500
                                      & rebuild_fraction <= 0.12),
                        family = "binomial"
)

summary(logit_abandoners)
pR2(logit_abandoners)
vif(logit_abandoners)
anova(logit_abandoners)
# Anova(logit_abandoners, type=2)
plot(logit_abandoners)


## Second, model switchers (changed tools)

# Control and treatment groups
trt_s = subset(data_to_model[data_to_model$left_travis == 1,],
               slug %in% target_ci[target_ci$error == 0,]$slug)
nrow(trt_s)
ctrl_s = data_to_model[data_to_model$active == 1,]
nrow(ctrl_s)

# This time the samples are unbalanced, downsample the controls
switchers_to_model = rbind(ctrl_s[sample(1:nrow(ctrl_s), 5*nrow(trt_s), replace=FALSE),], trt_s)
# switchers_to_model = rbind(ctrl_s, trt_s)
nrow(switchers_to_model)
table(switchers_to_model$abandoned_and_alive)

# Sanity checks
summary(switchers_to_model$project_age)
hist(switchers_to_model$project_age)
summary(switchers_to_model$last_build_duration)
hist(log(switchers_to_model$last_build_duration))
summary(switchers_to_model$commits)
hist(log(switchers_to_model$commits))
summary(switchers_to_model$contribs)
hist(log(switchers_to_model$contribs))
summary(switchers_to_model$job_count)
hist(switchers_to_model$job_count)
hist(log(subset(switchers_to_model, job_count<=30)$job_count))
summary(switchers_to_model$PRs)
hist(log(switchers_to_model$PRs+1))
table(switchers_to_model$has_long_builds)
table(switchers_to_model$new_user)
table(switchers_to_model$lang_supported)
table(switchers_to_model$commercial)
summary(switchers_to_model$number_of_test_files)
table(switchers_to_model$number_of_test_files > 500)
hist(log(subset(switchers_to_model, job_count<=30 & number_of_test_files<=500)$number_of_test_files+1))
table(switchers_to_model$has_rebuilds)
hist(log(switchers_to_model[switchers_to_model$rebuild_fraction <= 0.12,]$rebuild_fraction+1))
table(switchers_to_model$low_activity)
table(switchers_to_model$docker)
table(switchers_to_model$influenced)

# Model switchers
logit_switchers <- glm(left_travis  ~
                          log(project_age) +
                          log(last_build_duration) +
                          log(commits) +
                          log(contribs) +
                          log(job_count) +
                          log(PRs+1) +
                          log(number_of_test_files+1) +
                          has_long_builds + # Projects with more trivial builds and long builds likely to abandon
                          # new_user *
                          lang_supported + # Non supported langauges more likely to abandon
                          commercial + # Projects with significant commercial email involvement (3rd quartile) from one company(!) more likely to abandon
                          influenced + # If they connect to a previously abandoning project, they're more likely to abandon themselves.
                          new_user *
                          docker +
                          # has_rebuilds +
                          scale(log(rebuild_fraction+1)) +
                          low_activity,
                        data = subset(switchers_to_model, 
                                      job_count <= 30 
                                      & number_of_test_files <= 500
                                      & rebuild_fraction <= 0.12),
                        family = "binomial"
)

summary(logit_switchers)
pR2(logit_switchers)
vif(logit_switchers)
# Anova(logit_switchers, type=2)
anova(logit_switchers)
plot(logit_switchers)


## Export model summaries

source("helpers.r")
library(texreg)
library(xtable)

file="tex_model_all.csv"
modelNames=c("Switchers", "Abandoners")
caption="CI switchers and abandoners"

mList = list(m1=logit_switchers, m2=logit_abandoners)
makeTexRegCox(mList, file, modelNames, caption, digits=2)

print_Anova_glm(logit_switchers, "anova_model_all_1.csv")
print_Anova_glm(logit_abandoners, "anova_model_all_2.csv")

pR2(logit_switchers)
pR2(logit_abandoners)


