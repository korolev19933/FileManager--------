#  AzureWebSitePublishModule.psm1 является модулем сценария Windows PowerShell. Он экспортирует функции Windows PowerShell, которые автоматизируют управление жизненным циклом для веб-приложений. Вы можете использовать эти функции как есть или настроить для своего приложения и среды публикации.

Set-StrictMode -Version 3

# Переменная для сохранения исходной подписки.
$Script:originalCurrentSubscription = $null

# Переменная для сохранения исходной учетной записи хранения.
$Script:originalCurrentStorageAccount = $null

# Переменная для сохранения учетной записи хранения указанной пользователем подписки.
$Script:originalStorageAccountOfUserSpecifiedSubscription = $null

# Переменная для сохранения имени подписки.
$Script:userSpecifiedSubscription = $null


<#
.SYNOPSIS
Добавляет дату и время в начало сообщения.

.DESCRIPTION
Добавляет дату и время в начало сообщения. Эта функция предназначена для сообщений, записываемых в потоки Error и Verbose.

.PARAMETER  Message
Указывает сообщение без даты.

.INPUTS
System.String

.OUTPUTS
System.String

.EXAMPLE
PS C:\> Format-DevTestMessageWithTime -Message "Добавление файла $filename в каталог"
2/5/2014 1:03:08 PM - Добавление файла $filename в каталог

.LINK
Write-VerboseWithTime

.LINK
Write-ErrorWithTime
#>
function Format-DevTestMessageWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )

    return ((Get-Date -Format G)  + ' - ' + $Message)
}


<#

.SYNOPSIS
Записывает сообщение об ошибке с текущим временем в префиксе.

.DESCRIPTION
Записывает сообщение об ошибке с текущим временем в префиксе. Эта функция вызывает функцию Format-DevTestMessageWithTime для добавления времени перед записью сообщения в поток Error.

.PARAMETER  Message
Указывает сообщение в вызове сообщения об ошибке. Строку сообщения можно передать в функцию.

.INPUTS
System.String

.OUTPUTS
Нет. Функция выполняет запись в поток Error.

.EXAMPLE
PS C:> Write-ErrorWithTime -Message "Failed. Cannot find the file."

Write-Error: 2/6/2014 8:37:29 AM - Failed. Cannot find the file.
 + CategoryInfo     : NotSpecified: (:) [Write-Error], WriteErrorException
 + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException

.LINK
Write-Error

#>
function Write-ErrorWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )

    $Message | Format-DevTestMessageWithTime | Write-Error
}


<#
.SYNOPSIS
Записывает подробное сообщение с текущим временем в префиксе.

.DESCRIPTION
Записывает подробное сообщение с текущим временем в префиксе. Поскольку вызывается функция Write-Verbose, сообщение выводится только при выполнении скрипта с параметром Verbose или с заданным для параметра VerbosePreference значением Continue.

.PARAMETER  Message
Указывает сообщение в вызове подробного сообщения. Строку сообщения можно передать в функцию.

.INPUTS
System.String

.OUTPUTS
Нет. Функция выполняет запись в поток Verbose.

.EXAMPLE
PS C:> Write-VerboseWithTime -Message "The operation succeeded."
PS C:>
PS C:\> Write-VerboseWithTime -Message "The operation succeeded." -Verbose
VERBOSE: 1/27/2014 11:02:37 AM - The operation succeeded.

.EXAMPLE
PS C:\ps-test> "The operation succeeded." | Write-VerboseWithTime -Verbose
VERBOSE: 1/27/2014 11:01:38 AM - The operation succeeded.

.LINK
Write-Verbose
#>
function Write-VerboseWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )

    $Message | Format-DevTestMessageWithTime | Write-Verbose
}


<#
.SYNOPSIS
Записывает сообщение узла с текущим временем в префиксе.

.DESCRIPTION
Эта функция записывает в основную программу (Write-Host) сообщение с текущим временем в префиксе. Результат записи в основную программу варьируется. Большинство программ, использующих Windows PowerShell, записывают эти сообщения в стандартный вывод.

