#!/bin/bash
virsh shutdown mycluster-cp1
virsh shutdown mycluster-cp2
virsh shutdown mycluster-cp3
virsh shutdown mycluster-w1
virsh shutdown mycluster-w2
virsh shutdown mycluster-w3
#virsh shutdown mycluster-w4
sudo cp /media/STORAGE/VM/blank/*.rawdisk /media/STORAGE/VM
virsh start mycluster-cp1
virsh start mycluster-cp2
virsh start mycluster-cp3
virsh start mycluster-w1
virsh start mycluster-w2
virsh start mycluster-w3
#virsh start mycluster-w4
