terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = ">= 4"
  }

  cloud {
    organization = "Dexco"
    workspaces {
      name = "template-beanstalk-module"
    }
  }
}

provider "aws" {
  region = var.region
}


module "vpc" {
  source   = "app.terraform.io/Dexco/vpc/aws"
  version  = "1.0.0"
  vpc_name = var.vpc_name
  env      = var.env
}

module "acm" {
  source      = "app.terraform.io/Dexco/acm/aws"
  version     = "1.0.0"
  certificate = var.certificate
}

module "subnet" {
  source          = "app.terraform.io/Dexco/subnet/aws"
  version         = "1.0.0"
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  vpc_id          = module.vpc.vpc_id
}

module "route53" {
  source        = "app.terraform.io/Dexco/route53/aws"
  version       = "1.0.0"
  app_name      = var.app_name
  dns_name      = var.dns_name
  domain        = var.domain
  alias_name    = module.beanstalk.dns_name
  alias_zone_id = module.beanstalk.zone_id
  tier          = var.tier
}

module "sg_lb" {
  source                = "app.terraform.io/Dexco/sg/aws"
  version               = "1.0.0"
  app_name              = var.app_name
  resource              = var.lb
  ingress_ports         = var.ingress_ports_lb
  egress_ports          = var.egress_ports_lb
  ingress_allowed_cidrs = var.ingress_allowed_cidrs_lb
  egress_allowed_cidrs  = var.egress_allowed_cidrs_lb
  env                   = var.env
  project               = var.project
  team                  = var.team
  region                = var.region
  vpc_id                = module.vpc.vpc_id
}

module "sg_ec2" {
  source                = "app.terraform.io/Dexco/sg/aws"
  version               = "1.0.0"
  app_name              = var.app_name
  resource              = var.app
  ingress_ports         = var.ingress_ports_app
  egress_ports          = var.egress_ports_app
  ingress_allowed_cidrs = var.ingress_allowed_cidrs_app
  egress_allowed_cidrs  = var.egress_allowed_cidrs_app
  env                   = var.env
  project               = var.project
  team                  = var.team
  region                = var.region
  vpc_id                = module.vpc.vpc_id
}

module "s3" {
  source   = "app.terraform.io/Dexco/s3/aws"
  app_name = var.app_name
  env      = var.env
  team     = var.team
  project  = var.project
}

module "beanstalk" {
  source                 = "app.terraform.io/Dexco/beanstalk/aws"
  version                = "1.0.1"
  app_name               = var.app_name
  env                    = var.env
  team                   = var.team
  project                = var.project
  vpc_id                 = module.vpc.vpc_id
  private_subnets_ids    = module.subnet.private_subnets_ids
  public_subnets_ids     = module.subnet.public_subnets_ids
  security_group_ec2_id  = module.sg_ec2.security_group_id
  security_group_lb_id   = module.sg_lb.security_group_id
  certificate_arn        = module.acm.certificate_arn
  healthcheck_url        = var.healthcheck_url
  tier                   = var.tier
  eb_solution_stack_name = var.eb_solution_stack_name
  private_access         = false
}