.PARAMETER  Message
Указывает базовое сообщение без даты. Строку сообщения можно передать в функцию.

.INPUTS
System.String

.OUTPUTS
Нет. Функция записывает сообщение в основную программу.

.EXAMPLE
PS C:> Write-HostWithTime -Message "Операция выполнена успешно."
1/27/2014 11:02:37 AM - Операция выполнена успешно.

.LINK
Write-Host
#>
function Write-HostWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )
    
    if ((Get-Variable SendHostMessagesToOutput -Scope Global -ErrorAction SilentlyContinue) -and $Global:SendHostMessagesToOutput)
    {
        if (!(Get-Variable -Scope Global AzureWebAppPublishOutput -ErrorAction SilentlyContinue) -or !$Global:AzureWebAppPublishOutput)
        {
            New-Variable -Name AzureWebAppPublishOutput -Value @() -Scope Global -Force
        }

        $Global:AzureWebAppPublishOutput += $Message | Format-DevTestMessageWithTime
    }
    else 
    {
        $Message | Format-DevTestMessageWithTime | Write-Host
    }
}


<#
.SYNOPSIS
Возвращает значение $true, если свойство метода является членом объекта. В противном случае — $false.

.DESCRIPTION
Возвращает $true, если свойство или метод является членом объекта. Эта функция возвращает $false для статических методов класса и для представлений, таких как PSBase и PSObject.

.PARAMETER  Object
Указывает объект в тесте. Введите переменную, которая содержит объект или выражение, возвращающее объект. Указывать типы, такие как [DateTime], или передавать объекты в эту функцию невозможно.

.PARAMETER  Member
Указывает имя свойства или метода в тесте. При указании метода опустите скобки после имени метода.

.INPUTS
Нет. Эта функция не получает входные данные из конвейера.

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\> Test-Member -Object (Get-Date) -Member DayOfWeek
True

.EXAMPLE
PS C:\> $date = Get-Date
PS C:\> Test-Member -Object $date -Member AddDays
True

.EXAMPLE
PS C:\> [DateTime]::IsLeapYear((Get-Date).Year)
True
PS C:\> Test-Member -Object (Get-Date) -Member IsLeapYear
False

.LINK
Get-Member
#>
function Test-Member
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Object]
        $Object,

        [Parameter(Mandatory = $true)]
        [String]
        $Member
    )

    return $null -ne ($Object | Get-Member -Name $Member)
}


<#
.SYNOPSIS
Возвращает $true, если используется модуль Azure версии 0.7.4 или более поздней. Иначе — $false.

.DESCRIPTION
Test-AzureModuleVersion возвращает $true, если используется модуль Azure версии 0.7.4 или более поздней. Если модуль не установлен или имеет более раннюю версию, возвращается значение $false. Эта функция не имеет параметров.

.INPUTS
Нет

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\> Get-Module Azure -ListAvailable
PS C:\> #No module
PS C:\> Test-AzureModuleVersion
False

.EXAMPLE
PS C:\> (Get-Module Azure -ListAvailable).Version

Major  Minor  Build  Revision
-----  -----  -----  --------
0      7      4      -1

PS C:\> Test-AzureModuleVersion
True

.LINK
Get-Module

.LINK
PSModuleInfo object (http://msdn.microsoft.com/en-us/library/system.management.automation.psmoduleinfo(v=vs.85).aspx)
#>
function Test-AzureModuleVersion
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Version]
        $Version
    )

    return ($Version.Major -gt 0) -or ($Version.Minor -gt 7) -or ($Version.Minor -eq 7 -and $Version.Build -ge 4)
}


<#
.SYNOPSIS
Возвращает $true, если установлен модуль Azure версии 0.7.4 или более поздней.

.DESCRIPTION
Test-AzureModule возвращает $true, если установлен модуль Azure версии 0.7.4 или более поздней. Если модуль не установлен или имеет более раннюю версию, возвращается значение $false. Эта функция не имеет параметров.

