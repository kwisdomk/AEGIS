Write-Host "Hey. AEGIS here. What are we doing today?" -ForegroundColor Cyan

do {
    Write-Host ""
    Write-Host "=== AEGIS - Gaming Laptop Shield ===" -ForegroundColor White
    Write-Host "1. Take a fresh snapshot of this machine"
    Write-Host "2. Check system health"
    Write-Host "3. Just show me what to fix"
    Write-Host "4. Compare before and after a fix"
    Write-Host "5. Full check - health + what to fix"
    Write-Host "6. I'm done, get out"
    Write-Host ""

    $choice = Read-Host "Select an option"
    Write-Host ""

    switch ($choice) {
        '1' { & "$PSScriptRoot\scripts\AGcollect.ps1" }
        '2' { & "$PSScriptRoot\scripts\AGanalyse.ps1" }
        '3' { & "$PSScriptRoot\scripts\AGremediate.ps1" }
        '4' { & "$PSScriptRoot\scripts\AGcompare.ps1" }
        '5' { 
            & "$PSScriptRoot\scripts\AGanalyse.ps1"
            & "$PSScriptRoot\scripts\AGremediate.ps1"
        }
        '6' {
            Write-Host "Alright. Catch you later." -ForegroundColor Gray
            break
        }
        default {
            Write-Host "That is not a thing. Try again." -ForegroundColor Yellow
        }
    }
} while ($choice -ne '6')
