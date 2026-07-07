We need a new Deployment Topology for testing Nova with Ceph HCI storage.

Requirements:
- 3 compute nodes with HCI (co-located Ceph OSDs)
- Nova, Glance, Cinder, Neutron (OVN), and Heat services enabled
- Ceph HCI storage backend for Cinder and Glance
- IPv4 networking with VLANs (ctlplane, internalapi, storage, storagemgmt, tenant, external)
- MetalLB in L2 mode
- No networker nodes (standard OVN setup)
- No GPU, SR-IOV, or DPDK requirements

This is a test-only topology (DT), not a VA.
