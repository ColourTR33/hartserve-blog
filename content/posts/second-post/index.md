---
title: "K3s + Flux + Hugo: my homelab blog"
date: 2025-10-15
draft: false
tags: [hugo, fluxcd, k3s]
categories: [homelab]
description: "How I wired a Hugo blog into my Raspberry Pi K3s cluster with FluxCD."
cover:
  image: "hero.jpg"     # add hero.jpg next to index.md
  alt: "Raspberry Pi cluster"
  caption: "SRV-blue, green, black doing the heavy lifting."
  relative: true
showToc: true
---

Welcome! This is a page-bundle post. Images live **beside** the Markdown:

![Cluster](/blog/posts/k3s-flux-hugo/cluster.png)

But because this is a *page bundle*, you can use relative links too:

![Cluster](./cluster.png)

## Code blocks with copy buttons

```bash
kubectl -n blog get pods