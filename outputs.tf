output "function_url" {
  value = aws_lambda_function_url.visitor.function_url
}
output "site_url" {
  value = "https://${aws_cloudfront_distribution.site.domain_name}"
}

output "bucket_name" {
  value = aws_s3_bucket.site.id
}