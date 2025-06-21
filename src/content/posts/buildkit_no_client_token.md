+++ 
draft = false
date = 2025-06-20T20:17:47+08:00
title = "BUILDKIT_NO_CLIENT_TOKEN=1：修复代理后 Docker Buildx 认证失败"
description = ""
slug = ""
authors = ['Xu ZhiYi']
tags = ['docker','proxy','buildx','buildkit','BUILDKIT_NO_CLIENT_TOKEN']
categories = []
externalLink = ""
series = []
+++

# BUILDKIT_NO_CLIENT_TOKEN=1：修复代理后 Docker Buildx 认证失败

在使用 Docker Buildx （docker-container 驱动）并通过 HTTP_PROXY 或 HTTPS_PROXY 环境变量配置代理进行构建时，可能会遇到以下错误：

```
ERROR: failed to solve: failed to fetch anonymous token: Get "https://auth.docker.io/token?...": dial tcp ...:443: connectex: A connection attempt failed because the connected party did not properly respond after a period of time, or established connection failed because connected host has failed to respond.
```

**原因在于：** 默认情况下，BuildKit 的 Docker 驱动 (docker-container) 会尝试复用宿主机的 Docker 客户端认证凭据 (Token) 来与 Docker Hub 通信。然而，当构建容器运行在代理后方，而宿主机本身可能不在代理环境时，这种复用机制会导致容器无法成功获取或使用宿主机凭据进行认证，从而引发上述连接失败。

**解决方案：** 强制 BuildKit 容器独立获取认证凭据，避免复用宿主机的凭据复用。这可以通过在构建命令前设置环境变量（全局或临时） ```BUILDKIT_NO_CLIENT_TOKEN=1``` 来实现。设置后，BuildKit 容器将使用其自身的网络配置（包括代理设置）直接与 Docker Hub 认证服务通信。
