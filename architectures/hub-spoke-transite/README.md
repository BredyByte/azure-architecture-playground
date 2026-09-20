# Hub and Spoke with Azure Firewall and VPN Gateway

A personal Azure architecture playground for experimenting with routing between spokes, controlled internet egress, and connectivity between regions.

## Diagram

![Architecture diagram](diagram/architecture.png)

## Part 1 — Hub-and-spoke peering, Firewall, and UDRs

The hub is peered with Spokes A, B, and C. There is no direct peering between spokes. UDRs on the VM1 and VM2 subnets send traffic for the other spoke and `0.0.0.0/0` through Azure Firewall.

The Firewall Policy allows SSH between VM1 and VM2, HTTPS to `api.ipify.org`, and the traffic required for Run Command. Spoke B is peered but has no workload.

### Tests

In the Azure portal, open **Virtual machines → VM1 or VM2 → Operations → Run command → RunShellScript**.

**Spoke-to-spoke traffic:** run on VM1 and VM2 respectively:

```bash
nc -vz -w 5 10.4.0.4 22
```

```bash
nc -vz -w 5 10.2.0.4 22
```

Both commands should report that port 22 is reachable.

**Internet egress:** run on both VMs:

```bash
curl -sS --max-time 10 https://api.ipify.org
```

Both should return the Azure Firewall public IP.

**Routing:** in **Network Watcher → Next hop**, check:

| Source | Destination | Expected next hop |
| --- | --- | --- |
| VM1 | `10.4.0.4` | `VirtualAppliance` — Firewall private IP |
| VM2 | `10.2.0.4` | `VirtualAppliance` — Firewall private IP |
| VM1 and VM2 | `8.8.8.8` | `VirtualAppliance` — Firewall private IP |

## Part 2 — VNet-to-VNet VPN Gateway

The Italy North VNet (`10.10.0.0/16`) connects to the hub through two route-based VPN gateways and a VNet-to-VNet VPN connection. BGP is enabled on both gateways. Italy is not peered with the hub or the spokes.

Gateway transit lets the spokes use the hub gateway through their existing peerings. On the VM1 and VM2 subnets, a UDR sends traffic for `10.10.0.0/16` to Azure Firewall (`10.1.1.4`). The Firewall Policy allows SSH from both VMs to VM3 (`10.10.0.4`). UDRs on the hub `GatewaySubnet` send return traffic for Spokes A and C through the Firewall.

The resulting path is **VM1 or VM2 → Azure Firewall → hub VPN gateway → VPN tunnel → Italy VPN gateway → VM3**. Return traffic passes through the hub Firewall before reaching the originating spoke.

### Tests

**VPN connection:** in **Virtual network gateways → Connections**, check that `conn-hub-to-italy` and `conn-italy-to-hub` show **Connected**.

**Route to Italy:** in **Network Watcher → Next hop**, test VM1 with destination `10.10.0.4`. The expected next hop is **VirtualAppliance**, with IP address `10.1.1.4`. This confirms that the VM sends traffic to the Firewall before it reaches the VPN gateway.

**End-to-end connectivity:** on VM1, open **Operations → Run command → RunShellScript** and run:

```bash
nc -vz -w 5 10.10.0.4 22
```

The command should report that port 22 on VM3 is reachable. This also confirms that the return path works.