.INPUTS
Нет

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\> Get-Module Azure -ListAvailable
PS C:\> #No module
PS C:\> Test-AzureModule
False

.EXAMPLE
PS C:\> (Get-Module Azure -ListAvailable).Version

Major  Minor  Build  Revision
-----  -----  -----  --------
    0      7      4      -1

PS C:\> Test-AzureModule
True

.LINK
Get-Module

.LINK
PSModuleInfo object (http://msdn.microsoft.com/en-us/library/system.management.automation.psmoduleinfo(v=vs.85).aspx)
#>
function Test-AzureModule
{
    [CmdletBinding()]

    $module = Get-Module -Name Azure

    if (!$module)
    {
        $module = Get-Module -Name Azure -ListAvailable

        if (!$module -or !(Test-AzureModuleVersion $module.Version))
        {
            return $false;
        }
        else
        {
            $ErrorActionPreference = 'Continue'
            Import-Module -Name Azure -Global -Verbose:$false
            $ErrorActionPreference = 'Stop'

            return $true
        }
    }
    else
    {
        return (Test-AzureModuleVersion $module.Version)
    }
}


<#
.SYNOPSIS
Сохраняет текущую подписку Microsoft Azure в переменной $Script:originalSubscription в области скрипта.

.DESCRIPTION
Функция Backup-Subscription сохраняет в области скрипта текущую подписку Microsoft Azure (Get-AzureSubscription -Current) и ее учетную запись хранения, а также подписку, изменяемую этим скриптом ($UserSpecifiedSubscription, и ее учетную запись хранения. Сохранение этих значений позволяет использовать функцию, такую как Restore-Subscription, для восстановления исходной текущей подписки и учетной записи хранения в текущем статусе в случае изменения текущего статуса.

.PARAMETER UserSpecifiedSubscription
Указывает имя подписки, в которой будут созданы и опубликованы новые ресурсы. Функция сохраняет имена подписки и ее учетных записей хранения в области скрипта. Это обязательный параметр.

.INPUTS
Нет

.OUTPUTS
Нет

.EXAMPLE
PS C:\> Backup-Subscription -UserSpecifiedSubscription Contoso
PS C:\>

.EXAMPLE
PS C:\> Backup-Subscription -UserSpecifiedSubscription Contoso -Verbose
VERBOSE: Backup-Subscription: Start
VERBOSE: Backup-Subscription: Original subscription is Microsoft Azure MSDN - Visual Studio Ultimate
VERBOSE: Backup-Subscription: End
#>
function Backup-Subscription
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $UserSpecifiedSubscription
    )

    Write-VerboseWithTime 'Backup-Subscription: начало'

    $Script:originalCurrentSubscription = Get-AzureSubscription -Current -ErrorAction SilentlyContinue
    if ($Script:originalCurrentSubscription)
    {
        Write-VerboseWithTime ('Backup-Subscription: исходная подписка: ' + $Script:originalCurrentSubscription.SubscriptionName)
        $Script:originalCurrentStorageAccount = $Script:originalCurrentSubscription.CurrentStorageAccountName
    }
    
    $Script:userSpecifiedSubscription = $UserSpecifiedSubscription
    if ($Script:userSpecifiedSubscription)
    {        
        $userSubscription = Get-AzureSubscription -SubscriptionName $Script:userSpecifiedSubscription -ErrorAction SilentlyContinue
        if ($userSubscription)
        {
            $Script:originalStorageAccountOfUserSpecifiedSubscription = $userSubscription.CurrentStorageAccountName
        }        
    }

    Write-VerboseWithTime 'Backup-Subscription: окончание'
}


<#
.SYNOPSIS
Восстанавливает "текущий" статус подписки Microsoft Azure, сохраненную в переменной $Script:originalSubscription в области скрипта.

