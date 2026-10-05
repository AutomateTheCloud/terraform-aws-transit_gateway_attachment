# Basic transit gateway attachment

A VPC attached to a new transit gateway in `us-east-1`, through a private subnet in each of two Availability Zones. The VPC's private route table sends traffic for `10.0.0.0/8` to the transit gateway; traffic within the VPC's own range, `10.50.0.0/16`, stays in the VPC, because the more specific route wins.

The transit gateway keeps AWS's default settings, so the attachment is associated with its default route table and propagates the VPC's range to it. Another VPC attached to the same transit gateway, with a matching route, could reach this one.

A transit gateway attachment is billed by the hour while it exists, and for each gigabyte sent to the transit gateway; see [AWS Transit Gateway pricing](https://aws.amazon.com/transit-gateway/pricing/).

## Run it

```shell
terraform init
terraform apply
```

Creating the transit gateway and the attachment takes a few minutes each. Remove it with `terraform destroy`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Outputs

The following outputs are exported:

#### <a name="output_transit_gateway_attachment_id"></a> [transit_gateway_attachment_id](#output_transit_gateway_attachment_id)

Description: The attachment's ID, which transit gateway route tables refer to
<!-- END_TF_DOCS -->
