param([string]$ObsRoot = "$env:ProgramFiles\obs-studio")
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function Run([string]$exe, [string[]]$arguments) {
    & $exe @arguments
    if ($LASTEXITCODE -ne 0) { throw "$exe failed: $LASTEXITCODE" }
}
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vs = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (!$vs) { throw 'Install Visual Studio 2022 C++ desktop tools and Windows SDK.' }
$toolVersion = (Get-Content "$vs\VC\Auxiliary\Build\Microsoft.VCToolsVersion.default.txt").Trim()
$tools = "$vs\VC\Tools\MSVC\$toolVersion\bin\Hostx64\x64"
$deps = Join-Path $root deps
$build = Join-Path $root build
$imports = Join-Path $build imports
New-Item -ItemType Directory -Force $deps,$imports | Out-Null
foreach ($item in @(
    @('obs', 'https://github.com/obsproject/obs-studio.git', '65c320b46e1af5c7a555161aea6182cdf7a8c524'),
    @('vpl', 'https://github.com/intel/libvpl.git', '412c5cffe3022d5ebb8a955c3b30afe7bd2e3929')
)) {
    $dest = Join-Path $deps $item[0]
    if (!(Test-Path "$dest\.git")) { Run git -arguments @('clone','--no-checkout',$item[1],$dest) }
    Run git -arguments @('-C',$dest,'fetch','--depth=1','origin',$item[2])
    Run git -arguments @('-C',$dest,'checkout','--detach',$item[2])
}
foreach ($name in @('obs','w32-pthreads')) {
    $dll = Join-Path $ObsRoot "bin\64bit\$name.dll"
    if (!(Test-Path $dll)) { throw "Missing OBS runtime: $dll" }
    $exports = & "$tools\dumpbin.exe" /exports $dll
    if ($LASTEXITCODE -ne 0) { throw 'dumpbin failed' }
    $symbols = @($exports | ForEach-Object { if ($_ -match '^\s+\d+\s+[0-9A-F]+\s+[0-9A-F]+\s+(\S+)') { $Matches[1] } })
    if (!$symbols.Count) { throw "No exports in $dll" }
    $def = Join-Path $imports "$name.def"
    @("LIBRARY $name",'EXPORTS') + $symbols | Set-Content -Encoding ascii $def
    Run "$tools\lib.exe" -arguments @("/def:$def",'/machine:x64',"/out:$imports\$name.lib")
}
Run cmake -arguments @('-S',"$deps\vpl",'-B',"$build\vpl",'-G','Visual Studio 17 2022','-A','x64','-DBUILD_SHARED_LIBS=OFF','-DBUILD_TESTS=OFF','-DBUILD_EXAMPLES=OFF','-DINSTALL_EXAMPLES=OFF')
Run cmake -arguments @('--build',"$build\vpl",'--config','Release')
Run cmake -arguments @('-S',$root,'-B',"$build\plugin",'-G','Visual Studio 17 2022','-A','x64',"-DOBS_SOURCE=$deps/obs","-DVPL_SOURCE=$deps/vpl","-DVPL_LIBRARY=$build/vpl/Release/vpl.lib","-DIMPORT_DIR=$imports")
Run cmake -arguments @('--build',"$build\plugin",'--config','Release')
$dist = Join-Path $root dist
New-Item -ItemType Directory -Force "$dist\obs-plugins\64bit","$dist\data\obs-plugins\obs-qsv-lowpower" | Out-Null
Copy-Item "$build\plugin\Release\obs-qsv-lowpower.dll" "$dist\obs-plugins\64bit" -Force
Copy-Item "$root\src\data\locale" "$dist\data\obs-plugins\obs-qsv-lowpower" -Recurse -Force
Copy-Item "$root\LICENSE","$root\README.md" $dist -Force
Copy-Item "$root\licenses" $dist -Recurse -Force
Get-FileHash "$dist\obs-plugins\64bit\obs-qsv-lowpower.dll" -Algorithm SHA256
Write-Host "Build ready: $dist (not installed automatically)"
