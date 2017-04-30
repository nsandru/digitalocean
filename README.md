# Digital Ocean environment for Sandesnet LLC

Building a set of docker servers on Digital Ocean to function as a back up for the Sandesnet LLC services.

The set is consisting of the following types of docker containers:

  1. http servers - apache and nginx for hosting websites

  2. consul - for service discovery

  3. ha-proxy - load balancer (for testing purposes, it will be hosted on the firewall/gateway VMs in the final setup)

Besides docker servers other VMs are planned to host email, LDAP and DNS services.

The docker containers are built with packer and the applications are configured with ansible.

The docker image used as startpoint is centos:7. The centos7ansible image is built from it, and this image (with ansible installed) is used to build the application-specific images.


