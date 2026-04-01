---
name: devpod
description: Manage devpod development environment. Start, stop, configure resources (GPUs, CPU, RAM), and troubleshoot the devpod.
user-invocable: true
allowed-tools: Bash
argument-hint: "[command] [options]"
---

# Devpod Management

Manage devpod development environments with configurable resources.

## Arguments

Parse `$ARGUMENTS` for the command and options:

**Commands:** `up`, `stop`, `delete`, `status`, `configure`, `cluster-info`

**Resource options (for `configure` command):**
- `gpus=N` - Number of GPUs (default: 1)
- `cpu=N` - CPU cores (default: 15)
- `memory=NGi` - RAM in Gi (default: 128Gi)
- `provider=NAME` - Provider name
- `disk=1TB` - Workspace disk size (default: 1TB)

## Commands

### `up` - Start the devpod
```bash
devpod up . --id <devpod-id>
```
If no id specified, derive from current directory name.

### `stop` - Stop the devpod (releases resources but keeps data)
```bash
devpod stop <devpod-id>
```

### `delete` - Delete everything (pod + data)
```bash
devpod delete <devpod-id>
```

### `status` - Check devpod status
```bash
devpod list
kubectl get pods | grep <devpod-id>
```

### `cluster-info` - Check cluster node specs
```bash
kubectl get nodes -o custom-columns='NAME:.metadata.name,CPU:.status.allocatable.cpu,RAM:.status.allocatable.memory,STORAGE:.status.allocatable.ephemeral-storage,GPUs:.status.allocatable.nvidia\.com/gpu'
```
Also get GPU model info:
```bash
kubectl get nodes -o json | jq -r '.items[0].metadata.labels | to_entries[] | select(.key | contains("nvidia")) | "\(.key): \(.value)"' | head -20
```

### `configure` - Set provider resource options
When pod doesn't schedule or you need different resources, configure the provider.

**Step 1: Ask the user which provider to use.**
List available providers with:
```bash
devpod provider list
```
Then ask the user to select one.

**Step 2: Query cluster resources.**
Run cluster-info to get actual node specs:
```bash
kubectl get nodes -o custom-columns='NAME:.metadata.name,CPU:.status.allocatable.cpu,RAM:.status.allocatable.memory,STORAGE:.status.allocatable.ephemeral-storage,GPUs:.status.allocatable.nvidia\.com/gpu'
```
Parse the output to determine max available resources per node. Use these values to:
- Show the user what's available in the cluster
- Calculate proportional defaults based on requested GPUs (e.g., if node has 128 CPU and 8 GPUs, then 1 GPU ≈ 16 CPU)

**Step 3: Check for local pod template and inspect volumes.**
If `.devcontainer/pod-template.yaml` exists, read it and extract any persistent volume mounts (look for `volumes`, `volumeMounts`, `persistentVolumeClaim`, `emptyDir` with `sizeLimit`, etc.). Report these to the user.

**Step 4: Ask for final validation.**
Before applying any changes, summarize the configuration and ask the user for confirmation:

> Before proceeding, confirm DISK_SIZE for the workspace volume (default: 1TB).
> If the user doesn't specify a size, set DISK_SIZE=1TB.
>
> Based on cluster resources, I am going to create a devpod with:
> - **CPUs:** X (cluster max: Y)
> - **RAM:** Z Gi (cluster max: W Gi)
> - **GPUs:** N (cluster max: M)
> - **Disk:** DISK_SIZE (default: 1TB)
> - **Provider:** <provider-name>
> - **Volumes:** <list any PVCs or special mounts from pod-template.yaml>
>
> Is this configuration correct?

Wait for user confirmation before proceeding.

**Step 5: Apply pod template if exists:**
```bash
if [ -f "$(pwd)/.devcontainer/pod-template.yaml" ]; then
  devpod provider set-options <provider> -o POD_MANIFEST_TEMPLATE="$(pwd)/.devcontainer/pod-template.yaml"
fi
```

**Step 6: Set resource limits:**
```bash
devpod provider set-options <provider> -o RESOURCES=limits.nvidia.com/gpu=<gpus>,requests.nvidia.com/gpu=<gpus>,limits.cpu=<cpu>,requests.cpu=<cpu>,limits.memory=<memory>,requests.memory=<memory>
```

## Usage Examples

- `/devpod up` - Start with default id
- `/devpod stop my-project` - Stop specific devpod
- `/devpod configure gpus=4 cpu=60 memory=480Gi` - Configure for 4 GPUs
- `/devpod configure gpus=1 provider=my-provider` - Single GPU setup
- `/devpod status` - List all devpods
- `/devpod cluster-info` - Check cluster node specs (CPU, RAM, storage, GPUs)

## Troubleshooting / Debugging

### If DevPod fails during agent transfer (e.g., “write: broken pipe”, hangs while “uploading devpod agent”),

If the above error is seen when running `devpod ip`, apply the pod template fix:

- Ensure .devcontainer/pod-template.yaml has an init container that downloads the DevPod binary into a
  shared emptyDir and mounts it into /usr/local/bin/devpod via subPath.
- Ensure the Kubernetes provider is configured to use that template (POD_MANIFEST_TEMPLATE).
- Recreate the workspace (init containers don’t retrofit).

#### Verify with kubectl

- Init container ran: kubectl get pod <pod> -o jsonpath='{.status.initContainerStatuses}'
- Init container logs: kubectl logs <pod> -c devpod-agent
- Binary present: kubectl exec <pod> -- ls -l /usr/local/bin/devpod
  
**If the pod is still the old template**
- Delete the DevPod workspace and/or the pod (kubectl delete pod <pod>) so DevPod can recreate with the new template.

**If the init container can’t download**
- Note that cluster egress or GitHub access might be blocked; swap the URL to an internal mirror or pre-baked image.

## Notes
- Always query cluster-info to get actual allocatable resources before configuring
- Scale resources proportionally based on cluster specs (CPU and RAM per GPU)
- Stop devpods when not in use to release GPU resources
- The pod template should mount `/dev/shm` for shared memory
