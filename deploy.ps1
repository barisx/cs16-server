# Set environment variables
$serverIp = "192.168.1.100"
$port = 27017
$maxPlayers = 16
$map = "fy_iceworld16"
$svLan = 1

# Run the Docker container with environment variables
docker run -p $port:$port `
    -e SERVER_IP=$serverIp `
    -e PORT=$port `
    -e MAXPLAYERS=$maxPlayers `
    -e MAP=$map `
    -e SV_LAN=$svLan `
    barisx/cs16fun:dev