import pyshark
import pycrate_mobile.NASLTE as nas
from binascii import hexlify, unhexlify
import json
import os

def parse_pcap(file_name, disp_filter='lte-rrc.dedicatedInfoNAS'):
    
    cap = pyshark.FileCapture(file_name, display_filter=disp_filter)
    service_reject_count = attach_reject_count = auth_failure_count = tau_reject_count = 0

    for pkt in cap:
        nasdata = pkt['lte_rrc'].lte_rrc_dedicatedInfoNAS
        nasdata = unhexlify(nasdata.replace(':', ''))
        t = nas.parse_NASLTE_MT(nasdata)
        if t[1] == 0:
            nas_data_dict = json.loads(t[0].to_json())
            if 'EMMServiceReject' in nas_data_dict:
                service_reject_count += 1
            elif 'EMMAttachReject' in nas_data_dict:
                attach_reject_count += 1
            elif 'EMMTrackingAreaUpdateReject' in nas_data_dict:
                tau_reject_count += 1
            elif 'EMMSecProtNASMessage' in nas_data_dict:
                for i in nas_data_dict['EMMSecProtNASMessage']:
                    if 'EMMAuthenticationFailure' in i:
                        auth_failure_count += 1
                        break
            else:
                None
            
        else:
            print("Error:", t[1])

    print(service_reject_count, attach_reject_count, auth_failure_count, tau_reject_count)


os.chdir("/home/kali/Desktop/telcosec/phoenix/NAS_PCAP_logs/specifics")

caps = os.listdir('.')
for filename in caps:
    print("\n" + filename)
    parse_pcap(filename)