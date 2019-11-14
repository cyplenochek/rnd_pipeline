resource "aws_s3_bucket" "codebuild_artifacts" {
  bucket = "codebuild-artifactik"
  acl    = "private"
}


resource "aws_codebuild_project" "test-tr" {
  name          = "test-tr-project"
  description   = "test_codebuild_project"
  build_timeout = "5"
  service_role  = "${var.code_build_role}"

  artifacts {
    type                   = "CODEPIPELINE"
    override_artifact_name = true
  }


  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"


  }

  logs_config {

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.codebuild_artifacts.id}/build-log"
    }
  }

  source {
    type            = "CODEPIPELINE"
    git_clone_depth = 1
  }


  tags = {
    Environment = "Test-tr"
  }
}