function New-InsperaToolkitSection {
    param(
        [string]$Heading,
        [string[]]$Lines = @(),
        [string]$Level = 'info'
    )

    return [PSCustomObject]@{
        Heading = $Heading
        Lines = @($Lines)
        Level = $Level
    }
}
