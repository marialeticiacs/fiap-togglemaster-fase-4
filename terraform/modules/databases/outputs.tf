output "rds_endpoints" {
  description = "Endpoints de conexão dos bancos RDS"
  value = {
    for k, v in aws_db_instance.postgresql : k => v.endpoint
  }
}

output "sqs_url" {
  description = "URL da fila SQS para Analytics"
  value       = aws_sqs_queue.main_queue.url
}

output "redis_endpoint" {
  description = "Endpoint do Redis"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}