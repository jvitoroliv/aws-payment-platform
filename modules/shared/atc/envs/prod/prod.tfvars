records = {
  # Card Service API
  "cards-internal.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "cards-internal-prod-us-east-1.platform.example.com"
        set_identifier = "us-east-1-card-service-api-prod"
        weight         = 100
      }
      "us-west-2" = {
        record         = "cards-internal-prod-us-west-2.platform.example.com"
        set_identifier = "us-west-2-card-service-api-prod"
        weight         = 0
      }
    }
    zone = "platform.example.com"
  }

  # Payment Scheduler API - deprecated
  "payments-internal.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "payments-internal-prod-us-east-1.platform.example.com"
        set_identifier = "us-east-1-payment-scheduler-api-prod"
        weight         = 100
      }
      "us-west-2" = {
        record         = "payments-internal-prod-us-west-2.platform.example.com"
        set_identifier = "us-west-2-payment-scheduler-api-prod"
        weight         = 0
      }
    }
    zone = "platform.example.com"
  }

  # Payment Scheduler API internal
  "payments.internal.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "internal-payments-scheduler-prod-1575391250.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1-payment-scheduler-api-prod-internal"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "internal-payments-scheduler-prod-74083715.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2-payment-scheduler-api-prod-internal"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "platform.example.com"
  }

  # TAG API
  "api.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "ecs-fargate-api-prod-us-east-1.platform.example.com"
        set_identifier = "us-east-1-api-prod"
        weight         = 100
      }
      "us-west-2" = {
        record         = "ecs-fargate-api-prod-us-west-2.platform.example.com"
        set_identifier = "us-west-2-api-prod"
        weight         = 0
      }
    }
    zone = "platform.example.com"
  }

  "api-post-waf-lb.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "ecs-fgate-alb-api-prod-562339227.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 prod api post waf lb"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "ecs-fgate-alb-api-prod-807090515.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 prod api post waf lb"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "platform.example.com"
  }

  # TAG Common API
  "common-api.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "ecs-common-api-prod-us-east-1.platform.example.com"
        set_identifier = "common-api-prod-us-east-1"
        weight         = 100
      }
      "us-west-2" = {
        record         = "ecs-common-api-prod-us-west-2.platform.example.com"
        set_identifier = "common-api-prod-us-west-2"
        weight         = 0
      }
    }
    zone = "platform.example.com"
  }

  "common-api-post-waf-lb.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "ecs-common-api-prod-1347995736.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 prod common api post waf lb"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "ecs-common-api-prod-115569452.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 prod common api post waf lb"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "platform.example.com"
  }

  # TAG Internal API - deprecated
  "internal-api.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "ecs-fargate-api-internal-prod-us-east-1.platform.example.com"
        set_identifier = "us-east-1-internal-api-prod"
        weight         = 100
      }
      "us-west-2" = {
        record         = "ecs-fargate-api-internal-prod-us-west-2.platform.example.com"
        set_identifier = "us-west-2-internal-api-prod"
        weight         = 0
      }
    }
    zone = "platform.example.com"
  }

  # Card Service Internal API
  "cards.internal.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "internal-prod-ue1-card-service-979039334.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1-card-service-api-prod-internal"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "internal-prod-uw2-card-service-1246924643.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2-card-service-api-prod-internal"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "platform.example.com"
  }

  # TAG Web
  # The platform.example.com and www.platform.example.com records are of type CNAME and point to Imperva WAF. Currently managed outside of Terraform.
  # Imperva WAF forwards traffic to www-post-waf-lb.platform.example.com
  "www-post-waf-lb.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "ecs-fgate-alb-web-prod-2145906152.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 prod www post waf lb"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "ecs-fgate-alb-web-prod-751772080.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 prod www post waf lb"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "platform.example.com"
  }

  # Web internal
  "www.internal.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "internal-ecs-fgate-alb-web-intprod-1930481485.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 prod www internal lb"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "internal-ecs-fgate-alb-web-intprod-398934601.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 prod www internal lb"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "platform.example.com"
  }

  "common-api.internal.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "internal-ecs-common-api-internal-prod-1149362271.us-east-1.elb.amazonaws.com"
        set_identifier = "common-api-prod-us-east-1-internal"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "internal-ecs-common-api-internal-prod-323834815.us-west-2.elb.amazonaws.com"
        set_identifier = "common-api-prod-us-west-2-internal"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "platform.example.com"
  }

  # TAG API internal
  "api.internal.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "internal-ecs-fgate-alb-api-int-prod-2088101899.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1-api-prod"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "internal-ecs-fgate-alb-api-int-prod-1372860722.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2-api-prod"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "platform.example.com"
  }
}
