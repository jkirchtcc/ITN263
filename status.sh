#!/bin/sh                                                                                       
#                                                                                               
# This (modified) script updates the SG-3100 device's first LED with gateway status             
# based on gwstatus, set color of first LED                                                     
# led a  -  led b  -  led c                                                                     
# 6 7 8  -  3 4 5  -  0 1 2    
#                                                                                               
#   php /usr/local/sbin/pfSsh.php playback gatewaystatus                                        
#                                                                                               
#   Ref: https://forum.netgate.com/topic/122407/netgate-sg-3100-leds/18                         
#   Credit: msf2000                                                                             
####################################################################################            
# Uncomment below for debugging                                                                 
#set -x                                                                                                                                                                                                                                                                               
                                                                                                                                                               
# Define color functions                                                                        
blue()                                                                                          
{                                                                                               
  echo "$gwstatus: blue"                                                                        
  /usr/sbin/gpioctl 6 duty 0                                                                    
  /usr/sbin/gpioctl 7 duty 0                                                                    
  /usr/sbin/gpioctL 8 duty 128                                                                  
}                                                                                               
                                                                                                
green()                                                                                         
{                                                                                               
  echo "$gwstatus: green"                                                                       
  /usr/sbin/gpioctl 6 duty 0                                                                    
  /usr/sbin/gpioctl 7 duty 12828                                                                
  /usr/sbin/gpioctl 8 duty 0                                                                    
}                                                                                               
                                                                                                
yellow()                                                                                        
{                                                                                               
  echo "$gwstatus: yellow"                                                                      
  /usr/sbin/gpioctl 6 duty 128                                                                  
  /usr/sbin/gpioctl 7 duty 32                                                                   
  /usr/sbin/gpioctl 8 duty 0                                                                    
}                                                                                               
                                                                                                
red()                                                                                           
{                                                                                               
  echo "$gwstatus: red"                                                                         
  /usr/sbin/gpioctl 6 duty 128                                                                  
  /usr/sbin/gpioctl 7 duty 0                                                                    
  /usr/sbin/gpioctl 8 duty 0                                                                    
}                                                                                               
                                                                                                
# main -----------------------------                                                            
gw=`/usr/local/bin/php /usr/local/sbin/pfSsh.php playback gatewaystatus | grep WAN `            
gwstatus=`echo $gw | awk '{ ORS="  "; print $7 }' | tr -d " " `                                 
                                                                                                
# debugging                                                                                     
echo $gw                                                                                        
echo "status:$gwstatus"                                                                         
                                                                                                
case "$gwstatus" in                                                                             
  none)                                                                                         
        green                                                                                   
        break                                                                                   
        ;;                                                                                      
  Online)                                                                                       
        green                                                                                   
        break                                                                                   
        ;;                                                                                      
  down)                                                                                         
        red                                                                                     
        break                                                                                   
        ;;                                                                                      
  Offline)                                                                                      
        red                                                                                     
        break                                                                                   
        ;;                                                                                      
  Warning)                                                                                      
        yellow                                                                                  
        break                                                                                   
        ;;                                                                                      
  *)                                                                                            
        blue                                                                                    
        echo "highloss, loss, highdelay or other issue."                                        
        break                                                                                   
        ;;                                                                                      
esac                                                                                            
