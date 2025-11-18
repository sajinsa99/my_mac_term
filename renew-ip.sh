echo
echo "Stop wifi"
networksetup -setnetworkserviceenabled "Wi-Fi" off
sleep 6
echo "re init DHCP and ip"
ipconfig set en0 DHCP
sleep 6
echo "flush dns"
dscacheutil -flushcache
sleep 6
killall -HUP mDNSResponder
sleep 6
echo "start wifi"
networksetup -setnetworkserviceenabled "Wi-Fi" on
sleep  6
echo "renew ip"
ifconfig en0 down
sleep 6
ifconfig en0 up
sleep 6
echo "check connexion"
echo "ping -c 5 free.fr"
ping -c 5 free.fr || exit 1
echo
