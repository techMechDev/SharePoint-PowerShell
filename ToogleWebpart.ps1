function List-Pages {
    param (
        $Pages, [string]$Path, [string]$WebPartTitle, [string]$NewWebPart, [string]$File
    )

    Foreach($page in $Pages | Where-Object {$_.FieldValues["FileLeafRef"].EndsWith(".aspx") -eq $true}) {
        $pageName= $page.FieldValues["FileLeafRef"]
        $pg= Get-PnPClientSidePage -Identity $pageName
        $WebParts= $pg.Controls

        Foreach($WebPart in $WebParts | Where-Object {$_.Title -eq $WebPartTitle}) {
            $WPInstID= $WebPart.InstanceId
            $WpPJ= $Webpart.PropertiesJson
            $WpJ= ConvertFrom-Json -InputObject $WpPJ
            if ($WpJ.ConfigType -eq "Auto") {
                Remove-PnPPageComponent -Page $pageName -InstanceId $WPInstID -Force
                $webPartProperties = @{
                    "ConfigType" = "Auto"
                }
                Add-PnPPageWebPart -Page $pageName -Component $NewWebPart -Section 1 -Column 1 -Order 0 -WebPartProperties $webPartProperties
                $log = "..."
                
            }else {
                Remove-PnPPageComponent -Page $pageName -InstanceId $WPInstID -Force
                Add-PnPPageWebPart -Page $pageName -Component $NewWebPart -Section 1 -Column 1 -Order 0 -WebPartProperties $WpPJ
                $log = "..."
            }
            Add-Content -Value $log -Path $File
            break
        }
    }
    $log = "salida"
    Add-Content -Value $log -Path $File
}

# Titulo del webpart a buscar
$oldWebpart = "Webpart-Antiguo"

# Titulo del webpart con el que se va a sustituir
$newWebpart = "Webpart-Nuevo"

# Sitios en los que buscar
$sites = "sitio1","sitio2","sitio3"

$domain = "https://midominio.sharepoint.com"

Foreach ($site in $sites) {
    $siteUrl = $domain + "/sites/" + $site
    $file = ".\" + $site + ".txt"

    Connect-PnPOnline -Url $siteUrl -Interactive
    $pages= Get-PnPListItem -List sitepages -IncludeContentType

    Set-Content -Value "inicio de log" -Path $file
    List-Pages -Pages $pages -Path $siteUrl -WebPartTitle $oldWebpart -NewWebPart $newWebpart -File $file

    $siteCollections = Get-PnPSubWeb

    Foreach($siteCollection in $siteCollections) {
        $subSiteUrl = $domain + $siteCollection.ServerRelativeUrl
        Connect-PnPOnline -Url $subSiteUrl -Interactive
        $subSitePages = Get-PnPListItem -List sitepages -FolderServerRelativeUrl $siteCollection.ServerRelativeUrl

        $log = "sub-sitio: " + $siteCollection.Title
        Add-Content -Value $log -Path $file
        Write-Host $log

        List-Pages -Pages $subSitePages -Path $subSiteUrl -WebPartTitle $oldWebpart -NewWebPart $newWebpart -File $file
    }

    Add-Content -Value "fin" -Path $file
}