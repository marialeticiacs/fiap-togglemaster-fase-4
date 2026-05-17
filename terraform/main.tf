# terraform/main.tf (O Maestro)

module "networking" {
  source       = "./modules/networking"
  project_name = "togglemaster"
  region       = "us-east-2"
  vpc_cidr     = "10.0.0.0/16"
}

module "databases" {
  source             = "./modules/databases"
  project_name       = "togglemaster"
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids

  depends_on = [module.networking]
}

module "cluster" {
  source             = "./modules/cluster"
  project_name       = "togglemaster"
  private_subnet_ids = module.networking.private_subnet_ids
  vpc_id             = module.networking.vpc_id
  region             = "us-east-2"

  depends_on = [module.networking]
}

module "ecr" {
  source       = "./modules/ecr"
  project_name = "togglemaster"
}

module "observability" {
  source       = "./modules/observability"
  cluster_name = module.cluster.cluster_name

  depends_on = [module.cluster]
}