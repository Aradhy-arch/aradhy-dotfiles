#!/bin/bash

# Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Error: Please run as root (use sudo)${NC}"
  exit 1
fi

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}    USB Drive Formatter for Arch Linux   ${NC}"
echo -e "${BLUE}=========================================${NC}"

# Prompt for device name
echo -e "${YELLOW}WARNING: Ensure you know the correct device name!${NC}"
read -p "Enter the device name (e.g., /dev/sdb): " DEVICE

# Safety check: Ensure input looks like /dev/sdX and IS NOT /dev/sda
if [[ ! "$DEVICE" =~ ^/dev/sd[b-z]$ ]]; then
  if [[ "$DEVICE" == "/dev/sda" ]]; then
    echo -e "${RED}ERROR: /dev/sda is your main system drive! Aborting to prevent data loss.${NC}"
  else
    echo -e "${RED}Error: Invalid target. Must be a secondary drive like /dev/sdb, /dev/sdc, etc.${NC}"
  fi
  exit 1
fi

# Confirm action
echo -e "\n${RED}!!! DANGER ZONE !!!${NC}"
echo -e "This will ${RED}PERMANENTLY WIPE${NC} all data on ${YELLOW}$DEVICE${NC}!"
read -p "Type 'yes' to confirm: " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo -e "${YELLOW}Aborted.${NC}"
  exit 0
fi

# Prompt for filesystem first to enforce label limits properly
echo -e "\n${GREEN}Select filesystem:${NC}"
echo "1) FAT32 (Universal compatibility)"
echo "2) exFAT (Large files, modern compatibility)"
echo "3) ext4 (Linux only)"
echo "4) NTFS (Windows compatibility)"
read -p "Enter choice [1-4]: " FS_CHOICE

case $FS_CHOICE in
  1)
    FS_TYPE="fat32"
    PARTED_TYPE="fat32"
    MAX_LABEL_LEN=11
    ;;
  2)
    FS_TYPE="exfat"
    PARTED_TYPE="ntfs"
    MAX_LABEL_LEN=11
    ;;
  3)
    FS_TYPE="ext4"
    PARTED_TYPE="ext4"
    MAX_LABEL_LEN=16
    ;;
  4)
    FS_TYPE="ntfs"
    PARTED_TYPE="NTFS"
    MAX_LABEL_LEN=32
    ;;
  *)
    echo -e "${RED}Invalid choice.${NC}"
    exit 1
    ;;
esac

# Prompt for label with length validation
while true; do
  read -p "Enter volume label (name, max $MAX_LABEL_LEN chars): " LABEL
  if [ ${#LABEL} -gt $MAX_LABEL_LEN ]; then
    echo -e "${RED}Error: Label is ${#LABEL} chars. Maximum allowed for $FS_TYPE is $MAX_LABEL_LEN characters.${NC}"
  else
    break
  fi
done

# Unmount any mounted partitions
echo -e "\n${BLUE}Unmounting partitions...${NC}"
umount "${DEVICE}"* 2>/dev/null

# Create partition table
echo -e "\n${BLUE}Creating new partition table on $DEVICE...${NC}"
parted -s "$DEVICE" mklabel msdos
parted -s "$DEVICE" mkpart primary "$PARTED_TYPE" 1MiB 100%

# Ensure partition nodes are fully registered
partprobe "$DEVICE" 2>/dev/null
udevadm settle 2>/dev/null || sleep 2

PARTITION="${DEVICE}1"
echo -e "${BLUE}Formatting $PARTITION as $FS_TYPE...${NC}"

wipefs -a "$PARTITION" >/dev/null 2>&1

case $FS_CHOICE in
  1) mkfs.vfat -F 32 -n "$LABEL" "$PARTITION" ;;
  2) mkfs.exfat -F -n "$LABEL" "$PARTITION" ;; # Capital -F for exfatprogs!
  3) mkfs.ext4 -F -L "$LABEL" "$PARTITION" ;;
  4) mkfs.ntfs -f -L "$LABEL" "$PARTITION" ;;
esac

if [ $? -eq 0 ]; then
  echo -e "\n${GREEN}=========================================${NC}"
  echo -e "${GREEN}    SUCCESS! Drive formatted correctly.   ${NC}"
  echo -e "${GREEN}=========================================${NC}"
  echo -e "Device:     ${YELLOW}$PARTITION${NC}"
  echo -e "Filesystem: ${YELLOW}$FS_TYPE${NC}"
  echo -e "Label:      ${YELLOW}$LABEL${NC}"
  echo -e "\n${BLUE}You can now mount or remove the drive.${NC}"
else
  echo -e "\n${RED}Error: Formatting failed.${NC}"
  exit 1
fi
