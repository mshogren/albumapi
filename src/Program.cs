using Azure.Core;
using Azure.Identity;
using Microsoft.Azure.Cosmos;

var builder = WebApplication.CreateBuilder();

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddCors(options => {
    options.AddDefaultPolicy(builder =>
    {
        builder.AllowAnyOrigin();
        builder.AllowAnyHeader();
        builder.AllowAnyMethod();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors();

app.MapGet("/", async context =>
{
    await context.Response.WriteAsync("Hit the /albums endpoint to retrieve a list of albums!");
});

app.MapGet("/albums", () =>
{
    return Album.GetAll();
})
.WithName("GetAlbums");

app.MapGet("/albumsdb", async () =>
{
    return await Album.GetAllFromDb();
})
.WithName("GetAlbumsFromDb");

app.Run();

record Album(string Id, string Title, string Artist, double Price, string Image_url)
{
     public static List<Album> GetAll(){
         var albums = new List<Album>(){
            new Album("1", "You, Me and an App Id", "Daprize", 10.99, "https://aka.ms/albums-daprlogo"),
            new Album("2", "Seven Revision Army", "The Blue-Green Stripes", 13.99, "https://aka.ms/albums-containerappslogo"),
            new Album("3", "Scale It Up", "KEDA Club", 13.99, "https://aka.ms/albums-kedalogo"),
            new Album("4", "Lost in Translation", "MegaDNS", 12.99,"https://aka.ms/albums-envoylogo"),
            new Album("5", "Lock Down Your Love", "V is for VNET", 12.99, "https://aka.ms/albums-vnetlogo"),
            new Album("6", "Sweet Container O' Mine", "Guns N Probeses", 14.99, "https://aka.ms/albums-containerappslogo")
         };

        return albums; 
     }

     public static async Task<List<Album>> GetAllFromDb() {
        TokenCredential credential = new DefaultAzureCredential();
        using CosmosClient client = new(
            accountEndpoint: Environment.GetEnvironmentVariable("AZURE_COSMOS_RESOURCEENDPOINT")!,
            tokenCredential: credential
        );
        var container = client.GetContainer("main", "albums");

        var query = new QueryDefinition(
            query: "SELECT * FROM albums"
        );

        using FeedIterator<Album> feed = container.GetItemQueryIterator<Album>(
            queryDefinition: query
        );
        
        List<Album> items = new();
        double requestCharge = 0d;
        while (feed.HasMoreResults)
        {
            FeedResponse<Album> response = await feed.ReadNextAsync();
            foreach (Album item in response)
            {
                items.Add(item);
            }
            requestCharge += response.RequestCharge;
        }

        return items;
     }
}