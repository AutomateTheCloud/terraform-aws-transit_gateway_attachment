# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

locals {
  # The attachment's Name tag: <scope>-<purpose>-<environment>-<region> unless the input
  # names it.
  attachment_name = var.attachment.name != null ? var.attachment.name : "${local.scope.abbr}-${local.purpose.abbr}-${local.environment.abbr}-${local.aws.region.abbr}"
}
