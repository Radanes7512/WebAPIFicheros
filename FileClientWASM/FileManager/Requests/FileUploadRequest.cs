using Microsoft.AspNetCore.Components.Forms;

namespace FileManager.Request
{
    public class FileUploadRequest
    {
        public IBrowserFile File { get; set; }
    }

}
