using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;
using System;
using System.Configuration;
using System.Web;
using System.Web.Mvc;
using System.Threading;
using FileManager.Models;

namespace FileManager.Controllers
{
    public class HomeController : Controller
    {
        static FileManagerDataBase dataBase = new FileManagerDataBase();
        static FileManagerBlobAccess blob = new FileManagerBlobAccess();

        public ActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public String UploadFile(HttpPostedFileBase upload, int time)
        {
            string key = DateTime.UtcNow.ToString("yyyy-MM-dd-HH:mm:ss") + "-" + upload.FileName;

            string containerUri = blob.GetContainerUri() + @"/";

            MyFile file = new MyFile { Key = key, Name = upload.FileName, Time = time, FileStream = upload.InputStream, Downloads = 0, URI = containerUri + key };

            blob.AddFile(file);
            dataBase.Add(file);

            Thread thread = new Thread(delegate() { DeleteFile(file); });
            thread.Start();

            return key;
            //return dataBase.GetUri(key);
            //return file.URI;
        }

        public void DeleteFile(MyFile file)
        {
            Thread.Sleep(file.Time * 24 * 60 * 60 * 1000);
            blob.DeleteFile(file);
            dataBase.Delete(file);
        }

        public RedirectResult Download(string key)
        {
            //string uri = @"https://filemanagerstorage.blob.core.windows.net/fmcontainer/" + key;
            string uri = blob.GetContainerUri() + @"/" + key;
            //string uri = dataBase.GetUri(key);

            dataBase.DownloadsInc(key);

            return Redirect(uri);
        }
    }
}