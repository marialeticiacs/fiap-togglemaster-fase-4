output "rds_endpoints" {
  value = aws_db_instance.postgresql[*].endpoint
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "sqs_url" {
  value = aws_sqs_queue.main_queue.id
}