.DESCRIPTION
Функция Restore-Subscription делает подписку, сохраненную в переменной $Script:originalSubscription, текущей подпиской (повторно). Если исходная подписка имела учетную запись хранения, эта учетная запись становится текущей для текущей подписки. Подписка восстанавливается только при наличии в среде переменной $SubscriptionName с отличным от null значением. В противном случае функция завершается. Если $SubscriptionName заполнено, но $Script:originalSubscription имеет значение $null, Restore-Subscription использует командлет Select-AzureSubscription для очистки параметров Current и Default для подписок в Microsoft Azure PowerShell. Эта функция не имеет параметров, не получает входных данных и ничего не возвращает (void). Можно использовать -Verbose для записи сообщений в поток Verbose.

.INPUTS
Нет

.OUTPUTS
Нет

.EXAMPLE
PS C:\> Restore-Subscription
PS C:\>

.EXAMPLE
PS C:\> Restore-Subscription -Verbose
VERBOSE: Restore-Subscription: Start
VERBOSE: Restore-Subscription: End
#>
function Restore-Subscription
{
    [CmdletBinding()]
    param()

    Write-VerboseWithTime 'Restore-Subscription: начало'

    if ($Script:originalCurrentSubscription)
    {
        if ($Script:originalCurrentStorageAccount)
        {
            Set-AzureSubscription `
                -SubscriptionName $Script:originalCurrentSubscription.SubscriptionName `
                -CurrentStorageAccountName $Script:originalCurrentStorageAccount
        }

        Select-AzureSubscription -SubscriptionName $Script:originalCurrentSubscription.SubscriptionName
    }
    else 
    {
        Select-AzureSubscription -NoCurrent
        Select-AzureSubscription -NoDefault
    }
    
    if ($Script:userSpecifiedSubscription -and $Script:originalStorageAccountOfUserSpecifiedSubscription)
    {
        Set-AzureSubscription `
            -SubscriptionName $Script:userSpecifiedSubscription `
            -CurrentStorageAccountName $Script:originalStorageAccountOfUserSpecifiedSubscription
    }

    Write-VerboseWithTime 'Restore-Subscription: окончание'
}


<#
.SYNOPSIS
Проверяет файл конфигурации и возвращает хэш-таблицу значений файла конфигурации.

.DESCRIPTION
Функция Read-ConfigFile проверяет JSON-файл конфигурации и возвращает хэш-таблицу выбранных значений.
-- В первую очередь JSON-файл преобразуется в объект PSCustomObject. Хэш-таблица веб-сайта имеет следующие ключи:
-- Location: Расположение веб-сайта
-- Databases: Базы данных SQL веб-сайта

.PARAMETER  ConfigurationFile
Указывает путь и имя JSON-файла конфигурации для веб-проекта. Visual Studio автоматически создает JSON-файл конфигурации при создании веб-проекта и хранит его в папке PublishScripts вашего решения.

.PARAMETER HasWebDeployPackage
Обозначает наличие ZIP-файла пакета веб-развертывания для веб-приложения. Чтобы задать значение $true, используйте синтаксис -HasWebDeployPackage или HasWebDeployPackage:$true. Чтобы задать значение false, используйте синтаксис HasWebDeployPackage:$false. Это обязательный параметр.

.INPUTS
Нет. В эту функцию невозможно передать входные данные.

.OUTPUTS
System.Collections.Hashtable

.EXAMPLE
PS C:\> Read-ConfigFile -ConfigurationFile <path> -HasWebDeployPackage


