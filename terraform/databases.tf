resource "aws_dynamodb_table" "analytics" {
  name         = "ToggleMasterAnalytics"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "eventId"
  
  attribute { 
    name = "eventId"
    type = "S" 
  }
}

resource "aws_sqs_queue" "analytics_queue" { 
  name = "analytics-queue" 
}

resource "aws_security_group" "db_sg" {
  name   = "togglemaster-db-sg"
  vpc_id = module.vpc.vpc_id
  
  ingress { 
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block] 
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "togglemaster-db-subnet-group"
  subnet_ids = module.vpc.private_subnets
}

locals { 
  dbs = {
    "auth-db"      = "auth_db"
    "flag-db"      = "flag_db"
    "targeting-db" = "targeting_db"
  } 
}

resource "aws_db_instance" "postgres" {
  for_each               = local.dbs
  identifier             = each.key
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = each.value
  username               = "dbadmin"
  password               = "SenhaForte123!" 
  skip_final_snapshot    = true
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}

resource "aws_elasticache_subnet_group" "redis_subnet" {
  name       = "togglemaster-redis-subnet"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "togglemaster-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.1"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet.name
  security_group_ids   = [aws_security_group.db_sg.id]
}