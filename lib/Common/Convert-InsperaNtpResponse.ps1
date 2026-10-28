function Convert-InsperaNtpResponse {
    # Decodes the transmit timestamp (bytes 40-47) of a 48-byte SNTP response into UTC.
    param([byte[]]$Response)

    if (-not $Response -or $Response.Length -lt 48) {
        throw 'NTP response shorter than 48 bytes'
    }

    # NTP is big-endian; BitConverter on Windows is little-endian
    $intBytes = [byte[]]$Response[40..43]
    $fracBytes = [byte[]]$Response[44..47]
    [Array]::Reverse($intBytes)
    [Array]::Reverse($fracBytes)

    $seconds = [BitConverter]::ToUInt32($intBytes, 0) + ([BitConverter]::ToUInt32($fracBytes, 0) / 4294967296.0)
    return [DateTime]::new(1900, 1, 1, 0, 0, 0, [DateTimeKind]::Utc).AddSeconds($seconds)
}
