# Changelog

All notable changes to this module are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module uses [semantic versioning](https://semver.org/): a new major version means callers must change their code.

## [Unreleased]

## [1.0.1] - 2026-10-06

### Changed

- The copyright year in `NOTICE` and the file headers is now 2026, the year the module was rebuilt and released as 1.0.0.
- `CLAUDE.md`, the working rules shared by every Automate the Cloud module, adds the lessons learned while rebuilding the modules.

## [1.0.0] - 2026-10-05

Initial release.

### Added

- An AWS Transit Gateway attachment for an Amazon VPC, in exactly the subnets you list.
- Attachment options: DNS support, IPv6, appliance mode, security group referencing, and association with and propagation to the transit gateway's default route table.
- Routes from the route tables you list to the transit gateway, keyed by names you choose, each to an IPv4 range, an IPv6 range or a managed prefix list. A route table created in the same configuration can be used.
- Checks at plan time for IDs, route destinations, and a route table listed twice for the same destination.
- `region`, to create everything in a Region other than the provider's.
- A `metadata` output with everything the module created.
- Offline tests, and a basic and a complete example.

[Unreleased]: https://github.com/AutomateTheCloud/terraform-aws-transit_gateway_attachment/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/AutomateTheCloud/terraform-aws-transit_gateway_attachment/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/AutomateTheCloud/terraform-aws-transit_gateway_attachment/releases/tag/v1.0.0
