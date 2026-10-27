variable "region" {
  type    = string
  default = "us-west-2"
}

variable "project" {
  type    = string
  default = "resume-tf"
}

# Part 2 will replace this with the CloudFront domain.
variable "allowed_origin" {
  type    = string
  default = "*"
}