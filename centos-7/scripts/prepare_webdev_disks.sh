#!/bin/bash
# Format and mount external disks for web development VMs

######################################################################
# determine device name prefix for items in /dev/ 

CONTROLLER=$1
CONTROLLER=${CONTROLLER:-virtio}

if [[ "$CONTROLLER" == "sata" ]]; then
  DEVPREFX=s
elif [[ "$CONTROLLER" == "virtio" ]]; then
  DEVPREFX=v
else
  echo "FATAL: I do not understand controller type $CONTROLLER. Quitting."
  exit 1
fi

######################################################################
# Device naming depends on qemu interface used. /dev/sd* for sata
# /dev/vd* for virtio. sata has a limit of 4 disks so we typical have 
# to use virtio.

# CONFIGURE
APPDB_DIR=/u02/oradata/appdb
APPDB_DEV=/dev/${DEVPREFX}db
APPDB_LABEL=appdb

USERDB_DIR=/u02/oradata/userdb
USERDB_DEV=/dev/${DEVPREFX}dc
USERDB_LABEL=userdb

ACCTDB_DIR=/u02/oradata/acctdb
ACCTDB_DEV=/dev/${DEVPREFX}dd
ACCTDB_LABEL=acctdb

DATA_DIR=/var/www/Common/apiSiteFilesMirror
DATA_DEV=/dev/${DEVPREFX}de
DATA_LABEL=data

BUILDER_DIR=/home/vmbuilder
BUILDER_DEV=/dev/${DEVPREFX}df
BUILDER_LABEL=vmbuilder


######################################################################
# FORMAT DISKS - full disk, no partition
set -x
mkfs.ext4 -F $APPDB_DEV
mkfs.ext4 -F $USERDB_DEV
mkfs.ext4 -F $ACCTDB_DEV
mkfs.ext4 -F $DATA_DEV
#mkfs.ext4 -F $BUILDER_DEV

# LABEL DISKS
e2label $APPDB_DEV   $APPDB_LABEL
e2label $USERDB_DEV  $USERDB_LABEL
e2label $ACCTDB_DEV  $ACCTDB_LABEL
e2label $DATA_DEV    $DATA_LABEL
#e2label $BUILDER_DEV $BUILDER_LABEL
set +x

# # MAKE MOUNTPOINTS
mkdir -p $APPDB_DIR
mkdir -p $USERDB_DIR
mkdir -p $ACCTDB_DIR
mkdir -p $DATA_DIR

# UPDATE /ETC/FSTAB
cat >> /etc/fstab <<EOF

LABEL=$APPDB_LABEL $APPDB_DIR ext4 nofail,defaults 0  0
LABEL=$USERDB_LABEL $USERDB_DIR ext4 nofail,defaults 0  0
LABEL=$ACCTDB_LABEL $ACCTDB_DIR ext4 nofail,defaults 0  0
LABEL=$DATA_LABEL $DATA_DIR ext4 nofail,defaults 0  0
#LABEL=$BUILDER_LABEL $BUILDER_DIR ext4 nofail,defaults 0  0
EOF

# MOUNT ALL
mount -a

# UPDATE PERMISSIONS ON MOUNTED DEVICES
chown oracle:oinstall $USERDB_DIR
chown oracle:oinstall $APPDB_DIR
chown oracle:oinstall $ACCTDB_DIR
chmod 1777 $DATA_DIR
