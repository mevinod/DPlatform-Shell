#!/bin/sh

[ "$1" = update ] && { /home/git/gogs/gogs update; chown -R git: /home/git/gogs; whiptail --msgbox "Gogs updated!" 8 32; break; }
[ "$1" = remove ] && { sh sysutils/service.sh remove Gogs; rm -rf /home/git/gogs; whiptail --msgbox "Gogs removed." 8 32; break; }

[ $ARCHf != x86 ] && [ $ARCH != armv7 ] && [ $ARCH != armv6 ] &&  { whiptail --msgbox "Gogs doesn't support your architecture $ARCH
	Try to install Gitea instead." 8 48; exit 1; }

# Prerequisites
$install sqlite3

# Create a git user
useradd -mrU git

# Go to its directory
cd /home/git

# Get the latest Gogs release
ver=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/gogits/gogs/releases/latest)

# Only keep the version number in the url
ver=${ver#*v}

# Download, extract the archive
if [ $ARCHf = x86 ] ;then
	arch=amd64
	[ $ARCH = 86 ] && arch=386
	
	# Download the arcive
	download "https://cdn.gogs.io/gogs_v${ver}_linux_$arch.tar.gz -O gogs.tar.gz" "Downloading the Gogs $ver archive..."
	
	# Extract the downloaded archive and remove it
	extract gogs.tar.gz "xzf -" "Extracting the files from the archive..."
	rm gogs.tar.gz
elif [ $ARCHf = arm ] ;then
	# Install unzip if not installed
	hash unzip 2>/dev/null || $install unzip
	
	# Download the archive
	[ $ARCH = armv7 ] && url=https://cdn.gogs.io/gogs_v${ver}_raspi2.zip || url=https://cdn.gogs.io/gogs_v${ver}_linux_armv6.zip
	download "$url -O gogs.zip" "Downloading the Gogs $ver archive..."
	
	# Extract the downloaded archive and remove it
	unzip gogs.zip
	rm gogs.zip
fi
# Add a systemd service for Gogs
cp /home/git/gogs/scripts/systemd/gogs.service /etc/systemd/system

# Change the owner from root to git
chown -R git: /home/git/gogs

# Start the service and enable it to start at boot
systemctl start gogs
systemctl enable gogs

<<CADDY
if hash caddy 2>/dev/null ;then
  [ $IP = $LOCALIP ] && access=$IP || access=0.0.0.0
  cat >> /etc/caddy/Caddyfile <<EOF
http://$access:3000 {
    proxy / localhost:3000 {
        except /css /fonts /js /img
    }
    root /home/git/gogs/public
}

EOF
  systemctl restart caddy
fi
CADDY

whiptail --msgbox "Gogs installed!

Open http://$URL:3000 in your browser,
select SQlite and complete the installation." 10 64
