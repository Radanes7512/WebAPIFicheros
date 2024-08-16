using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApiAutores.Request;


namespace WebApiAutores.Controllers
{
    [ApiController]
    [Route("api/Uploader")]
    public class FileUploader : ControllerBase
    {

        private FileService _fileService;
        public FileUploader()
        {
            _fileService = new FileService();
        }

        [HttpGet("test-connection")]
        public IActionResult TestConnection()
        {
            return Ok(new { message = "La comunicación entre la API y la web funciona correctamente." });
        }



        /// <summary>
        /// Endpoint para subir un archivo. Recibe el nombre del archivo y el archivo en sí 
        /// desde un formulario y lo guarda en el servidor.
        /// </summary>
        /// <param name="request">Contiene el nombre del archivo y el archivo en sí.</param>
        /// <returns>Devuelve la ruta donde se guardó el archivo.</returns>
        [HttpPost("upload")]
        public async Task<IActionResult> UploadFile([FromForm] FileUploadRequest request)
        {
            // Verificar si se ha recibido un archivo en la petición
            if (request.File == null || request.File.Length == 0)
            {
                return BadRequest("No se ha seleccionado ningún archivo.");
            }

            // Si no se proporciona un nombre de archivo, se utiliza el nombre original
            string fileName = request?.File.FileName;

            // Usar el servicio para escribir el archivo
            var filePath = await _fileService.WriteFileAsync(request);

            // Devolver la ruta donde se guardó el archivo
            return Ok(new { filePath });
        }
    }
}



