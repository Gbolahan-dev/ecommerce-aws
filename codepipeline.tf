# codepipeline.tf

# 1. IAM Role for CodePipeline
#    This role gives CodePipeline permission to read from GitHub (source)
#    and start CodeBuild projects (build).
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-ecommerce-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      },
    ]
  })
}

# Attach a policy to the CodePipeline role
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline-ecommerce-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = [
          "arn:aws:s3:::*" # Broad permission for artifacts, can be scoped down
        ]
      },
      {
        Effect   = "Allow",
        Action   = [
          "codebuild:StartBuild"
        ],
        Resource = [aws_codebuild_project.main.arn]
      },
      {
        Effect   = "Allow",
        Action   = [
          "codestar-connections:UseConnection"
        ],
        Resource = [aws_codestarconnections_connection.github.arn]
      }
    ]
  })
}


# 2. IAM Role for CodeBuild
#    This role gives our build server permissions to do its job, like
#    logging to CloudWatch, talking to ECR, and running Terraform.
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-ecommerce-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}

# Attach AdministratorAccess to the CodeBuild role.
# For a real production system, we would create a custom policy with
# the exact least-privilege permissions needed (ECR push, ECS update, etc.).
# For this project, AdministratorAccess is much simpler and will prevent
# a lot of the IAM debugging we had to do on GCP.
resource "aws_iam_role_policy_attachment" "codebuild_admin_access" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


# 3. The CodeBuild Project
#    This defines our build environment.
resource "aws_codebuild_project" "main" {
  name          = "ecommerce-app-build"
  description   = "Builds the ecommerce-app Docker image"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = "20" # minutes

  artifacts {
    type = "CODEPIPELINE" # Artifacts will be managed by CodePipeline
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0" # A standard image with Docker, Git, AWS CLI
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true # Required to build Docker images
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml" # Tells CodeBuild which instruction file to use
  }

  tags = {
    Project = "ecommerce-aws"
  }
}

# 4. CodeStar Connection to GitHub (One-time setup)
#    This resource manages the connection to your GitHub account.
#    After applying, you will need to go to the AWS Console to finish the connection.
resource "aws_codestarconnections_connection" "github" {
  name          = "github-connection"
  provider_type = "GitHub"
}

# We will add the CodePipeline resource itself after this is applied.
# The connection to GitHub needs to be authorized manually first.
# codepipeline.tf

# ... (all the existing resources: roles, codebuild_project, connection) ...

# 5. The CodePipeline itself
#    This defines the stages of our CI/CD process.
resource "aws_codepipeline" "main" {
  name     = "ecommerce-app-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  # The artifact_store defines an S3 bucket where the pipeline will store
  # intermediate files (like the source code it downloads).
  # We can create a new bucket for this or use an existing one. Let's create one.
  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.codepipeline_artifacts.id
  }

  # --- PIPELINE STAGES ---

  # Stage 1: Source
  # This stage pulls the code from GitHub when a change is pushed.
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "Gbolahan-dev/ecommerce-aws" # <--- IMPORTANT: Update this to your repo name
        BranchName       = "main"
      }
    }
  }

  # Stage 2: Build
  # This stage runs our CodeBuild project using the source code from Stage 1.
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.main.name
      }
    }
  }

  # We will add Deploy stages here later.
  # Let's get the Source and Build stages working first.
}

# S3 Bucket for CodePipeline artifacts
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "codepipeline-artifacts-ecommerce-${var.aws_account_id}"
}