Name                           Value                                                                                                                                                                     
----                           -----                                                                                                                                                                     
databases                      {@{connectionStringName=; databaseName=; serverName=; user=; password=}}                                                                                                  
website                        @{name="mysite"; location="West US";}                                                      
#>
function Read-ConfigFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [String]
        $ConfigurationFile
    )

    Write-VerboseWithTime 'Read-ConfigFile: начало'

    # Получение содержимого JSON-файла (-raw игнорирует разрывы строк) и его преобразование в PSCustomObject
    $config = Get-Content $ConfigurationFile -Raw | ConvertFrom-Json

    if (!$config)
    {
        throw ('Read-ConfigFile: сбой ConvertFrom-Json: ' + $error[0])
    }

    # Определите, есть ли у объекта environmentSettings свойства webSite (независимо от значения свойства)
    $hasWebsiteProperty =  Test-Member -Object $config.environmentSettings -Member 'webSite'

    if (!$hasWebsiteProperty)
    {
        throw 'Read-ConfigFile: файл конфигурации не имеет свойства webSite.'
    }

    # Построение хэш-таблицы из значений PSCustomObject
    $returnObject = New-Object -TypeName Hashtable

    $returnObject.Add('name', $config.environmentSettings.webSite.name)
    $returnObject.Add('location', $config.environmentSettings.webSite.location)

    if (Test-Member -Object $config.environmentSettings -Member 'databases')
    {
        $returnObject.Add('databases', $config.environmentSettings.databases)
    }

    Write-VerboseWithTime 'Read-ConfigFile: окончание'

    return $returnObject
}


<#
.SYNOPSIS
Создает веб-сайт Microsoft Azure.

.DESCRIPTION
Создает веб-сайт Microsoft Azure с определенным именем и расположением. Эта функция вызывает командлет New-AzureWebsite в модуле Azure. Если у подписки еще нет веб-сайта с указанным именем, эта функция создает веб-сайт и возвращает объект веб-сайта. В противном случае она возвращает существующий веб-сайт.

.PARAMETER  Name
Указывает имя для нового веб-сайта. Имя виртуальной машины должно быть уникальным в Microsoft Azure. Это обязательный параметр.

.PARAMETER  Location
Указывает расположение веб-сайта. Допустимыми значениями являются расположения Microsoft Azure, такие как "West US". Это обязательный параметр.

.INPUTS
НЕТ.

.OUTPUTS
Microsoft.WindowsAzure.Commands.Utilities.Websites.Services.WebEntities.Site

.EXAMPLE
Add-AzureWebsite -Name TestSite -Location "West US"

Name       : contoso
State      : Running
Host Names : contoso.azurewebsites.net

.LINK
New-AzureWebsite
#>
function Add-AzureWebsite
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [String]
        $Location
    )

    Write-VerboseWithTime 'Add-AzureWebsite: начало'
    $website = Get-AzureWebsite -Name $Name -ErrorAction SilentlyContinue

    if ($website)
    {
        Write-HostWithTime ('Add-AzureWebsite: существующий веб-сайт ' +
        $website.Name + ' найден')
    }
    else
    {
        if (Test-AzureName -Website -Name $Name)
        {
            Write-ErrorWithTime ('Веб-сайт {0} уже существует' -f $Name)
        }
        else
        {
            $website = New-AzureWebsite -Name $Name -Location $Location
        }
    }

    $website | Out-String | Write-VerboseWithTime
    Write-VerboseWithTime 'Add-AzureWebsite: окончание'

    return $website
}

<#
.SYNOPSIS
Возвращает значение $True, если URL-адрес является абсолютным и использует схему https.

.DESCRIPTION
Функция Test-HttpsUrl преобразует входной URL-адрес в объект System.Uri. Возвращает значение $True, если URL-адрес является абсолютным (не относительным) и использует схему https. Если любое из этих условий не выполняется или входную строку невозможно преобразовать в URL-адрес, функция возвращает $false.

.PARAMETER Url
Указывает URL-адрес для тестирования. Введите строку URL-адреса

.INPUTS
НЕТ.

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\>$profile.publishUrl
waws-prod-bay-001.publish.azurewebsites.windows.net:443

PS C:\>Test-HttpsUrl -Url 'waws-prod-bay-001.publish.azurewebsites.windows.net:443'
False
#>
function Test-HttpsUrl
{

    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Url
    )

    # Если $uri невозможно преобразовать в объект System.Uri, Test-HttpsUrl возвращает $false
    $uri = $Url -as [System.Uri]

    return $uri.IsAbsoluteUri -and $uri.Scheme -eq 'https'
}


<#
.SYNOPSIS
Создает строку, которая позволяет подключиться к базе данных SQL Microsoft Azure.

