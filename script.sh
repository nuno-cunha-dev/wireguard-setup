#!/bin/bash

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Function to detect main network interface
get_main_interface() {
    # Try to get the interface with default route
    DEFAULT_ROUTE_IF=$(ip -4 route show default | awk '{print $5}' | head -n1)
    
    if [[ -n "$DEFAULT_ROUTE_IF" ]]; then
        echo "$DEFAULT_ROUTE_IF"
        return 0
    fi
    
    # Fallback: try to find first non-loopback, non-wireguard interface that's UP
    DEFAULT_ROUTE_IF=$(ip -o link show up | \
        awk -F': ' '{print $2}' | \
        grep -v -E '^(lo|wg[0-9]+|tun[0-9]+|docker[0-9]+|veth[a-zA-Z0-9]+)$' | \
        head -n1)
    
    if [[ -n "$DEFAULT_ROUTE_IF" ]]; then
        echo "$DEFAULT_ROUTE_IF"
        return 0
    fi
    
    echo "Error: Could not detect main network interface"
    exit 1
}

# Function to get public IP
get_public_ip() {
    PUBLIC_IP=$(curl -s https://api.ipify.org || \
                curl -s https://ifconfig.me || \
                curl -s https://icanhazip.com)
    
    if [[ -z "$PUBLIC_IP" ]]; then
        echo "Error: Could not determine public IP address"
        exit 1
    fi
    echo "$PUBLIC_IP"
}

# Function to clean up existing WireGuard installation
cleanup_wireguard() {
    echo "Cleaning up existing WireGuard installation..."
    
    # Stop WireGuard if it's running
    systemctl stop wg-quick@wg0 2>/dev/null
    systemctl disable wg-quick@wg0 2>/dev/null
    
    # Remove existing WireGuard configurations
    rm -rf /etc/wireguard/*.conf
    rm -rf /etc/wireguard/*.key
    rm -rf /etc/wireguard/clients
    
    # Remove sysctl configuration
    rm -f /etc/sysctl.d/99-wireguard.conf
    
    echo "Cleanup complete"
}

# Ask user if they want to remove existing configuration
if [ -d "/etc/wireguard" ]; then
    read -p "Existing WireGuard configuration found. Remove it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup_wireguard
    else
        echo "Exiting to preserve existing configuration"
        exit 1
    fi
fi

# Install WireGuard and required tools
apt update
apt install -y wireguard qrencode curl

# Get public IP and main interface
SERVER_IP=$(get_public_ip)
MAIN_INTERFACE=$(get_main_interface)

echo "Detected public IP: $SERVER_IP"
echo "Detected main interface: $MAIN_INTERFACE"

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-wireguard.conf
sysctl -p /etc/sysctl.d/99-wireguard.conf

# Generate server private and public keys
umask 077
wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key

# Create server configuration
cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $(cat /etc/wireguard/server_private.key)
Address = 10.0.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ${MAIN_INTERFACE} -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ${MAIN_INTERFACE} -j MASQUERADE

# Client configurations will be added here
EOF

# Function to generate client configuration
generate_client_config() {
    local client_name=$1
    local client_ip=$2
    
    # Generate client keys
    wg genkey | tee /etc/wireguard/clients/${client_name}_private.key | wg pubkey > /etc/wireguard/clients/${client_name}_public.key
    
    # Create client configuration
    cat > /etc/wireguard/clients/${client_name}.conf << EOF
[Interface]
PrivateKey = $(cat /etc/wireguard/clients/${client_name}_private.key)
Address = 10.0.0.${client_ip}/24
DNS = 1.1.1.1

[Peer]
PublicKey = $(cat /etc/wireguard/server_public.key)
AllowedIPs = 0.0.0.0/0
Endpoint = ${SERVER_IP}:51820
PersistentKeepalive = 25
EOF

    # Add client to server configuration
    cat >> /etc/wireguard/wg0.conf << EOF

[Peer]
PublicKey = $(cat /etc/wireguard/clients/${client_name}_public.key)
AllowedIPs = 10.0.0.${client_ip}/32
EOF

    # Generate QR code for this client
    echo "Generating QR code for ${client_name}..."
    qrencode -t ansiutf8 < /etc/wireguard/clients/${client_name}.conf
}

# Create directory for client configurations
mkdir -p /etc/wireguard/clients

# Generate first client configuration
generate_client_config "client1" "2"

# Start WireGuard
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

echo "WireGuard server setup complete!"
echo "Server IP: ${SERVER_IP}"
echo "Main Interface: ${MAIN_INTERFACE}"
echo "Client configuration is available at /etc/wireguard/clients/client1.conf"
