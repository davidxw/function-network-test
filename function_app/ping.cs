using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace Company.Function
{
    public class ping
    {
        private readonly ILogger<ping> _logger;

        public ping(ILogger<ping> logger)
        {
            _logger = logger;
        }

        [Function("ping")]
        public IActionResult Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequest req)
        {
            _logger.LogInformation("C# HTTP trigger function 'ping' processed a request.");

            var ips = GetAllLocalIPv4();

            var responseMessage = $"Hello from machine {System.Environment.MachineName} - hostName: {System.Net.Dns.GetHostName()} - host IPs: {string.Join(",", ips.Select(n => n.ToString()).ToArray())}";

            return new OkObjectResult(responseMessage);
        }

        public List<string> GetAllLocalIPv4()
        {
            // https://stackoverflow.com/questions/6803073/get-local-ip-address

            List<string> ipAddrList = new List<string>();
            foreach (NetworkInterface item in NetworkInterface.GetAllNetworkInterfaces())
            {
                if (item.OperationalStatus == OperationalStatus.Up)
                {
                    foreach (UnicastIPAddressInformation ip in item.GetIPProperties().UnicastAddresses)
                    {
                        if (ip.Address.AddressFamily == AddressFamily.InterNetwork)
                        {
                            ipAddrList.Add($"{ip.Address} ({item.NetworkInterfaceType})");
                        }
                    }
                }
            }
            return ipAddrList;
        }

    }
}


