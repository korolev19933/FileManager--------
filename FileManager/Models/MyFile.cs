using System;
using System.ComponentModel.DataAnnotations;
using System.IO;
using System.Web;

namespace FileManager.Models
{
    public class MyFile
    {
        public string Key { get; set; }
        public string Name { get; set; }
        public int Time { get; set; }
        public Stream FileStream { get; set; }
        public int Downloads { get; set; }
        [DataType(DataType.Url)]
        public string URI { get; set; }
    }
}