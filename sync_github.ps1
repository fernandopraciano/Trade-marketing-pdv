# Script de Sincronizacao Automatica com o GitHub
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "TVLar Trade Marketing - Sincronizacao GitHub"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "           TVLAR TRADE MARKETING - SINCRONIZADOR GITHUB             " -ForegroundColor Yellow
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Localizar o Git
$gitCmd = $null
if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitCmd = "git"
} elseif (Test-Path "C:\Users\Israel.fernando\.gemini\antigravity\scratch\tools\git\cmd\git.exe") {
    $gitCmd = "C:\Users\Israel.fernando\.gemini\antigravity\scratch\tools\git\cmd\git.exe"
} elseif (Test-Path "C:\Program Files\Git\cmd\git.exe") {
    $gitCmd = "C:\Program Files\Git\cmd\git.exe"
} elseif (Test-Path "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe") {
    $gitCmd = "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe"
}

if (-not $gitCmd) {
    Write-Host "[ERRO] Git nao encontrado no sistema!" -ForegroundColor Red
    Write-Host "Certifique-se de que o Git esteja instalado." -ForegroundColor Yellow
    exit 1
}

Write-Host "[1/5] Git localizado em: $gitCmd" -ForegroundColor Gray

# 2. Verificar se o repositorio foi inicializado
if (-not (Test-Path ".git")) {
    Write-Host "[INFO] Inicializando repositorio Git local..." -ForegroundColor Cyan
    & $gitCmd init
    & $gitCmd branch -M main
}

# 3. Configurar usuario Git caso nao esteja definido
$currentName = & $gitCmd config user.name
if (-not $currentName) {
    & $gitCmd config user.name "Israel Fernando"
    & $gitCmd config user.email "israel.fernando@tvlar.com.br"
}

# 4. Verificar ou solicitar repositorio remoto do GitHub
$remoteUrl = & $gitCmd remote get-url origin 2>$null
if (-not $remoteUrl) {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor Yellow
    Write-Host " PRIMEIRA VEZ: VINCULACAO COM O GITHUB                              " -ForegroundColor Yellow
    Write-Host "=====================================================================" -ForegroundColor Yellow
    Write-Host "Nenhum repositorio remoto vinculado ainda." -ForegroundColor White
    Write-Host "Crie um repositorio no GitHub (https://github.com/new) e cole a URL abaixo." -ForegroundColor Gray
    Write-Host "Exemplo: https://github.com/seu-usuario/trade-marketing-tvlar.git" -ForegroundColor Gray
    Write-Host ""
    $inputUrl = Read-Host "Digite ou cole a URL do seu repositorio no GitHub"
    if ($inputUrl) {
        $inputUrl = $inputUrl.Trim()
        & $gitCmd remote add origin $inputUrl
        $remoteUrl = $inputUrl
        Write-Host "[OK] Repositorio vinculado com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "[AVISO] Nenhuma URL informada. A sincronizacao foi cancelada." -ForegroundColor Red
        exit 1
    }
}

Write-Host "[2/5] Repositorio remoto: $remoteUrl" -ForegroundColor Green

# 5. Adicionar todos os arquivos
Write-Host "[3/5] Identificando alteracoes..." -ForegroundColor Gray
& $gitCmd add -A

# 6. Gravar commit se houver modificacoes
Write-Host "[4/5] Registrando alteracoes..." -ForegroundColor Gray
$diff = & $gitCmd status --porcelain
if ($diff) {
    $now = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    & $gitCmd commit -m "Auto-sync: $now"
    Write-Host "[OK] Novo commit gravado com sucesso ($now)!" -ForegroundColor Green
} else {
    Write-Host "[INFO] Nenhuma nova alteracao detectada nos arquivos locais." -ForegroundColor Gray
}

# 7. Enviar para o GitHub
Write-Host "[5/5] Enviando para o GitHub (branch main)..." -ForegroundColor Cyan
& $gitCmd push -u origin main 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor Green
    Write-Host "  [SUCESSO] TODAS AS ATUALIZACOES FORAM ENVIADAS PARA O GITHUB!      " -ForegroundColor Green
    Write-Host "=====================================================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[INFO] Tentando sincronizar com atualizacoes remotas antes do envio..." -ForegroundColor Yellow
    & $gitCmd pull --rebase origin main 2>&1
    & $gitCmd push -u origin main 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "=====================================================================" -ForegroundColor Green
        Write-Host "  [SUCESSO] PROJETO SINCRONIZADO COM SUCESSO NO GITHUB!              " -ForegroundColor Green
        Write-Host "=====================================================================" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "=====================================================================" -ForegroundColor Red
        Write-Host "  [ATENCAO] Nao foi possivel completar o envio para o GitHub.        " -ForegroundColor Red
        Write-Host "=====================================================================" -ForegroundColor Red
        Write-Host "Possiveis causas:" -ForegroundColor Yellow
        Write-Host "1. Voce precisa autenticar sua conta do GitHub no navegador/Git." -ForegroundColor White
        Write-Host "2. A URL do repositorio pode estar incorreta ou voce nao tem permissao de escrita." -ForegroundColor White
        Write-Host "3. Se solicitar senha no terminal, utilize seu GitHub Personal Access Token." -ForegroundColor White
    }
}
Write-Host ""
