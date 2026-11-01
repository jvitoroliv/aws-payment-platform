records = {
  # Mock Service
  "mock-dev.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "mock-us-east-1-dev.platform.example.com."
        set_identifier = "Mock us-east-1 dev"
        weight         = 100
      }
    }
    zone = "platform.example.com"
  }

  # Card Service API - deprecated
  "cards-internal-dev.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "cards-internal-dev-us-east-1.platform.example.com"
        set_identifier = "us-east-1-card-service-api-dev"
        weight         = 100
      }
      "us-west-2" = {
        record         = "cards-internal-dev-us-west-2.platform.example.com"
        set_identifier = "us-west-2-card-service-api-dev"
        weight         = 0
      }
    }
    zone = "platform.example.com"
  }


  # Card Service API internal
  "cards.internal.dev.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "internal-dev-ue1-card-service-1176308820.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1-card-service-api-dev-internal"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "internal-dev-uw2-card-service-1103949291.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2-card-service-api-dev-internal"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "dev.platform.example.com"
  }

  # Payment Scheduler API - deprecated
  "payments-internal-dev.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "payments-internal-dev-us-east-1.platform.example.com"
        set_identifier = "us-east-1-payment-scheduler-api-dev"
        weight         = 100
      }
      "us-west-2" = {
        record         = "payments-internal-dev-us-west-2.platform.example.com"
        set_identifier = "us-west-2-payment-scheduler-api-dev"
        weight         = 0
      }
    }
    zone = "platform.example.com"
  }

  # Payment Scheduler API internal
  "payments.internal.dev.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "internal-payments-scheduler-dev-1110347887.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1-payment-scheduler-api-dev-internal"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "internal-payments-scheduler-dev-589363736.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2-payment-scheduler-api-dev-internal"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "dev.platform.example.com"
  }

  # TAG API
  "api-post-waf-lb.dev.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "ecs-fgate-alb-api-dev-1911168578.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 dev api post waf lb"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "ecs-fgate-alb-api-dev-1861896468.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 dev api post waf lb"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "dev.platform.example.com"
  }

  # TAG API Internal - deprecated
  "dev-internal-api.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "internal-ecs-fgate-alb-api-int-dev-1168713626.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 dev internal api"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "internal-ecs-fgate-alb-api-int-dev-1414046550.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 dev internal api"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "platform.example.com"
  }

  # TAG API Internal
  "api.internal.dev.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "internal-ecs-fgate-alb-api-int-dev-1168713626.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 dev internal api"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "internal-ecs-fgate-alb-api-int-dev-1414046550.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 dev internal api"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "dev.platform.example.com"
  }

  # TAG Common API
  "common-api-post-waf-lb.dev.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "ecs-common-api-dev-1454701750.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 dev common api post waf lb"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "ecs-common-api-dev-242143475.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 dev common api post waf lb"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "dev.platform.example.com"
  }

  # TAG Common API Internal
  "common-api.internal.dev.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "internal-ecs-common-api-internal-dev-1501617018.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 dev common api internal"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "internal-ecs-common-api-internal-dev-200512315.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 dev common api internal"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "dev.platform.example.com"
  }

  # TAG Web
  "www-post-waf-lb.dev.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "ecs-fgate-alb-web-dev-1747695974.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 dev www post waf lb"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "ecs-fgate-alb-web-dev-2112780080.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 dev www post waf lb"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "dev.platform.example.com"
  }

  # TAG Web Internal
  "www.internal.dev.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "internal-ecs-fgate-alb-web-intdev-1198015686.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 dev www internal"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "internal-ecs-fgate-alb-web-intdev-630297180.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 dev www internal"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "dev.platform.example.com"
  }
}
