region = "us-east-1"

instances = [
  {
    name             = "app-01"
    ami              = "ami-0c02fb55956c7d316"
    instance_type    = "t3.small"
    key_name         = "prod-key"
    root_volume_type = "gp3"
    root_volume_size = 20
    environment      = "prod"
    owner            = "platform-team"
  },
  {
    name             = "app-02"
    ami              = "ami-0c02fb55956c7d316"
    instance_type    = "t3.medium"
    key_name         = "prod-key-2"
    root_volume_type = "gp3"
    root_volume_size = 30
    environment      = "prod"
    owner            = "platform-team"
  },
  {
    name             = "app-03"
    ami              = "ami-0c02fb55956c7d316"
    instance_type    = "m5.large"
    key_name         = "prod-key"
    root_volume_type = "io2"
    root_volume_size = 50
    iops             = 2500
    environment      = "prod"
    owner            = "platform-team"
  },
  {
    name             = "app-04"
    ami              = "ami-0c02fb55956c7d316"
    instance_type    = "c5.large"
    key_name         = "prod-key-3"
    root_volume_type = "standard"
    root_volume_size = 40
    environment      = "prod"
    owner            = "platform-team"
  },
  {
    name             = "app-05"
    ami              = "ami-0c02fb55956c7d316"
    instance_type    = "m5.xlarge"
    key_name         = "prod-key-4"
    root_volume_type = "gp2"
    root_volume_size = 60
    environment      = "prod"
    owner            = "platform-team"
  }
]
