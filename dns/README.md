# Digital Ocean environment for Sandesnet LLC - Name server

This is the procedure for buiding aand configuring name servers in Digital Ocean.

The name server configuration provides two views - internal and external.

The internal view includes the zones for the hosts in the local network.

The external view includes the zones used to resolve host names from the outside.

In the current configuration queries are only allowed from the local networks for the internal view.

Access to the zones in the external view is controlled via an access control list (ACL) - 0.external - which can be configured to allow queries, transfers to listed hosts or both.

Usage:

* Naming conventions for zone files: my.domain.internal for internal view and my.domain.external for the external view.

* The transfer ACL file must be named 0.external. The build script generates a default 0.external file which allows external zone queries but not transfers.

* The zone files must be present in the ansible/var/named directory before running the build script.

* Run the build script with the following command line:

	./dnsserverbuild.sh region.domain nr_of_instances

* region.domain = the Digital Ocean region (example nyc1) and the domain. The region.domain entry must be present in the domain's DNS zone.

* nr_of_instances is optional (default 2)

