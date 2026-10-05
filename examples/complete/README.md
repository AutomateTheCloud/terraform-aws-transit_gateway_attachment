# Complete transit gateway attachment

A VPC in `us-east-1` attached to a new transit gateway that does not use a default route table. The example shows:

- Attachment subnets of their own: a `/28` in each of two Availability Zones, apart from the application subnets.
- Security group referencing, turned on in both the transit gateway and the attachment.
- Routes from each application route table to the transit gateway: one for `10.0.0.0/8`, and one for the ranges in a managed prefix list of a partner's networks.
- The attachment placed in a transit gateway route table of its own: `default_route_table_association` and `default_route_table_propagation` are `false`, and the example associates the attachment with the `shared` route table and propagates the VPC's range to it, using the module's `metadata.vpc_attachment.id`.

The partner ranges, `192.168.10.0/24` and `192.168.20.0/24`, are placeholders: nothing is attached to the transit gateway that serves them, so traffic to them goes nowhere.

A transit gateway attachment is billed by the hour while it exists, and for each gigabyte sent to the transit gateway; see [AWS Transit Gateway pricing](https://aws.amazon.com/transit-gateway/pricing/).

## Run it

```shell
terraform init
terraform apply
```

Remove it with `terraform destroy`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Outputs

The following outputs are exported:

#### <a name="output_routes"></a> [routes](#output_routes)

Description: Each route the module added, with its route table and destination

#### <a name="output_transit_gateway_attachment_id"></a> [transit_gateway_attachment_id](#output_transit_gateway_attachment_id)

Description: The attachment's ID
<!-- END_TF_DOCS -->
