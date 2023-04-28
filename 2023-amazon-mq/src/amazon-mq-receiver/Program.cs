using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;

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


var consumer = new EventingBasicConsumer(channel);
consumer.Received += (model, ea) =>
{
    var body = ea.Body.ToArray();
    var message = Encoding.UTF8.GetString(body);
    Console.WriteLine($" [x] Received {message}");
    int dots = message.Split('.').Length - 1;
    Thread.Sleep(dots * 1000);
    Console.WriteLine(" [x] Done");
};

channel.BasicConsume(queue: "mailbox",
                     autoAck: true,
                     consumer: consumer);


Console.WriteLine(" Press [enter] to exit.");
Console.ReadLine();
