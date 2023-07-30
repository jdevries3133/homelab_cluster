I am having a gnarly hard time with PostgreSQL and transparent HugePages. This
little hello-world seeks to debug and ultimately resolve that.

Definitely, [Kubernetes #71233](https://github.com/kubernetes/kubernetes/issues/71233)
is hitting the nail on the head.

First, as a general goal, I do not care about or necessarily want transparent
hugepages. I don't think I have the hardware under the hood for it to matter and
even if I did, I don't really care and would rather things work.

I realized that I updated `/etc/default/grub` on my machines to disable
transparent hugepages, by adding this line:

```
GRUB_CMDLINE_LINUX_DEFAULT="transparent_hugepage=never"
```

However, I forgot to run `update-grub`, so when I reboot the machines, kubelet
presumably saw that hugepages was enabled on startup and was loading that
configuration. I ran `update-grub`, and observed that now, transparent hugepages
were disabled on boot. Nonetheless, the same postgres issue persisted.

I followed [this
guy](https://github.com/kubernetes/kubernetes/issues/71233#issuecomment-447472125)
and proceeded with creating a modified postgres image with hugepages totally
disabled. See ./Dockerfile.

With this container image pushed to Dockerhub, I reference it in the `test.yml`,
and I'm able to get PostgreSQL running in my K8s cluster!

See https://github.com/docker-library/docs/issues/2355; the plot continues.
