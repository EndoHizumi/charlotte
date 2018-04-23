param($path = "", $workspace = "")
Add-Type -AssemblyName "System.IO"

#.projectファイルを読み込みます。
function loadEclipcePrj ($dirPath) {
    #ワークスペースかルートディレクトリまで来たら、探索打ち切り
    if ($dirPath -eq $workspace -or $dirPath.Length -eq 0) {
        write-error ".project not exist"
        return
    }
    Write-Debug $dirPath
    if ( [System.IO.File]::Exists($dirPath + "/.project")) {
        #projectファイルから必要な情報を取得する。
        $project = [xml](gc -raw -Encoding Default $dirPath"/.project")
        $name = $project.projectDescription.name
        $library = $project.projectDescription.projects.project
        New-Object PSObject -Property @{name = ${name}; library = ${library}; projectDir = $dirPath}
    }
    else {
        #.projectファイルが無い場合、再帰的に呼び出す。 
        loadEclipcePrj ([System.IO.Path]::GetDirectoryName($dirPath))
    }
}


if ($path.Length -eq 0) {
    $path = (Get-Location).Path
}
Write-Output "Chalotte 0.2`r`n"
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
    $projectDir = $result.projectDir
    $buildTaskPath = "${projectDir}\buildTask.ps1"
    $exitCode = 0
    if ([System.IO.File]::Exists( $buildTaskPath)) {
        Write-Output ":start ${buildTaskPath}"

        $time = Measure-Command {
            try {
                .$buildTaskPath | Out-Default
            }
            catch {
                write-error $Error[0].Exception
                $script:exitCode = 1 
            }
        }
        Write-Output "`r`n"       
    }else{
        Write-Error "buildTask not exist."
    }
}
catch {
    Write-Error "charlotte inner Error:" $_.Exception
    $exitCode = 1 
}
finally {
    if ($exitCode -eq 0) {
        Write-Output "BUILD TASK SUCCESSFUL"
    }
    else {
        Write-Output "BUILD TASK FAILURE"
    }
    Write-Output "Total Time $($time.TotalSeconds) secs"
}