.DESCRIPTION
Функция Get-AzureSQLDatabaseConnectionString выполняет сборку строки подключения для подключения к базе данных SQL Microsoft Azure.

.PARAMETER  DatabaseServerName
Указывает имя существующего сервера баз данных в подписке Microsoft Azure. Все базы данных SQL Microsoft Azure должны быть связаны с сервером баз данных SQL. Для получения имени сервера используйте командлет Get-AzureSqlDatabaseServer (модуль Azure). Это обязательный параметр.

.PARAMETER  DatabaseName
Указывает имя для базы данных SQL. Это может быть существующая база данных SQL или имя, используемое для новой базы данных SQL. Это обязательный параметр.

.PARAMETER  Username
Указывает имя пользователя администратора базы данных SQL. Имя пользователя имеет вид $Username@DatabaseServerName. Это обязательный параметр.

.PARAMETER  Password
Указывает пароль для администратора базы данных SQL. Введите пароль в виде обычного текста. Защищенные строки запрещены. Это обязательный параметр.

.INPUTS
Нет.

.OUTPUTS
System.String

.EXAMPLE
PS C:\> $ServerName = (Get-AzureSqlDatabaseServer).ServerName[0]
PS C:\> Get-AzureSQLDatabaseConnectionString -DatabaseServerName $ServerName `
        -DatabaseName 'testdb' -UserName 'admin'  -Password 'password'

Server=tcp:testserver.database.windows.net,1433;Database=testdb;User ID=admin@testserver;Password=password;Trusted_Connection=False;Encrypt=True;Connection Timeout=20;
#>
function Get-AzureSQLDatabaseConnectionString
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $DatabaseServerName,

        [Parameter(Mandatory = $true)]
        [String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [String]
        $UserName,

        [Parameter(Mandatory = $true)]
        [String]
        $Password
    )

    return ('Server=tcp:{0}.database.windows.net,1433;Database={1};' +
           'User ID={2}@{0};' +
           'Password={3};' +
           'Trusted_Connection=False;' +
           'Encrypt=True;' +
           'Connection Timeout=20;') `
           -f $DatabaseServerName, $DatabaseName, $UserName, $Password
}


<#
.SYNOPSIS
Создает базы данных SQL Microsoft Azure из значений в создаваемом Visual Studio JSON-файле конфигурации.

.DESCRIPTION
Функция Add-AzureSQLDatabases получает информацию из раздела databases JSON-файла. Эта функция, Add-AzureSQLDatabases (мн. ч.), вызывает функцию Add-AzureSQLDatabase (ед. ч.) для каждой базы данных в JSON-файле. Add-AzureSQLDatabase (ед. ч.) вызывает командлет New-AzureSqlDatabase (модуль Azure), который создает базы данных. Эта функция не возвращает объект базы данных. Она возвращает хэш-таблицу значений, использовавшихся для создания баз данных.

.PARAMETER DatabaseConfig
 Принимает массив объектов PSCustomObjects, источником которых является JSON-файл, возвращаемый функцией Read-ConfigFile при наличии у JSON-файла свойства веб-сайта. Включает свойства environmentSettings.databases. Список можно передать в эту функцию.
PS C:\> $config = Read-ConfigFile <name>.json
PS C:\> $DatabaseConfig = $config.databases| where {$_.connectionStringName}
PS C:\> $DatabaseConfig
connectionStringName: Default Connection
databasename : TestDB1
edition   :
size     : 1
collation  : SQL_Latin1_General_CP1_CI_AS
servertype  : New SQL Database Server
servername  : r040tvt2gx
user     : dbuser
password   : Test.123
location   : West US

.PARAMETER  DatabaseServerPassword
Указывает пароль для администратора сервера баз данных SQL. Введите хэш-таблицу с ключами Name и Password. Значение Name является именем сервера баз данных. Значение Password является паролем администратора. Например: @Name = "TestDB1"; Password = "password" Это необязательный параметр. Если он не указан или имя сервера баз данных не совпадает со значением свойства serverName объекта $DatabaseConfig, функция использует свойство Password объекта $DatabaseConfig для базы данных SQL в строке подключения.

