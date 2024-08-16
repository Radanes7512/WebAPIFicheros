using System.IO;
using System.IO.Pipes;
using System.Threading.Tasks;
using WebApiAutores.Request;

namespace WebApiAutores
{
    public class FileService
    {
        // Ruta donde se guardarán los archivos recibidos
        private readonly string _destinyPath = "FICHEROS RECIBIDOS";

        public FileService()
        {
            // Asegúrate de que la ruta de destino existe al instanciar el servicio
            if (!Directory.Exists(_destinyPath))
            {
                Directory.CreateDirectory(_destinyPath);
            }
        }

        /// <summary>
        /// Escribe el archivo en la ruta de destino especificada.
        /// </summary>
        /// <param name="fileName">El nombre del archivo a guardar.</param>
        /// <param name="fileStream">El flujo de datos del archivo a guardar.</param>
        /// <returns>La ruta completa donde se guardó el archivo.</returns>
        public async Task<string> WriteFileAsync(FileUploadRequest fileRequest)
        {
            // Define la ruta completa donde se guardará el archivo
            var filePath = Path.Combine(_destinyPath, fileRequest.File.FileName);
            var fileStream = fileRequest.File.OpenReadStream();
            // Guardar el archivo en la ruta especificada
            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await fileStream.CopyToAsync(stream);
            }

            // Devolver la ruta completa del archivo guardado
            return filePath;
        }
    }
}
