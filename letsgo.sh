#!/bin/bash

#--------------FUNCTIONS-----------------------------

function get_host_path {
  target="$1"
  output=$(findmnt --target "${target}")
  fstype=$(echo "${output}" | awk '{print $3}')
  source=$(echo "${output}" | awk '{print $2}')
  
   if [[ $output == *shfs* ]]; then
    host_path=$(echo $output | awk -F'[\\[\\]]' '{print "/mnt/user"$2}')
    echo "$host_path"
  elif echo "${source}" | grep -qE '/dev/mapper/md[0-9]+'; then
    disk_num=$(echo "${source}" | sed -nE 's|/dev/mapper/md([0-9]+)\[.*|\1|p')
    subvol=$(echo "${source}" | sed -nE 's|/dev/mapper/md[0-9]+\[(.*)\]|\1|p')
    host_path="/mnt/disk${disk_num}${subvol}"
	echo "${host_path}"
  else
    echo "Unsupported filesystem type: ${fstype}"
    return 1
  fi
  
}

function push_win98 {
    # Create vdisk location if it doesn't exist
    if [ ! -d "$install_location" ]; then
        echo "Install location directory does not exist. Creating it..."
        mkdir -p "$install_location"
    fi

    if [[ "$RUNTYPE" == "Fix-xml" ]]; then
        if [[ -f "$install_location/vdisk1.img" ]] && [[ -f "$install_location/vdisk2.img" ]]; then
            check_xml
            return
        fi
    else
        # Rename existing files if they exist
        if [[ -f "$install_location/vdisk1.img" ]]; then
            old_filename=$(date +"vdisk1-old-%Y-%m-%d-%H-%M.img")
            mv "$install_location/vdisk1.img" "$install_location/$old_filename" || { echo "Failed to rename file. Exiting..."; exit 1; }
        fi

        if [[ -f "$install_location/vdisk2.img" ]]; then
            old_filename=$(date +"vdisk2-old-%Y-%m-%d-%H-%M.img")
            mv "$install_location/vdisk2.img" "$install_location/$old_filename" || { echo "Failed to rename file. Exiting..."; exit 1; }
        fi

        # Move and rename vdisks
        if [[ "$TYPE" == "WIN98-KernelEX" ]]; then
            src_file="/app/kernelex.img"
            dst_file="$install_location/vdisk1.img"
        elif [[ "$TYPE" == "WIN98-Normal" ]]; then
            src_file="/app/normal.img"
            dst_file="$install_location/vdisk1.img"
        else
            echo "Unsupported type: $TYPE. Exiting..."
            exit 1
        fi

        mv "$src_file" "$dst_file" || { echo "Failed to move file. Exiting..."; exit 1; }

        # Move and rename second vdisk
        src_file="/app/data.img"
        dst_file="$install_location/vdisk2.img"
        mv "$src_file" "$dst_file" || { echo "Failed to move file. Exiting..."; exit 1; }
    fi
}

function set_variables {
   
    domains_share=$(get_host_path "/vm_location")
    install_location="/vm_location/""$vm_name"
    vdisk_location="$domains_share/$vm_name"
    icon_location="/unraid_vm_icons/Recalbox-logo.png"  
    XML_FILE="/tmp/win98.xml"
}

define_win98() {
    # Generate a random UUID and MAC address
    UUID=$(uuidgen)
    MAC=$(printf '52:54:00:%02X:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))

    # Replace the UUID and MAC address tags in the XML file with the generated values
    sed -i "s#<uuid>.*<\/uuid>#<uuid>$UUID<\/uuid>#" "$XML_FILE"
    sed -i "s#<mac address='.*'/>#<mac address='$MAC'/>#" "$XML_FILE"

    # Replace the source file locations in the XML file with the vdisk location and filename
    sed -i "s#<source file='\(.*\)/vdisk1.img'/>#<source file='$install_location/vdisk1.img'/>#" "$XML_FILE"
    sed -i "s#<source file='\(.*\)/vdisk2.img'/>#<source file='$install_location/vdisk2.img'/>#" "$XML_FILE"

    # Replace the name of the virtual machine in the XML file with the specified name
    sed -i "s#<name>.*<\/name>#<name>$vm_name<\/name>#" "$XML_FILE"

    # Define the virtual machine using the modified XML file
    virsh define "$XML_FILE"
}

function check_xml {
    local xml_file="/tmp/${vm_name}.xml"
    virsh dumpxml "$vm_name" > "$xml_file"
    
    # Remove tablet device
    sed -i '/<input type='"'"'tablet'"'"'/,/<\/input>/d' "$xml_file"
    
    # Check if qemu:commandline already exists
    if ! grep -q '<qemu:commandline>' "$xml_file"; then
        # Add qemu:commandline if it doesn't exist
        sed -i '/<\/devices>/i \  <qemu:commandline>\n    <qemu:arg value='"'"'-cpu'"'"'/>\n    <qemu:arg value='"'"'pentium3,vendor=GenuineIntel,+invtsc,+sse,+sse2'"'"'/>\n  </qemu:commandline>' "$xml_file"
    fi

    # Redefine domain if it exists and is not running
    if virsh list --name --state-running | grep -q "$vm_name"; then
        echo "Cannot redefine a running domain. Exiting..."
        return 1
    elif virsh list --name --all | grep -q "$vm_name"; then
        virsh define "$xml_file"
        virsh start "$vm_name"
    fi

}

function download_xml {
	local url="https://raw.githubusercontent.com/SpaceinvaderOne/Recalbox_inabox/main/recal.xml"
	curl -s -L $url -o $XML_FILE
}

function download_icon {
    local url="https://github.com/SpaceinvaderOne/Recalbox_inabox/raw/main/Recalbox.png"

    # Check if the exists (as will only if on Unraid)
    if [ -d "$(dirname "$icon_location")" ]; then
        # Download the file to the Unraid location
        curl -s -L "$url" -o "$icon_location"
    else
        # Download the file to the current working directory for other Linus systems
        curl -s -L "$url" -o "$(basename "$icon_location")"
    fi
}


# Call the functions

set_variables 
push_win98
#download_xml
#download_icon
define_win98

       