.PARAMETER CreateDatabase
Проверяет необходимость создания базы данных. Это необязательный параметр.

.INPUTS
System.Collections.Hashtable[]

.OUTPUTS
System.Collections.Hashtable

.EXAMPLE
PS C:\> $config = Read-ConfigFile <name>.json
PS C:\> $DatabaseConfig = $config.databases| where {$_.connectionStringName}
PS C:\> $DatabaseConfig | Add-AzureSQLDatabases

Name                           Value
----                           -----
ConnectionString               Server=tcp:testdb1.database.windows.net,1433;Database=testdb;User ID=admin@testdb1;Password=password;Trusted_Connection=False;Encrypt=True;Connection Timeout=20;
Name                           Default Connection
Type                           SQLAzure

.LINK
Get-AzureSQLDatabaseConnectionString

.LINK
Create-AzureSQLDatabase
#>
function Add-AzureSQLDatabases
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]
        $DatabaseConfig,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Hashtable[]]
        $DatabaseServerPassword,

        [Parameter(Mandatory = $false)]
        [Switch]
        $CreateDatabase = $false
    )

    begin
    {
        Write-VerboseWithTime 'Add-AzureSQLDatabases: начало'
    }
    process
    {
        Write-VerboseWithTime ('Add-AzureSQLDatabases: создание ' + $DatabaseConfig.databaseName)

        if ($CreateDatabase)
        {
            # Создает новую базу данных SQL со значениями DatabaseConfig (если такой БД еще не существует)
            # Выходной поток команды подавлен.
            Add-AzureSQLDatabase -DatabaseConfig $DatabaseConfig | Out-Null
        }

        $serverPassword = $null
        if ($DatabaseServerPassword)
        {
            foreach ($credential in $DatabaseServerPassword)
            {
               if ($credential.Name -eq $DatabaseConfig.serverName)
               {
                   $serverPassword = $credential.password             
                   break
               }
            }               
        }

        if (!$serverPassword)
        {
            $serverPassword = $DatabaseConfig.password
        }

        return @{
            Name = $DatabaseConfig.connectionStringName;
            Type = 'SQLAzure';
            ConnectionString = Get-AzureSQLDatabaseConnectionString `
                -DatabaseServerName $DatabaseConfig.serverName `
                -DatabaseName $DatabaseConfig.databaseName `
                -UserName $DatabaseConfig.user `
                -Password $serverPassword }
    }
    end
    {
        Write-VerboseWithTime 'Add-AzureSQLDatabases: окончание'
    }
}


<#
.SYNOPSIS
Создает новую базу данных SQL Microsoft Azure.

.DESCRIPTION
Функция Add-AzureSQLDatabase создает базу данных SQL Microsoft Azure из данных в JSON-файле конфигурации, создаваемом Visual Studio, и возвращает эту новую базу данных. Если у подписки уже есть база данных SQL с указанным именем базы данных на указанном сервере баз данных SQL, функция возвращает существующую базу данных. Эта функция вызывает командлет New-AzureSqlDatabase (модуль Azure), который фактически создает базу данных SQL.

.PARAMETER DatabaseConfig
Принимает объект PSCustomObject, источником которого является JSON-файл конфигурации, возвращаемый функцией Read-ConfigFile при наличии у JSON-файла свойства веб-сайта. Включает свойства environmentSettings.databases. Передать объект в эту функцию невозможно. Visual Studio создает JSON-файл конфигурации для всех веб-проектов и хранит его в папке PublishScripts вашего решения.

.INPUTS
Нет. Эта функция не получает входные данные из конвейера

.OUTPUTS
Microsoft.WindowsAzure.Commands.SqlDatabase.Services.Server.Database

.EXAMPLE
PS C:\> $config = Read-ConfigFile <name>.json
PS C:\> $DatabaseConfig = $config.databases | where connectionStringName
PS C:\> $DatabaseConfig

