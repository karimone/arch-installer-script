
configure_hostname(){
  echo "$HOSTNAME" > ${MOUNTPOINT}/etc/hostname
  if [[ ! -f ${MOUNTPOINT}/etc/hosts.aui ]]; then
    cp ${MOUNTPOINT}/etc/hosts ${MOUNTPOINT}/etc/hosts.aui
  else
    cp ${MOUNTPOINT}/etc/hosts.aui ${MOUNTPOINT}/etc/hosts
  fi
  arch_chroot "sed -i '/127.0.0.1/s/$/ '${HOSTNAME}'/' /etc/hosts"
  arch_chroot "sed -i '/::1/s/$/ '${HOSTNAME}'/' /etc/hosts"
}

