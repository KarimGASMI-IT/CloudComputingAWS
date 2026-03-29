resource "aws_cloudwatch_dashboard" "tp15" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        "type"   = "metric",
        "x"      = 0,
        "y"      = 0,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "title"  = "ALB RequestCount",
          "region" = var.aws_region,
          "view"   = "timeSeries",
          "metrics" = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              data.aws_lb.tp14.arn_suffix
            ]
          ],
          "stat" = "Sum",
          "period" = 60
        }
      },
      {
        "type"   = "metric",
        "x"      = 12,
        "y"      = 0,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "title"  = "ALB HealthyHostCount",
          "region" = var.aws_region,
          "view"   = "timeSeries",
          "metrics" = [
            [
              "AWS/ApplicationELB",
              "HealthyHostCount",
              "TargetGroup",
              data.aws_lb_target_group.tp14.arn_suffix,
              "LoadBalancer",
              data.aws_lb.tp14.arn_suffix
            ]
          ],
          "stat"   = "Average",
          "period" = 60
        }
      },
      {
        "type"   = "metric",
        "x"      = 0,
        "y"      = 6,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "title"  = "ECS RunningTaskCount",
          "region" = var.aws_region,
          "view"   = "timeSeries",
          "metrics" = [
            [
              "AWS/ECS",
              "RunningTaskCount",
              "ClusterName",
              var.tp14_ecs_cluster_name,
              "ServiceName",
              var.tp14_ecs_service_name
            ]
          ],
          "stat"   = "Average",
          "period" = 60
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  count = var.enable_incident_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Détecte au moins une target unhealthy derrière l'ALB"

  dimensions = {
    TargetGroup  = data.aws_lb_target_group.tp14.arn_suffix
    LoadBalancer = data.aws_lb.tp14.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_running_tasks_low" {
  count = var.enable_incident_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-ecs-running-tasks-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Détecte une baisse anormale du nombre de tasks ECS"

  dimensions = {
    ClusterName = var.tp14_ecs_cluster_name
    ServiceName = var.tp14_ecs_service_name
  }
}