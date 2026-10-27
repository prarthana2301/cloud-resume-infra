resource "aws_dynamodb_table" "visitor" {
  name         = "${var.project}-visitor-count"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table_item" "seed" {
  table_name = aws_dynamodb_table.visitor.name
  hash_key   = aws_dynamodb_table.visitor.hash_key

  item = jsonencode({
    id    = { S = "visits" }
    count = { N = "0" }
  })

  # Don't reset the live counter on later applies.
  lifecycle {
    ignore_changes = [item]
  }
}