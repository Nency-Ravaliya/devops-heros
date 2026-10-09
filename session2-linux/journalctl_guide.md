journalctl is a utility to query and display the logs that are collected by systemd and journald daemons.

journalctl -u <service>, journalctl -f, journalctl -p err

Sample outputs

durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session2-linux$ journalctl -u NetworkManager -n 10
Sep 02 16:00:49 durga-prasad-RedmiBook-15-Pro NetworkManager[916]: <info>  [1788345049.6623] device (p2p-dev-wlp0s20f3): supplicant management interfa>
Sep 02 16:00:49 durga-prasad-RedmiBook-15-Pro NetworkManager[916]: <info>  [1788345049.6697] device (wlp0s20f3): supplicant interface state: 4way_hand>
Sep 02 16:00:49 durga-prasad-RedmiBook-15-Pro NetworkManager[916]: <info>  [1788345049.6702] device (wlp0s20f3): ip:dhcp4: restarting
Sep 02 16:00:49 durga-prasad-RedmiBook-15-Pro NetworkManager[916]: <info>  [1788345049.6702] dhcp4 (wlp0s20f3): canceled DHCP transaction
Sep 02 16:00:49 durga-prasad-RedmiBook-15-Pro NetworkManager[916]: <info>  [1788345049.6702] dhcp4 (wlp0s20f3): activation: beginning transaction (tim>
Sep 02 16:00:49 durga-prasad-RedmiBook-15-Pro NetworkManager[916]: <info>  [1788345049.6702] dhcp4 (wlp0s20f3): state changed no lease
Sep 02 16:00:49 durga-prasad-RedmiBook-15-Pro NetworkManager[916]: <info>  [1788345049.6703] dhcp4 (wlp0s20f3): activation: beginning transaction (tim>
Sep 02 16:00:49 durga-prasad-RedmiBook-15-Pro NetworkManager[916]: <info>  [1788345049.6704] device (p2p-dev-wlp0s20f3): supplicant management interfa>
Sep 02 16:00:49 durga-prasad-RedmiBook-15-Pro NetworkManager[916]: <info>  [1788345049.7013] dhcp4 (wlp0s20f3): state changed new lease, address=192.1>
Sep 02 16:00:49 durga-prasad-RedmiBook-15-Pro NetworkManager[916]: <info>  [1788345049.7016] dhcp4 (wlp0s20f3): state changed new lease, address=192.1>


durga-prasad@durga-prasad-RedmiBook-15-Pro:~/devops-heros/session2-linux$ journalctl -p err -n 10
Aug 30 18:54:05 durga-prasad-RedmiBook-15-Pro systemd[1]: Failed to start fwupd-refresh.service - Refresh fwupd metadata and update motd.
Aug 30 21:18:05 durga-prasad-RedmiBook-15-Pro systemd[1]: Failed to start fwupd-refresh.service - Refresh fwupd metadata and update motd.
Aug 31 15:04:00 durga-prasad-RedmiBook-15-Pro systemd[1]: Failed to start fwupd-refresh.service - Refresh fwupd metadata and update motd.
-- Boot a6cbf14d8bcf4111923226f2a145e87f --
Sep 01 03:14:17 durga-prasad-RedmiBook-15-Pro bluetoothd[837]: profiles/sap/server.c:sap_server_register() Sap driver initialization failed.
Sep 01 03:14:17 durga-prasad-RedmiBook-15-Pro bluetoothd[837]: sap-server: Operation not permitted (1)
Sep 01 10:09:49 durga-prasad-RedmiBook-15-Pro systemd[1468]: Failed to start snap.firmware-updater.firmware-notifier.service - Service for snap applic>
Sep 01 10:10:16 durga-prasad-RedmiBook-15-Pro gdm-password][3265]: gkr-pam: couldn't unlock the login keyring.
Sep 01 10:10:17 durga-prasad-RedmiBook-15-Pro gdm3[1422]: Gdm: on_display_added: assertion 'GDM_IS_REMOTE_DISPLAY (display)' failed
Sep 01 10:10:27 durga-prasad-RedmiBook-15-Pro gdm3[1422]: Gdm: on_display_removed: assertion 'GDM_IS_REMOTE_DISPLAY (display)' failed
Sep 02 16:27:05 durga-prasad-RedmiBook-15-Pro adduser[213129]: Only root may add a user or group to the system.
...skipping...
Aug 30 18:54:05 durga-prasad-RedmiBook-15-Pro systemd[1]: Failed to start fwupd-refresh.service - Refresh fwupd metadata and update motd.
Aug 30 21:18:05 durga-prasad-RedmiBook-15-Pro systemd[1]: Failed to start fwupd-refresh.service - Refresh fwupd metadata and update motd.
Aug 31 15:04:00 durga-prasad-RedmiBook-15-Pro systemd[1]: Failed to start fwupd-refresh.service - Refresh fwupd metadata and update motd.
-- Boot a6cbf14d8bcf4111923226f2a145e87f --
Sep 01 03:14:17 durga-prasad-RedmiBook-15-Pro bluetoothd[837]: profiles/sap/server.c:sap_server_register() Sap driver initialization failed.
Sep 01 03:14:17 durga-prasad-RedmiBook-15-Pro bluetoothd[837]: sap-server: Operation not permitted (1)
Sep 01 10:09:49 durga-prasad-RedmiBook-15-Pro systemd[1468]: Failed to start snap.firmware-updater.firmware-notifier.service - Service for snap applic>
Sep 01 10:10:16 durga-prasad-RedmiBook-15-Pro gdm-password][3265]: gkr-pam: couldn't unlock the login keyring.
Sep 01 10:10:17 durga-prasad-RedmiBook-15-Pro gdm3[1422]: Gdm: on_display_added: assertion 'GDM_IS_REMOTE_DISPLAY (display)' failed
Sep 01 10:10:27 durga-prasad-RedmiBook-15-Pro gdm3[1422]: Gdm: on_display_removed: assertion 'GDM_IS_REMOTE_DISPLAY (display)' failed
Sep 02 16:27:05 durga-prasad-RedmiBook-15-Pro adduser[213129]: Only root may add a user or group to the system.