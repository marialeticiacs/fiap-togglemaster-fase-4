# Security Group para os Bancos de Dados
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Permitir acesso aos bancos de dados"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Acesso apenas interno da VPC
  }

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Subnet Group para o RDS
resource "aws_db_subnet_group" "rds_sg" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids
}

# Criando os 3 Bancos RDS PostgreSQL (auth, flag, targeting/evaluation)
resource "aws_db_instance" "postgresql" {
  count                  = 3
  identifier             = "${var.project_name}-db-${count.index}"
  engine                 = "postgres"
  engine_version         = "13"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "togglemasterdb${count.index}"
  username               = "postgres"
  password               = "password123" # Em prod, usar AWS Secrets Manager!
  db_subnet_group_name   = aws_db_subnet_group.rds_sg.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true
}

# ElastiCache Redis
resource "aws_elasticache_subnet_group" "redis_sg" {
  name       = "${var.project_name}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.project_name}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.redis_sg.name
  security_group_ids   = [aws_security_group.db_sg.id]
}

# DynamoDB
resource "aws_dynamodb_table" "analytics" {
  name           = "${var.project_name}-analytics"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# SQS Queue
resource "aws_sqs_queue" "main_queue" {
  name = "${var.project_name}-queue"
}