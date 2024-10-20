---
title: "SSH with custom identity"
author: ["Shahin Azad"]
draft: false
---

To use a custom ssh key (a different idnetity) to access a server, we
can use the following entry in `~/.ssh/config`:

```config
Host SomeName
  HostName myhost.com
  User myuser
  IdentityFile ~/.ssh/id_ed25519.myuser
  IdentitiesOnly yes
```

This is useful for example when you want to use a different identity
to push to [GitHub]({{< relref "20241017131521-github.md" >}}). As long as you use ssh to access, you can
change `github.com` from the remote address to `SomeName` (in the code
block above) and you'r good to go.
