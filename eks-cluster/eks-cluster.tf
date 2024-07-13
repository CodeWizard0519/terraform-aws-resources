#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#

resource "aws_iam_role" "eks-role" {
  name = "${var.cluster_name}-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "role-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-role.name
}

resource "aws_iam_role_policy_attachment" "role-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks-role.name
}

resource "aws_security_group" "eks-sg" {
  name        = "${var.cluster_name}-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.eks-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # ingress {
  #   description      = "onpen all TCP"
  #   from_port        = 0
  #   to_port          = 0
  #   protocol         = "-1"
  #   cidr_blocks      = ["0.0.0.0/0"]
  # }

  tags = {
    Name = "${var.cluster_name}-tag"
  }
}

resource "aws_security_group_rule" "eks-sgr" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all to communicate with the cluster API Server"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks-sg.id
  to_port           = 0
  type              = "ingress"
}

resource "aws_eks_cluster" "eks-cluster" {
  name     = "${var.cluster_name}"
  role_arn = aws_iam_role.eks-role.arn

  vpc_config {
    security_group_ids = [aws_security_group.eks-sg.id]
    subnet_ids         = aws_subnet.eks-subnet[*].id
  }

  depends_on = [
    aws_iam_role_policy_attachment.role-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.role-AmazonEKSVPCResourceController,
  ]
}