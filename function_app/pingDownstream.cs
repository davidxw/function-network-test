using System.Drawing;
using System.Text;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Company.Function
{
    public class pingDownstream
    {
        private readonly ILogger<pingDownstream> _logger;
        private List<string> _downstreamAddresses = new List<string>();

        private HttpClient _httpClient;

        public pingDownstream(ILogger<pingDownstream> logger, IConfiguration config)
        {
            _logger = logger;

            if (string.IsNullOrEmpty(config["DOWNSTREAM"]))
            {
                throw new Exception("DOWNSTREAM configuration not set.");
            }

            _downstreamAddresses = (config["DOWNSTREAM"] as string).Split(",").ToList<string>();

            var handler = new HttpClientHandler();
            handler.ClientCertificateOptions = ClientCertificateOption.Manual;
            handler.ServerCertificateCustomValidationCallback =
                (httpRequestMessage, cert, cetChain, policyErrors) =>
                {
                    return true;
                };

            int.TryParse(config["TIMEOUT"], out int tryTimeOutInSeconds);

            var timeOutInSeconds = tryTimeOutInSeconds > 0 ? tryTimeOutInSeconds : 10;

            logger.LogInformation($"HttpTimeout set to {timeOutInSeconds} seconds.");

            _httpClient = new HttpClient(handler)
            {
                Timeout = new TimeSpan(0, 0, timeOutInSeconds)
            };
        }

        [Function("pingDownstream")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequest req)
        {
            _logger.LogInformation("C# HTTP trigger function 'pingDownstream' processed a request.");

            var responseMessage = new StringBuilder();

            foreach (var downstreamAddress in _downstreamAddresses)
            {
                responseMessage.AppendLine($"#############################################################");
                responseMessage.AppendLine($"Calling: {downstreamAddress}");

                try
                {
                    var httpResponse = await _httpClient.GetAsync(downstreamAddress);

                    if (httpResponse.StatusCode != System.Net.HttpStatusCode.OK)
                    {
                        responseMessage.AppendLine($"Response: {httpResponse.StatusCode} - {httpResponse.ReasonPhrase}");
                    }
                    else
                    {
                        var content = await httpResponse.Content.ReadAsStringAsync();

                        responseMessage.AppendLine($"Response: {httpResponse.StatusCode} - {content}");
                    }
                }
                catch (Exception ex)
                {
                    responseMessage.AppendLine($"Failed: {ex.Message}");
                }
            }

            return new OkObjectResult(responseMessage.ToString());
        }
    }
}
