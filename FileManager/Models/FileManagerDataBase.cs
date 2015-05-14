using Microsoft.Practices.EnterpriseLibrary.TransientFaultHandling;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using FileManager.Models;
using System.Data;
using System.Timers;

namespace FileManager
{
    public class FileManagerDataBase
    {
        private SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder();
        private RetryManager manager;
        private RetryPolicy retryConnectionPolicy;
        private RetryPolicy retryCommandPolicy;

        public FileManagerDataBase()
        {
            builder["Server"] = "j7is9tex2d.database.windows.net";
            builder["User ID"] = "SQLAdmin@j7is9tex2d.database.windows.net";
            builder["Password"] = "Gg90879087";

            builder["Database"] = "filemanager12345_db";
            builder["Trusted_Connection"] = false;
            builder["Integrated Security"] = false;
            builder["Encrypt"] = true;

            int retryCount = 4;
            int minBackoffDelayMilliseconds = 2000;
            int maxBackoffDelayMilliseconds = 8000;
            int deltaBackoffMilliseconds = 2000;

            ExponentialBackoff exponentialBackoffStrategy =
              new ExponentialBackoff("exponentialBackoffStrategy",
                  retryCount,
                  TimeSpan.FromMilliseconds(minBackoffDelayMilliseconds),
                  TimeSpan.FromMilliseconds(maxBackoffDelayMilliseconds),
                  TimeSpan.FromMilliseconds(deltaBackoffMilliseconds));

            //2. Set a default strategy to Exponential Backoff.
            manager = new RetryManager(new List<RetryStrategy>
    {  
        exponentialBackoffStrategy 
    }, "exponentialBackoffStrategy");

            //3. Set a default Retry Manager. A RetryManager provides retry functionality, or if you are using declarative configuration, you can invoke the RetryPolicyFactory.CreateDefault
            RetryManager.SetDefault(manager);

            //4. Define a default SQL Connection retry policy and SQL Command retry policy. A policy provides a retry mechanism for unreliable actions and transient conditions.
            retryConnectionPolicy = manager.GetDefaultSqlConnectionRetryPolicy();
            retryCommandPolicy = manager.GetDefaultSqlCommandRetryPolicy();
        }

        public void Add(MyFile file)
        {
            string sqlCommand = "INSERT INTO MyFiles (FileKey, Name, Time, Uri, Downloads) VALUES ('" + file.Key + "', '" + file.Name + "', " + file.Time.ToString() + ", '" + file.URI + "', " + file.Downloads.ToString() + ");";

            retryConnectionPolicy.ExecuteAction(() =>
            {
                using (ReliableSqlConnection connection = new ReliableSqlConnection(builder.ConnectionString))
                {
                    connection.Open();

                    IDbCommand command = connection.CreateCommand();
                    command.CommandText = sqlCommand;
                    connection.ExecuteCommand(command);
                }
            });
        }

        public void Delete(MyFile file)
        {
            string sqlCommand = "DELETE FROM MyFiles WHERE FileKey = " + "'" + file.Key + "'";

            retryConnectionPolicy.ExecuteAction(() =>
            {
                using (ReliableSqlConnection connection = new ReliableSqlConnection(builder.ConnectionString))
                {
                    connection.Open();

                    IDbCommand command = connection.CreateCommand();
                    command.CommandText = sqlCommand;
                    connection.ExecuteCommand(command);
                }
            });
        }

        public void DownloadsInc(string key)
        {
            string sqlCommand = "UPDATE MyFiles SET Downloads = Downloads + 1 WHERE FileKey = '" + key + "'";

            retryConnectionPolicy.ExecuteAction(() =>
            {
                using (ReliableSqlConnection connection = new ReliableSqlConnection(builder.ConnectionString))
                {
                    connection.Open();

                    IDbCommand command = connection.CreateCommand();
                    command.CommandText = sqlCommand;
                    connection.ExecuteCommand(command);
                }
            });
        }

        //Почему-то не работает
        public string GetUri(string key)
        {
            string sqlCommand = "Select Uri From MyFiles Where FileKey = '" + key + "'";
            //string sqlCommand = "SELECT Uri From MyFiles WHERE FileKey = '" + key + "'";

            retryConnectionPolicy.ExecuteAction(() =>
            {
                using (ReliableSqlConnection connection = new ReliableSqlConnection(builder.ConnectionString))
                {
                    connection.Open();

                    IDbCommand command = connection.CreateCommand();
                    command.CommandText = sqlCommand;
                    //connection.ExecuteCommand(command);

                    retryCommandPolicy.ExecuteAction(() =>
                    {
                        using (IDataReader reader = connection.ExecuteCommand<IDataReader>(command))
                        {

                            if (reader.Read())
                            {
                                string uri = reader.GetString(0);
                                return uri;
                            }
                            else return null;
                        }
                    });
                }
            });
            return null;
        }
    }
}