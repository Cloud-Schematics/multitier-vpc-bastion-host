# Cloud logging	
resource "ibm_resource_instance" "logging" {
  count             = var.create_logging ? 1 : 0
  name              = "${var.basename}-logging"
  resource_group_id = var.resource_group_id
  service           = "logdna"
  plan              = "7-day"
  location          = var.region
  tags              = concat(var.tags, ["service"])
}

resource "ibm_resource_key" "logging_key" {
  count                = var.create_logging ? 1 : 0
  name                 = "${var.basename}-logging-key"
  resource_instance_id = ibm_resource_instance.logging.0.id
  role                 = "Manager"
}

# Cloud monitoring	
resource "ibm_resource_instance" "monitoring" {
  count             = var.create_monitoring ? 1 : 0
  name              = "${var.basename}-monitoring"
  resource_group_id = var.resource_group_id
  service           = "sysdig-monitor"
  plan              = "graduated-tier"
  location          = var.region
  tags              = concat(var.tags, ["service"])
}

resource "ibm_resource_key" "monitoring_key" {
  count                = var.create_monitoring ? 1 : 0
  name                 = "${var.basename}-monitoring-key"
  resource_instance_id = ibm_resource_instance.monitoring.0.id
  role                 = "Manager"
}

# Create Key protect + root key
resource "ibm_resource_instance" "keyprotect" {

  name              = "${var.basename}-kms"
  resource_group_id = var.resource_group_id
  service           = "kms"
  plan              = "tiered-pricing"
  location          = var.region
  tags              = concat(var.tags, ["service"])
  service_endpoints = "private"
}

resource "ibm_kms_key" "key" {
  instance_id  = ibm_resource_instance.keyprotect.guid
  key_name     = "root_key"
  standard_key = false
  force_delete = true
}

# Create Cloud Object Storage service, policy and COS bucket

resource "ibm_resource_instance" "cos" {

  name              = "${var.basename}-cos"
  resource_group_id = var.resource_group_id
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
  tags              = concat(var.tags, ["service"])
  service_endpoints = "private"
}

resource "ibm_resource_key" "cos_key" {

  name                 = "${var.basename}-cos-key"
  resource_instance_id = ibm_resource_instance.cos.id
  role                 = "Writer"

  parameters = {
    service-endpoints = "private"
    HMAC              = true
  }
  depends_on           = [ibm_iam_authorization_policy.cos_policy]
}

resource "ibm_iam_authorization_policy" "cos_policy" {
  source_service_name         = "cloud-object-storage"
  source_resource_instance_id = ibm_resource_instance.cos.guid
  target_service_name         = ibm_kms_key.key.type
  target_resource_instance_id = ibm_resource_instance.keyprotect.guid
  roles                       = ["Reader"]
}

resource "random_uuid" "uuid" {
}

resource "ibm_cos_bucket" "bucket" {
  bucket_name          = "${var.basename}-${random_uuid.uuid.result}-bucket"
  key_protect          = ibm_kms_key.key.crn
  resource_instance_id = ibm_resource_instance.cos.id
  region_location      = var.region
  storage_class        = "smart"
  force_delete         = true
  depends_on           = [ibm_iam_authorization_policy.cos_policy]
}

# Create a Postgresql DB 

resource "ibm_database" "postgresql" {
  resource_group_id = var.resource_group_id
  name              = "${var.basename}-postgres"
  service           = "databases-for-postgresql"
  plan              = "standard"
  location          = var.region
  tags              = concat(var.tags, ["service"])
  key_protect_key   = ibm_kms_key.key.crn
  service_endpoints = "private"
  depends_on        = [ibm_iam_authorization_policy.postgresql_policy]
}

resource "ibm_resource_key" "postgresql_key" {
  name                 = "${var.basename}-postgresql-key"
  resource_instance_id = ibm_database.postgresql.id
  role                 = "Administrator"

  parameters = {
    service-endpoints = "private"
  }
  depends_on        = [ibm_iam_authorization_policy.postgresql_policy]
}

resource "ibm_iam_authorization_policy" "postgresql_policy" {
  source_service_name         = "databases-for-postgresql"
  target_service_name         = ibm_kms_key.key.type
  target_resource_instance_id = ibm_resource_instance.keyprotect.guid
  roles                       = ["Reader", "AuthorizationDelegator"]
}

resource "time_sleep" "wait_for_postgresql_initialization" {
  #count               = var.step2_create_vpc || var.step4_create_dedicated ? 1 : 0
  depends_on = [
    ibm_database.postgresql
  ]

  create_duration = "5m"
}