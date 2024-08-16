namespace WebApiAutores.Request
{
    public class FileUploadRequest
    {
        /// <summary>
        /// El archivo en sí que se carga a través de un formulario.
        /// </summary>
        public IFormFile File { get; set; }
    }

}
