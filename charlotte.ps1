param($path = "", $workspace = "")
Add-Type -AssemblyName "System.IO"

#.projectファイルを読み込みます。
function loadEclipcePrj ($dirPath) {
    #ワークスペースかルートディレクトリまで来たら、探索打ち切り
    if ($dirPath -eq $workspace -or $dirPath.Length -eq 0) {
        throw ".project not exist"
    }
    Write-Debug $dirPath
    if ( [System.IO.File]::Exists($dirPath + "/.project")) {
        #projectファイルから必要な情報を取得する。
        $project = [xml](gc -raw -Encoding Default $dirPath"/.project")
        $name = $project.projectDescription.name
        $library = $project.projectDescription.projects.project
        New-Object PSObject -Property @{name = ${name}; library = ${library}; workspace = $dirPath}
    }
    else {
        #.projectファイルが無い場合、再帰的に呼び出す。 
        loadEclipcePrj ([System.IO.Path]::GetDirectoryName($dirPath))
    }
}


if ($path.Length -eq 0) {
    Throw "No specified Target path."
}
Write-Output "Chalotte 0.1`r`n"
#入力パスがファイルの場合、そのディレクトリを取得する
$FileAttribute = [System.IO.File]::GetAttributes($path)
$directoryAttribute = [System.IO.FileAttributes]
if ($FileAttribute -match $directoryAttribute) {
    $path = [System.IO.Path]::GetDirectoryName($path)
} 
try {
    $result = loadEclipcePrj $path
    $name = $result.name
    $library = $result.library
    $workSpace = $result.workspace
    $buildTaskPath = "${workspace}\buildTask.ps1"
    if ([System.IO.File]::Exists( $buildTaskPath)) {
        Write-Output ":start ${buildTaskPath}"
        $time = Measure-Command{
            .${buildTaskPath}
        }
        Write-Output "`r`n"
        if ($?){
            Write-Output "BUILD TASK SUCCESSFUL`r`n"
        }else{
            throw "BUILD TASK FAILURE`r`n"
        }
        Write-Output "Total Time$($time.TotalSeconds) secs"
    }
}
catch {
    Write-Error $_
    Write-Output "BUILD TASK FAILURE`r`n" 
    return -1   
}