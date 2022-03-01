data "aws_subnet_ids" "private" {
  vpc_id = var.vpc_id
  tags = {
    "kubernetes.io/role/internal-elb": "1"
  }
}

resource aws_db_subnet_group "private" {
  name = "private"
  subnet_ids = data.aws_subnet_ids.private.ids
}

locals {
  rds_port = 3306
}

resource "aws_security_group" "db" {
  name   = "service-${var.cluster_name}-rds-access"
  vpc_id = var.vpc_id

  ingress {
    description = "mysql from VPC"
    from_port   = local.rds_port
    to_port     = local.rds_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource aws_db_instance "rds" {
  engine               = "mysql"
  name                 = "kubeflow"
  instance_class       = "db.t3.micro"
  allocated_storage    = "10"
  username             = "admin"
  password             = "kubeFl0w"
  port = local.rds_port
  db_subnet_group_name = aws_db_subnet_group.private.name
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.db.id]
}

resource "aws_secretsmanager_secret" "rds-secret" {
  name = "kf-rds-secret"
  recovery_window_in_days = 0

}

resource "aws_secretsmanager_secret_version" "rds_version" {
  secret_id = aws_secretsmanager_secret.rds-secret.id


  secret_string=jsonencode({
      "username": aws_db_instance.rds.username,
      "password": aws_db_instance.rds.password,
      "database": aws_db_instance.rds.name,
      "host":aws_db_instance.rds.address,
      "port":tostring(aws_db_instance.rds.port)
    }
  )
}