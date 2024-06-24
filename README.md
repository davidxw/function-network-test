# Networking in Azure Functions

This repo contains a simple example of how to restrict ingress traffic to an Azure Function from a specific subnet using App Services ([access restictions](hhttps://learn.microsoft.com/en-us/azure/app-service/overview-access-restrictions)), and also how to direct egress traffic from an Azure Function to a Vnet using [Virtual Network Integresion](https://learn.microsoft.com/en-us/azure/app-service/overview-vnet-integration).

Note that acces restrictions are different from private endpoints.  If a private endpoint is configured for an Azure Function then all ingress traffic is allowed - in this case restricutions can be added using NSG rules.  While the access restrictions feature provides number of different ways to restrict acces, this example uses service endpoints to filter to all traffic from a subnet.

The repo consist if two levels of Functions:

* L1 have public inbound access (ingress), and egress sent to a Vnet
* L2 have ingress restricted to a specific subnet.

There are four function apps deployed - L1.1, L1.2, L2.1 and L2.2.  L2.1 is configured to only allow access form L1.1, and L2.2 is configured to only allow access from L1.2.

Each function app has 2 endpoints:

* "ping" - return a simple message
* "pingDownstream" - makes a HTTP call to a configured list of downstream endpoints.

To run the demo:

* Deploy the resources in the "infra" folder
* Deploy an instance of the function in the "function_app" folder to each function (4 in total)
* Add a "DOWNSTREAM" environment variable to the L1 function apps with a comma separated list containing the "ping" endpoint of the L2 function apps
* From a browser or curl call the L1 "pingDownstream" endpoint to see the response from the L2 function apps.  The response should look something like this:

```
#############################################################
Calling: https://functionappl2-1-7ix62hnooznzs.azurewebsites.net/api/ping?code=xxx
Response: Forbidden - Ip Forbidden
#############################################################
Calling: https://functionappl2-2-7ix62hnooznzs.azurewebsites.net/api/ping?code=xxx
Response: OK - Hello from machine 7e36af7220c3 - hostName: 7e36af7220c3 - host IPs: 127.0.0.1 (Loopback),169.254.129.3 (Ethernet) - original client IPs: 127.0.0.1
```