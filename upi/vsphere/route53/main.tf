provider "aws" {
  region = "eu-central-1"
}

data "aws_route53_zone" "base" {
  name = var.base_domain
}

resource "aws_route53_zone" "cluster" {
  name          = var.cluster_domain
  force_destroy = true

  tags = {
    "Name"     = var.cluster_domain
    "Platform" = "vSphere"
  }
}

resource "aws_route53_record" "name_server" {
  name    = var.cluster_domain
  type    = "NS"
  ttl     = "300"
  zone_id = data.aws_route53_zone.base.zone_id
  records = aws_route53_zone.cluster.name_servers
}

resource "aws_route53_record" "api-external" {
  type           = "A"
  ttl            = "60"
  zone_id        = aws_route53_zone.cluster.zone_id
  name           = "api.${var.cluster_domain}"
  set_identifier = "api"
  records        = concat(var.bootstrap_ips, var.control_plane_ips)

  weighted_routing_policy {
    weight = 90
  }
}

resource "aws_route53_record" "api-internal" {
  type           = "A"
  ttl            = "60"
  zone_id        = aws_route53_zone.cluster.zone_id
  name           = "api-int.${var.cluster_domain}"
  set_identifier = "api"
  records        = concat(var.bootstrap_ips, var.control_plane_ips)

  weighted_routing_policy {
    weight = 90
  }
}

resource "aws_route53_record" "etcd_a_nodes" {
  count = var.control_plane_count

  type    = "A"
  ttl     = "60"
  zone_id = aws_route53_zone.cluster.zone_id
  name    = "etcd-${count.index}.${var.cluster_domain}"
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibility in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  records = [element(var.control_plane_ips, count.index)]
}

resource "aws_route53_record" "etcd_cluster" {
  type    = "SRV"
  ttl     = "60"
  zone_id = aws_route53_zone.cluster.zone_id
  name    = "_etcd-server-ssl._tcp"
  records = formatlist("0 10 2380 %s", aws_route53_record.etcd_a_nodes.*.fqdn)
}

resource "aws_route53_record" "ingress" {
  type    = "A"
  ttl     = "60"
  zone_id = aws_route53_zone.cluster.zone_id
  name    = "*.apps.${var.cluster_domain}"
  records = var.compute_ips
}

resource "aws_route53_record" "control_plane_nodes" {
  count = var.control_plane_count

  type    = "A"
  ttl     = "60"
  zone_id = aws_route53_zone.cluster.zone_id
  name    = "control-plane-${count.index}.${var.cluster_domain}"
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibility in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  records = [element(var.control_plane_ips, count.index)]
}

resource "aws_route53_record" "compute_nodes" {
  count = var.compute_count

  type    = "A"
  ttl     = "60"
  zone_id = aws_route53_zone.cluster.zone_id
  name    = "compute-${count.index}.${var.cluster_domain}"
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibility in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  records = [element(var.compute_ips, count.index)]
}

