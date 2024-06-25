# Networking in Azure Functions

This repo contains a simple example of how to restrict ingress traffic to an Azure Function from a specific subnet using App Services [access restictions](hhttps://learn.microsoft.com/en-us/azure/app-service/overview-access-restrictions) and private endpoints, and also how to direct egress traffic from an Azure Function to a Vnet using [Virtual Network Integresion](https://learn.microsoft.com/en-us/azure/app-service/overview-vnet-integration).

The repo consist if two levels of Functions:

* L1.1 and L1.2 have public inbound access (ingress), and egress sent to a Vnet
* L2 have ingress restricted to a specific subnet:
    * L2.1 can only be accessed from L1.1, using access restrictions
    * L2.2 can only be accessed from L1.2, using a private endpoint on L2.2 and an NSG

Each function app has 2 endpoints:

* "ping" - returns a simple message
* "pingDownstream" - makes a HTTP call to a configured list of downstream endpoints.

To run the demo:

* Deploy the resources in the "infra" folder
* Deploy an instance of the function in the "function_app" folder to each function (4 in total). There is a deploy script in the "function_app" folder that can be used to deploy the function apps.
* Update the "DOWNSTREAM" environment variable in the L1 function apps with a comma separated list containing the "ping" endpoint of the L2 function apps
* From a browser or curl call the L1 "pingDownstream" endpoint to see the proxied response from the L2 function apps. The response should look something like this:

From L1.1 - L2.2 cannot be reached as it is behind a private endpoint and NSG rules are in place to restrict access from any subnet other than the one L1.2 uses for Vnet access.

```
#############################################################
Calling: https://functionappl2-1-i7q5xmih3kcgg.azurewebsites.net/api/ping?code=aaa
Response: OK - Hello from machine 626747b62925 - hostName: 626747b62925 - host IPs: 127.0.0.1 (Loopback),169.254.129.3 (Ethernet)
#############################################################
Calling: https://functionappl2-2-i7q5xmih3kcgg.azurewebsites.net/api/ping?code=aaa
Failed: The request was canceled due to the configured HttpClient.Timeout of 10 seconds elapsing.
```

From L1.2 - L2.1 cannot be reached as it has access restrictions in place to only allow access from the subnet of L1.1

```
#############################################################
Calling: https://functionappl2-1-i7q5xmih3kcgg.azurewebsites.net/api/ping?code=aaa
Response: Forbidden - Ip Forbidden
#############################################################
Calling: https://functionappl2-2-i7q5xmih3kcgg.azurewebsites.net/api/ping?code=aaa
Response: OK - Hello from machine d7fc48e7a52c - hostName: d7fc48e7a52c - host IPs: 127.0.0.1 (Loopback),169.254.129.3 (Ethernet)
```