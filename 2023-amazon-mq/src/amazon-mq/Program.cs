// See https://aka.ms/new-console-template for more information
using RabbitMQ.Client;
using System.Text;

internal class Program
{
    private static void Main(string[] args)
    {
        var factory = new ConnectionFactory()
        {
            HostName = "b-2d48176f-1640-4019-9561-b35853964802.mq.eu-west-1.amazonaws.com",
            Port = 5671,
            UserName = "rob-vp",
            Password = "",
            Ssl = new SslOption
            {
                Enabled = true,
                ServerName = "b-2d48176f-1640-4019-9561-b35853964802.mq.eu-west-1.amazonaws.com"
            }
        };



        using var connection = factory.CreateConnection();
        using var channel = connection.CreateModel();

        channel.QueueDeclare(queue: "mailbox",
                             durable: false,
                             exclusive: false,
                             autoDelete: false,
                             arguments: null);

        string message = args.Length > 0 ? string.Join(" ", args) : "Hello World!";

        var body = Encoding.UTF8.GetBytes(message);

        channel.BasicPublish(exchange: string.Empty,
                             routingKey: "mailbox",
                             basicProperties: null,
                             body: body);
        Console.WriteLine($" [x] Sent {message}");
    }
}