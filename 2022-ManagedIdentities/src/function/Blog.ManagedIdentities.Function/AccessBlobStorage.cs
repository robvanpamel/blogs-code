using System.Net;
using Azure.Identity;
using Azure.Storage.Blobs;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace Blog.ManagedIdentities.Function;

public static class AccessBlobStorage
{
    private const string BLOB_CONTAINER = "cntr-simple-storage";
    private const string BLOB_ACCOUNT = "storetf77xg36cmxio";
    private const string BLOB_SASTOKEN = "<ADD SAS TOKEN HERE>";

    [Function("AccessBlobStorage")]
    public static async Task<HttpResponseData> Read([HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequestData req,
        FunctionContext executionContext)
    {
        var logger = executionContext.GetLogger("ReadBlobStorage");
        logger.LogInformation("C# HTTP trigger function processed a request.");

        var response = req.CreateResponse(HttpStatusCode.OK);
        response.Headers.Add("Content-Type", "text/plain; charset=utf-8");
        try
        {
            await WriteWithSas();

            await response.WriteStringAsync("Welcome to reading Azure Functions!");

        }
        catch (Exception ex)
        {
            await response.WriteStringAsync($"ex: {ex.Message}, ex {ex.InnerException}");
        }
        return response;
    }

    public static async Task WriteWithoutSAS()
    {
        string containerEndpoint = $"https://{BLOB_ACCOUNT}.blob.core.windows.net/{BLOB_CONTAINER}";

        var client = new BlobContainerClient(new Uri(containerEndpoint), new DefaultAzureCredential());

        await WriteToContainer(client);
    }

    public static async Task WriteWithSas()
    {
        string blobContainerName = BLOB_CONTAINER;
        var connectionString =
                $"BlobEndpoint=https://{BLOB_ACCOUNT}.blob.core.windows.net/;{BLOB_SASTOKEN}";
        var client = new BlobContainerClient(connectionString, blobContainerName);
        await WriteToContainer(client);
    }

    private static async Task WriteToContainer(BlobContainerClient blobContainerClient)
    {
        using (var stream = new MemoryStream())
        {
            using StreamWriter writer = new StreamWriter(stream);
            await writer.WriteLineAsync($"Last accessed at: {DateTime.Now}");
            await writer.FlushAsync();
            stream.Position = 0;
            _ = await blobContainerClient.UploadBlobAsync($"file-{DateTime.UtcNow:yyyy-MM-dd-HH-mm-ss}.txt", stream);
        };
    }
}