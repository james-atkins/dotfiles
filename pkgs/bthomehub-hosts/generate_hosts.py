#!/usr/bin/env python3
import btsmarthub_devicelist

smarthub = btsmarthub_devicelist.BTSmartHub(router_ip='192.168.1.254', smarthub_model=2)
devices = smarthub.get_devicelist(only_active_devices=True, include_connections=True)

for device in devices:
    if device["UserHostName"]:
        print(device["IPAddress"], "\t", device["UserHostName"])

