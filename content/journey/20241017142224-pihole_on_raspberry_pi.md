---
title: "Pihole on Raspberry Pi"
author: ["Shahin Azad"]
draft: false
---

## Notes {#notes}

-   First important observation is [NixOS]({{< relref "20241017131726-nixos.md" >}}) is not a good fit when the
    resources are as limited as what Raspberry Pi version 3
    provides. Even though I managed to boot it, and successfully load a
    few custom shells, building a full systems with all required
    updates, was causing out of memory and cache flushing. In general it
    might be possible, but not practical to use it for that matter.
-   Even without NixOS, I still wanted to track my changes, so I
    switched to [Ansible]({{< relref "20241017134446-ansible.md" >}}).
-   In a research to find an automated way to secure my Pi-hole setup, I
    ended up with [Ansible Collection Hardening](https://github.com/dev-sec/ansible-collection-hardening/tree/master).
-   When running [OS Hardening](https://github.com/dev-sec/ansible-collection-hardening/tree/master/roles/os_hardening) playbook, it was unable to set
    `vm.mmap_rnd_bits` value to the default 32. Also the suggested
    alternative 16 was raising the same error (invalid value). Using the
    following comment I realized the current value is 18 and kept it as
    is:
    ```bash
    sysctl vm.mmap_rnd_bits
    # Also it's possible to see all of them by:
    sysctl -a
    ```
-   Enabling [DNSSEC](https://www.cloudflare.com/dns/dnssec/how-dnssec-works/) I realized one of the services I run for a client,
    is not accessible. It was a `CNAME` record, which apparently is
    necessary to be set with `DNSSEC` enabled, to work correctly.
-   Pihole provides a `pihole` CLI interface, helping to interact with the
    system.
-   Using the following command you can check if a domain is listed in
    the installed adlists:
    ```bash
    pihole -q example.com
    ```
-   Using the following command you can tail the dns query logs:
    ```bash
    pihole -t
    ```
-   In order to block mallware and nudity on the DNS level, instead of
    utilizing a list, I utilized [Cloudflare]({{< relref "20241017125846-cloudflare.md" >}}) [Family DNS](https://developers.cloudflare.com/1.1.1.1/setup/#1111-for-families), which provides
    this by setting Pihole's upstream server.
-   When running a hypervisor like Proxmox in order to run multiple
    virtual machines the number of CPU cores matter. Given that
    typically each VM requires 1-2 cores. Some server CPUs provide
    virtual cores, which can be useful in this case.
-   NixOS by default doesn't allow to use Tailscale exit
    nodes. [This
    github issue](https://github.com/tailscale/tailscale/issues/10319#issuecomment-1886730614) helped me to solve it by adding the following to my
    config:
    ```nix
    networking.firewall.checkReversePath = "loose";
    ```
-   You can list Tailscale exit nodes using `tailscale exit-node list`.
-   If you need to reset Tailscale configuration for `up`, you can use
    `--reset`.
-   Even though Caddy supports Tailscale certificates, the following
    configuration needs to be available in `/etc/default/tailscale`:
    ```nil
    TS_PERMIT_CERT_UID=caddy
    ```
    [More Info](https://tailscale.com/kb/1190/caddy-certificates#provide-non-root-users-with-access-to-fetch-certificate.). Also note you need to use your system's user. On
    Raspbian, it was, `www-data`. The best place to find it is by checking
    the `systemd` service (if that's what you use).
-   To read `systemd` logs from a given time, you can use:
    ```bash
    journalctl -fu docker.service --since "30 minutes ago"
    ```
-   Using `journalctl -k` you log only kernel related logs.
-   `journalctl -e` prints the most recent entries.
-   Some ways to check dns records from a specific server:
    ```bash
    # On default dns server
    nslookup example.com
    # On local dns server
    nslookup example.com 127.0.0.1
    # On a dns server launched on 127.0.0.1:5379, resolve example.com
    host -p 5379 example.com 127.0.0.1
    # Or
    dig @127.0.0.1 -p 5379 example.com
    ```
-   For a quick check, you can create a reverse proxy on caddy like:
    ```bash
    caddy reverse-proxy --from $DOMAIN --to $TARGET
    ```
-   To define an inventory item for Ansible this is the format:
    ```text
    [servers]
    server-name ansible_host=x.x.x.x ansible_user=user
    ```
-   To define a local inventory file, add the following to `ansible.cfg`:
    ```text
    [defaults]
    # (pathlist) Comma separated list of Ansible inventory sources
    inventory=inventory
    ```
