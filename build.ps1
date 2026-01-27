# Usage: .\build.ps1 [-Registry <registry>] [-ImageTag "latest"] [-Platforms "linux/amd64,linux/arm64"] [-Push] [-NoRun]
# local build and run: .\build.ps1
# local build only: .\build.ps1 -NoRun
# local build with custom name: .\build.ps1 -Registry "myapp" -ImageTag "dev"
# push to registry: .\build.ps1 -Registry "docker.io/myuser/presshost" -ImageTag "v1.0" -Push

param(
    [string]$Registry = "presshost",
    [string]$ImageTag = "latest",
    [string]$Platforms = "",
    [switch]$Push = $false,
    [switch]$NoRun = $false
)

$Run = -not $NoRun

$ImageName = $Registry
$BuilderName = "presshost-builder"

$ErrorActionPreference = "Stop"

$IsRemoteRegistry = $Registry -match '[/\.]'

if ([string]::IsNullOrEmpty($Platforms)) {
    if ($Push -or $IsRemoteRegistry) {
        $Platforms = "linux/amd64,linux/arm64"
    } else {
        $arch = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "386" }
        $Platforms = "linux/$arch"
    }
}

if ($IsRemoteRegistry -and -not $PSBoundParameters.ContainsKey('Push')) {
    $Push = $true
}

Write-Host "========================================" -ForegroundColor Green
Write-Host " PressHost Docker Build" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Image: " -NoNewline
Write-Host "${ImageName}:${ImageTag}" -ForegroundColor Yellow
Write-Host "Platforms: " -NoNewline
Write-Host "${Platforms}" -ForegroundColor Yellow
Write-Host "Mode: " -NoNewline
if ($Push) {
    Write-Host "Push to Registry" -ForegroundColor Yellow
} else {
    Write-Host "Local Build" -ForegroundColor Yellow
}
Write-Host ""

try {
    $null = Get-Command docker -ErrorAction Stop
} catch {
    Write-Host "ERROR: Docker is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

try {
    docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker daemon not running"
    }
} catch {
    Write-Host "ERROR: Docker daemon is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

$builderExists = docker buildx inspect $BuilderName 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating buildx builder '${BuilderName}'..." -ForegroundColor Green
    docker buildx create --name $BuilderName --driver docker-container --bootstrap
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to create buildx builder" -ForegroundColor Red
        exit 1
    }
}

docker buildx use $BuilderName
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to use buildx builder" -ForegroundColor Red
    exit 1
}

Write-Host "Building Docker image for platforms: ${Platforms}..." -ForegroundColor Green
Write-Host ""

if ($Push) {
    docker buildx build `
        --platform "${Platforms}" `
        -t "${ImageName}:${ImageTag}" `
        -f Dockerfile `
        --push `
        .
    
    $BuildExitCode = $LASTEXITCODE
    
    if ($BuildExitCode -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host " Build & Push Successful!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Image: " -NoNewline
        Write-Host "${ImageName}:${ImageTag}" -ForegroundColor Yellow
        Write-Host "Platforms: " -NoNewline
        Write-Host "${Platforms}" -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host " Build & Push Failed!" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        exit $BuildExitCode
    }
} else {
    docker buildx build `
        --platform "${Platforms}" `
        -t "${ImageName}:${ImageTag}" `
        -f Dockerfile `
        --load `
        .
    
    $BuildExitCode = $LASTEXITCODE
    
    if ($BuildExitCode -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host " Build Successful!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Image: " -NoNewline
        Write-Host "${ImageName}:${ImageTag}" -ForegroundColor Yellow
        Write-Host "Platforms: " -NoNewline
        Write-Host "${Platforms}" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Note: Image loaded to local Docker daemon." -ForegroundColor Yellow
        Write-Host "Use -Push to push to a registry, or specify a remote registry." -ForegroundColor Yellow
        
        if ($Run) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host " Starting Container..." -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
            Write-Host ""
            
            $ContainerName = "presshost-dev"
            
            $existingContainer = docker ps -aq -f name=$ContainerName 2>&1
            if ($existingContainer) {
                Write-Host "Stopping existing container '${ContainerName}'..." -ForegroundColor Yellow
                docker stop $ContainerName 2>&1 | Out-Null
                docker rm $ContainerName 2>&1 | Out-Null
            }
            
            Write-Host "Starting container '${ContainerName}'..." -ForegroundColor Green
            docker run -d `
                --name $ContainerName `
                -p 8080:80 `
                -p 8443:443 `
                -e SITE_URL=localhost `
                -e DB_HOST=host.docker.internal `
                -e DB_NAME=presshost `
                -e DB_USER=presshost `
                -e DB_PASSWORD=presshost `
                "${ImageName}:${ImageTag}"
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host ""
                Write-Host "========================================" -ForegroundColor Green
                Write-Host " Container Started!" -ForegroundColor Green
                Write-Host "========================================" -ForegroundColor Green
                Write-Host ""
                Write-Host "Container: " -NoNewline
                Write-Host "${ContainerName}" -ForegroundColor Yellow
                Write-Host "HTTP: " -NoNewline
                Write-Host "http://localhost:8080" -ForegroundColor Yellow
                Write-Host "HTTPS: " -NoNewline
                Write-Host "https://localhost:8443" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Commands:" -ForegroundColor Green
                Write-Host "  Logs: docker logs -f ${ContainerName}" -ForegroundColor Yellow
                Write-Host "  Shell: docker exec -it ${ContainerName} bash" -ForegroundColor Yellow
                Write-Host "  Stop: docker stop ${ContainerName}" -ForegroundColor Yellow
            } else {
                Write-Host ""
                Write-Host "========================================" -ForegroundColor Red
                Write-Host " Failed to start container!" -ForegroundColor Red
                Write-Host "========================================" -ForegroundColor Red
                exit 1
            }
        }
    } else {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host " Build Failed!" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        exit $BuildExitCode
    }
}