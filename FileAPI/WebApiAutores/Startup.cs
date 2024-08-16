using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace WebApiAutores
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        public void ConfigureServices(IServiceCollection services)
        {
            services.AddControllers();
            // Configuración de Swagger/OpenAPI
            services.AddEndpointsApiExplorer();
            services.AddSwaggerGen();

            // Configuración de CORS
            services.AddCors(options =>
            {
                options.AddPolicy("AllowBlazorClient", builder =>
                {
                    builder.WithOrigins("https://localhost:7173") // URL de la aplicación Blazor sin barra al final
                           .AllowAnyHeader()
                           .AllowAnyMethod();
                });
            });
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            app.UseHttpsRedirection();

            app.UseRouting();

            // Aplicar la política de CORS
            app.UseCors("AllowBlazorClient");

            app.UseAuthorization();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });
        }


    }

}