connectionStringName    : Default Connection
databasename : TestDB1
edition      :
size         : 1
collation    : SQL_Latin1_General_CP1_CI_AS
servertype   : New SQL Database Server
servername   : r040tvt2gx
user         : dbuser
password     : Test.123
location     : West US

PS C:\> Add-AzureSQLDatabase -DatabaseConfig $DatabaseConfig

.LINK
Add-AzureSQLDatabases

.LINK
New-AzureSQLDatabase
#>
function Add-AzureSQLDatabase
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [Object]
        $DatabaseConfig
    )

    Write-VerboseWithTime 'Add-AzureSQLDatabase: начало'

    # Сбой, если у значения параметра нет свойства serverName или если значение свойства serverName не заполнено.
    if (-not (Test-Member $DatabaseConfig 'serverName') -or -not $DatabaseConfig.serverName)
    {
        throw 'Add-AzureSQLDatabase: имя сервера баз данных (обязательно) отсутствует в значении DatabaseConfig.'
    }

    # Сбой, если у значения параметра нет свойства databasename или если значение свойства databasename не заполнено.
    if (-not (Test-Member $DatabaseConfig 'databaseName') -or -not $DatabaseConfig.databaseName)
    {
        throw 'Add-AzureSQLDatabase: имя базы данных (обязательно) отсутствует в значении DatabaseConfig.'
    }

    $DbServer = $null

    if (Test-HttpsUrl $DatabaseConfig.serverName)
    {
        $absoluteDbServer = $DatabaseConfig.serverName -as [System.Uri]
        $subscription = Get-AzureSubscription -Current -ErrorAction SilentlyContinue

        if ($subscription -and $subscription.ServiceEndpoint -and $subscription.SubscriptionId)
        {
            $absoluteDbServerRegex = 'https:\/\/{0}\/{1}\/services\/sqlservers\/servers\/(.+)\.database\.windows\.net\/databases' -f `
                                     $subscription.serviceEndpoint.Host, $subscription.SubscriptionId

            if ($absoluteDbServer -match $absoluteDbServerRegex -and $Matches.Count -eq 2)
            {
                 $DbServer = $Matches[1]
            }
        }
    }

    if (!$DbServer)
    {
        $DbServer = $DatabaseConfig.serverName
    }

    $db = Get-AzureSqlDatabase -ServerName $DbServer -DatabaseName $DatabaseConfig.databaseName -ErrorAction SilentlyContinue

    if ($db)
    {
        Write-HostWithTime ('Create-AzureSQLDatabase: использование существующей базы данных ' + $db.Name)
        $db | Out-String | Write-VerboseWithTime
    }
    else
    {
        $param = New-Object -TypeName Hashtable
        $param.Add('serverName', $DbServer)
        $param.Add('databaseName', $DatabaseConfig.databaseName)

        if ((Test-Member $DatabaseConfig 'size') -and $DatabaseConfig.size)
        {
            $param.Add('MaxSizeGB', $DatabaseConfig.size)
        }
        else
        {
            $param.Add('MaxSizeGB', 1)
        }

        # Если у объекта $DatabaseConfig есть свойство collation с непустым и отличным от NULL значением
        if ((Test-Member $DatabaseConfig 'collation') -and $DatabaseConfig.collation)
        {
            $param.Add('Collation', $DatabaseConfig.collation)
        }

        # Если у объекта $DatabaseConfig есть свойство edition с непустым и отличным от NULL значением
        if ((Test-Member $DatabaseConfig 'edition') -and $DatabaseConfig.edition)
        {
            $param.Add('Edition', $DatabaseConfig.edition)
        }

        # Запись хэш-таблицы в подробный поток
        $param | Out-String | Write-VerboseWithTime
        # Вызов New-AzureSqlDatabase со сплаттингом (выходной поток подавляется)
        $db = New-AzureSqlDatabase @param
    }

    Write-VerboseWithTime 'Add-AzureSQLDatabase: окончание'
    return $db
}
