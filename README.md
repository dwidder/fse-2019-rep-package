# Replication Package

This replication package accompanies `A Conceptual Replication of TravisCI Pain Points`, accepted to FSE 2019.

## Observations and Interview Questions
To allow other researchers to confirm observations from our literature review which were out of scope for our study, the full list of observations is provided in the `pdf` document included here. We also provide our interview protocol used for the 12 semistructured interviews in the same document, should future researchers wish to use a similar protocol. 

## Model and Data
To allow other researchers to critique our model or reanalyize our dataset, we provide and document it here. 

Basic columns:

- slug: the owner's login and the project name in the format: owner_login/project_name
- travis_id: the id of the project in the Travis API
- ght_id: the id of the project 

Description of columns used as controlled variables:

- project_age: age of project in days
- last_build_duration: duration of last build in seconds
- commits: the number of commits
- contribs: the number of contributors to the project
- job_count: the number of jobs in the most recent Travis build instance
- PRs: the number of pull requests made to the project

Description of columns used as indepdent variables:

- number_of_test_files: the number of test files found in the project 
- has_long_builds: binary variable, recording whether this project has builds reaching the top 20% of build times             
- new_user: binary variable, recording whether this project has 30 days between their first and last build or fewer than 30 builds total
- lang_supported: binary variable, recording whether this project's primary langauge has offical support as per https://docs.travis-ci.com/user/languages/
- commercial: binary variable, recording whether this project has commerical contributers using email classification method first defveloped in https://dl.acm.org/citation.cfm?id=3236062                  
- influenced: binary variable, recording whether this project has members who had contributed to a project which had left Travis in the past                  
- docker: binary variable, recording whether this project had a Docker file on the day before this project's last build
- has_rebuilds: binary variable, recording whether this project has rebuilds of the same commit                
- low_activity: binary variable, recording whether this project has any months without commits in the 6 months before the projects last build                

Description of dependent variables:
- left_travis: this project left Travis, and is alive. 
- target_ci$error (from commit_status_context.csv): 1 if no new CI detected, 0 if new CI detected.
