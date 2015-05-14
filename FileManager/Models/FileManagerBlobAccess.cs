using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Web;
using FileManager.Models;
using System.Timers;
using System.IO;

namespace FileManager
{
    public class FileManagerBlobAccess
    {
        private string connString;
        private string destContainer;
        private CloudStorageAccount sa;
        private CloudBlobClient bc;
        private CloudBlobContainer container;

        public FileManagerBlobAccess()
        {
            connString = ConfigurationManager.ConnectionStrings["StorageConnectionString"].ConnectionString;
            destContainer = ConfigurationManager.AppSettings["destConrainer"];

            sa = CloudStorageAccount.Parse(connString);
            bc = sa.CreateCloudBlobClient();

            container = bc.GetContainerReference(destContainer);
            container.CreateIfNotExists();
        }

        public String GetContainerUri()
        {
            return container.Uri.ToString();
        }

        public void AddFile(MyFile file)
        {
            CloudBlockBlob b = container.GetBlockBlobReference(file.Key);

            b.UploadFromStream(file.FileStream);
        }

        public void DeleteFile(MyFile file)
        {
            CloudBlockBlob b = container.GetBlockBlobReference(file.Key);

            b.Delete();
        }
    }
}