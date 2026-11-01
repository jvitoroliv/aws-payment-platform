records = {
  # Card Service API - deprecated
  "cards-internal.stage.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "cards-internal-stage-us-east-1.stage.platform.example.com"
        set_identifier = "us-east-1-card-service-api-stage"
        weight         = 100
      }
      "us-west-2" = {
        record         = "cards-internal-stage-us-west-2.stage.platform.example.com"
        set_identifier = "us-west-2-card-service-api-stage"
        weight         = 0
      }
    }
    zone = "stage.platform.example.com"
  }

  # Card Service API internal
  "cards.internal.stage.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "internal-stage-ue1-card-service-727846736.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1-card-service-api-stage-internal"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "internal-stage-uw2-card-service-404058114.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2-card-service-api-stage-internal"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "stage.platform.example.com"
  }

  # Mock Service
  "mock-stage.stage.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "mock-us-east-1-stage.stage.platform.example.com"
        set_identifier = "mock-stage-us-east-1"
        weight         = 100
      }
      # Mock service is not deployed in us-west-2
      # "us-west-2" = {
      #   record         = "mock-us-west-2-stage.stage.platform.example.com"
      #   set_identifier = "mock-stage-us-west-2"
      #   weight         = 0
      # }
    }
    zone = "stage.platform.example.com"
  }

  # Payment Scheduler API
  # Add again when Payment Scheduler is moved to the new Stage AWS account
  # "payments-internal-stage.platform.example.com" = {
  #   targets = {
  #     "us-east-1" = {
  #       record         = "payments-internal-stage-us-east-1.platform.example.com"
  #       set_identifier = "us-east-1-payment-scheduler-api-stage"
  #       weight         = 100
  #     }
  #     "us-west-2" = {
  #       record         = "payments-internal-stage-us-west-2.platform.example.com"
  #       set_identifier = "us-west-2-payment-scheduler-api-stage"
  #       weight         = 0
  #     }
  #   }
  #   zone = "platform.example.com"
  # }

  # TAG API
  "api-post-waf-lb.stage.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "ecs-fgate-alb-api-stage-2089181143.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 stage api post waf lb"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "ecs-fgate-alb-api-stage-1833492252.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 stage api post waf lb"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "stage.platform.example.com"
  }

  # TAG API Internal - deprecated
  "internal-api.stage.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "ecs-fargate-api-internal-stage-us-east-1.stage.platform.example.com"
        set_identifier = "internal-api-stage-us-east-1"
        weight         = 100
      }
      "us-west-2" = {
        record         = "ecs-fargate-api-internal-stage-us-west-2.stage.platform.example.com"
        set_identifier = "internal-api-stage-us-west-2"
        weight         = 0
      }
    }
    zone = "stage.platform.example.com"
  }

  # TAG API Internal
  "api.internal.stage.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "ecs-fargate-api-internal-stage-us-east-1.stage.platform.example.com"
        set_identifier = "internal-api-stage-us-east-1"
        weight         = 100
      }
      "us-west-2" = {
        record         = "ecs-fargate-api-internal-stage-us-west-2.stage.platform.example.com"
        set_identifier = "internal-api-stage-us-west-2"
        weight         = 0
      }
    }
    zone = "stage.platform.example.com"
  }

  # TAG Common API
  "common-api-post-waf-lb.stage.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "ecs-common-api-stage-1167288137.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 stage common api post waf lb"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "ecs-common-api-stage-1698717563.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 stage common api post waf lb"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "stage.platform.example.com"
  }

  # TAG Common API Internal
  "common-api.internal.stage.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "internal-ecs-common-api-internal-stage-1979096175.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 stage common api internal"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "internal-ecs-common-api-internal-stage-1979616581.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 stage common api internal"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "stage.platform.example.com"
  }

  # TAG Web
  "www-post-waf-lb.stage.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "ecs-fgate-alb-web-stage-1146841858.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 stage www post waf lb"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "ecs-fgate-alb-web-stage-1946186956.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 stage www post waf lb"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "stage.platform.example.com"
  }

  # TAG Web Internal
  "www.internal.stage.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "internal-ecs-fgate-alb-web-intstage-1014741508.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 stage www internal"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "internal-ecs-fgate-alb-web-intstage-1656523501.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 stage www internal"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "stage.platform.example.com"
  }
}
