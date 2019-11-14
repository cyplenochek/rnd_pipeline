# plexus_pipeline

Prerequisites:

 1) - IAM role for codebuild project has to be created before running this project
    - IAM role for codepipilene has to be created before running this project
 
 2)For security reasons please create local_secret.tfvars file in the same directory as the current README.md
 Please specify the following sensitive data inside your local_secret.tfvars:
         github_repo = "<repo that  will be automatically triggering your cicd process>"
         github_user = "<your github user>"
         github_token = "your secret token"
         code_build_role = "< predefined  IAM role for codebuild project>"
         code_pipeline_role = "< predefined IAM role for codepipilene >"

 3) Add your local_secret.tfvars into .gitignore file to prevent accidental commit of sensitive data.
 
 4) Run terraform init -var-file="local_secret.tfvars"
 
