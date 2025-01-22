# WireGuard VPN Server Setup

A step-by-step guide to setting up a WireGuard VPN server on a Linux-based system (e.g., Ubuntu/Debian). This repository includes a script to automate the deployment of a WireGuard server.


## Overview
WireGuard is a fast, modern, and secure VPN protocol. This guide automates the setup of a WireGuard server and client using shell script. The server will route client traffic through an encrypted tunnel, and clients can connect using their generated keys.


## Prerequisites
- A Linux server (Ubuntu/Debian recommended) with root/sudo access.
- A public IP address.
- Port routing rule on your router/VPS for UDP port `51820`.
- Basic familiarity with terminal commands.


## Installation

### Server Setup
This will download and execute the setup:
```
curl -fsSL https://raw.githubusercontent.com/nuno-cunha-dev/wireguard-setup/refs/tags/v1.0.0/script.sh | sh
```

After successful execution, you should have a wireguard server with a QR code with your client configuration.


### Client setup
You can use the WireGuard android app to scan this QR code and connect to the server.

https://play.google.com/store/apps/details?id=com.wireguard.android


## Troubleshooting
Verify the server is running:
```
sudo wg show wg0
```


## License
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <https://unlicense.org/>
