provider "aws" {
  region = "us-east-1"
}

provider "github" {
  individual   = false
  token        = "${var.github_token}"
  organization = "${var.github_user}"
}

locals {
  webhook_secret = "${var.github_token}"
  github_repo    = "${var.github_repo}"
  github_branch  = "master"
  aws_iam_role   = "${var.code_pipeline_role}"
}


resource "aws_s3_bucket" "codepipeline-bucket" {
  bucket = "codepipeline-bucketok"
  acl    = "private"
}

resource "aws_codepipeline" "codepipeline" {
  name     = "tf-test-pipeline-auto"
  role_arn = "${local.aws_iam_role}"

  artifact_store {
    location = "${aws_s3_bucket.codepipeline-bucket.bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = "${var.github_user}"
        Repo       = "${local.github_repo}"
        Branch     = "${local.github_branch}"
        OAuthToken = "${local.webhook_secret}"
      }
    }
  }

  stage {
    name = "Test"

    action {
      name             = "Test"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["test_output"]
      version          = "1"

      configuration = {
        ProjectName          = "test-tr-project"
        EnvironmentVariables = "[{\"name\":\"STAGE\",\"value\":\"TEST\",\"type\":\"PLAINTEXT\"}]"
      }
    }
  }

  stage {
    name = "Approve"

    action {
      name     = "Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "Deploy"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName          = "test-tr-project"
        EnvironmentVariables = "[{\"name\":\"STAGE\",\"value\":\"DEPLOY\",\"type\":\"PLAINTEXT\"}]"
      }

    }
  }
}


resource "aws_codepipeline_webhook" "bar" {
  name            = "test-webhook-github-bar"
  authentication  = "GITHUB_HMAC"
  target_action   = "Source"
  target_pipeline = "${aws_codepipeline.codepipeline.name}"

  authentication_configuration {
    secret_token = "${local.webhook_secret}"
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }
}

# Wire the CodePipeline webhook into a GitHub repository.
resource "github_repository_webhook" "githubchik" {

  repository = "${local.github_repo}"

  configuration {
    url          = "${aws_codepipeline_webhook.bar.url}"
    content_type = "json"
    insecure_ssl = true

    secret = "${local.webhook_secret}"

  }
  events = ["push"]
}