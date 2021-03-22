provider "aws" {
  region = "us-east-2"
}

terraform {
  # Only the 'key' parameter remains in the Terraform code, since you still need to set a different 'key' value for each module.
  # All the other repeated 'backend' arguments, such as 'bucket' and 'region', into a separate file called backend.hcl.
  backend "s3" {
    # Terraform will create the key path automatically.
    # Variables aren't allowed in a backend configuration.
    key = "global/iam/terraform.tfstate"
  }
}

data "aws_iam_policy_document" "cloudwatch_read_only" {
  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:Describe",
      "cloudwatch:Get*",
      "cloudwatch:List*"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "cloudwatch_full_access" {
  statement {
    effect = "Allow"
    actions = ["cloudwatch:*"]
    resources = ["*"]
  }
}

# The 'for_each' expressions allows you loop over lists, sets, and maps to create either:
# (a) multiple copies of an entire resources, or
# (b) multiple copies of an inline block within a resource.
resource "aws_iam_user" "example" {
  # 'lists' are not supported when using 'for_each' on a resource.
  # This is why it's needed to convert to set first.
  for_each = toset(var.user_names)
  name = each.value
}

resource "aws_iam_policy" "cloudwatch_read_only" {
  name = "cloudwatch-read-only"
  policy = data.aws_iam_policy_document.cloudwatch_read_only.json
}

resource "aws_iam_policy" "cloudwatch_full_access" {
  name = "cloudwatch-full-access"
  policy = data.aws_iam_policy_document.cloudwatch_full_access.json
}

resource "aws_iam_user_policy_attachment" "neo_cloudwatch_full_access" {
  count = var.give_neo_cloudwatch_full_access ? 1 : 0

  policy_arn = aws_iam_policy.cloudwatch_full_access.arn
  user = aws_iam_user.example["neo"].name
}

resource "aws_iam_user_policy_attachment" "neo_cloudwatch_read_only" {
  count = var.give_neo_cloudwatch_full_access ? 0 : 1

  policy_arn = aws_iam_policy.cloudwatch_read_only.arn
  user = aws_iam_user.example["neo"].name
}