records = {
  # Mock Service
  "mock-test.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "mock-us-east-1-test.platform.example.com."
        set_identifier = "mock-test-us-east-1"
        weight         = 100
      }
      "us-west-2" = {
        record         = "mock-us-west-2-test.platform.example.com."
        set_identifier = "Mock us-west-2"
        weight         = 0
      }
    }
    zone = "platform.example.com"
  }

  # Card Service API - deprecated
  "cards-internal-test.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "cards-internal-test-us-east-1.platform.example.com"
        set_identifier = "us-east-1-card-service-api-test"
        weight         = 100
      }
      "us-west-2" = {
        record         = "cards-internal-test-us-west-2.platform.example.com"
        set_identifier = "us-west-2-card-service-api-test"
        weight         = 0
      }
    }
    zone = "platform.example.com"
  }

  # Card Service API internal
  "cards.internal.test.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "internal-test-ue1-card-service-1642209641.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1-card-service-api-test-internal"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "internal-test-uw2-card-service-868933355.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2-card-service-api-test-internal"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "test.platform.example.com"
  }

  # Payment Scheduler API - deprecated
  "payments-internal-test.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "payments-internal-test-us-east-1.platform.example.com"
        set_identifier = "us-east-1-payment-scheduler-api-test"
        weight         = 100
      }
      "us-west-2" = {
        record         = "payments-internal-test-us-west-2.platform.example.com"
        set_identifier = "us-west-2-payment-scheduler-api-test"
        weight         = 0
      }
    }
    zone = "platform.example.com"
  }

  # Payment Scheduler API internal
  "payments.internal.test.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "internal-payments-scheduler-test-58356256.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1-payment-scheduler-api-test-internal"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "internal-payments-scheduler-test-107084921.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2-payment-scheduler-api-test=internal"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "test.platform.example.com"
  }
  
  # TAG API - deprecated
  "test-api.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "ecs-fgate-alb-api-test-1356275061.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 test api"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "ecs-fgate-alb-api-test-96507479.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 test api"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "platform.example.com"
  }

  # TAG API
  "api-post-waf-lb.test.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "ecs-fgate-alb-api-test-1356275061.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 test api post waf lb"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "ecs-fgate-alb-api-test-96507479.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 test api post waf lb"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "test.platform.example.com"
  }

  # TAG API Internal - deprecated
  "test-internal-api.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "internal-ecs-fgate-alb-api-int-test-43930705.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 test internal api"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "internal-ecs-fgate-alb-api-int-test-734473539.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 test internal api"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "platform.example.com"
  }

  # TAG API Internal
  "api.internal.test.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "internal-ecs-fgate-alb-api-int-test-43930705.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 test internal api"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "internal-ecs-fgate-alb-api-int-test-734473539.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 test internal api"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "test.platform.example.com"
  }

  # TAG Common API - deprecated
  "common-api-test.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "ecs-common-api-test-521195370.us-east-1.elb.amazonaws.com"
        set_identifier = "common-api-test-us-east-1"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "ecs-common-api-test-1115348050.us-west-2.elb.amazonaws.com"
        set_identifier = "common-api-test-us-west-2"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "platform.example.com"
  }

  # TAG Common API
  "common-api-post-waf-lb.test.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "ecs-common-api-test-521195370.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 test common api post waf lb"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "ecs-common-api-test-1115348050.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 test common api post waf lb"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "test.platform.example.com"
  }

  # TAG Common API Internal
  "common-api.internal.test.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "internal-ecs-common-api-internal-test-1235792951.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 test common api internal"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "internal-ecs-common-api-internal-test-774408705.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 test common api internal"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "test.platform.example.com"
  }

  # TAG Web
  "www-post-waf-lb.test.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "ecs-fgate-alb-web-test-695488995.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 test www post waf lb"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "ecs-fgate-alb-web-test-2044989990.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 test www post waf lb"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "test.platform.example.com"
  }

  # TAG Web Internal
  "www.internal.test.platform.example.com" = {
    targets = {
      "us-east-1" = {
        record         = "internal-ecs-fgate-alb-web-inttest-173016818.us-east-1.elb.amazonaws.com"
        set_identifier = "us-east-1 test www internal"
        weight         = 100
        zone_id        = "Z0EXAMPLE000000"
      }
      "us-west-2" = {
        record         = "internal-ecs-fgate-alb-web-inttest-2117654251.us-west-2.elb.amazonaws.com"
        set_identifier = "us-west-2 test www internal"
        weight         = 0
        zone_id        = "Z0EXAMPLE000000"
      }
    }
    zone = "test.platform.example.com"
  }
}
