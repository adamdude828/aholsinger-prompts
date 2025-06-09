# Docker-Compose Pattern: Claude Runner with project_ops Side-Car

## Purpose
Provide a simple, Docker-only local-development layout where:

* `claude_runner` can freely **edit** project files, talk to HTTP services, and drive browsers.
* Any command execution (tests, DB resets, builds, etc.) runs in existing service containers via `docker compose exec`.
* The privileged Docker socket is _not_ exposed to the interactive agent; it lives in a tiny _side-car_ (`project_ops`).

---

## High-Level Architecture

```mermaid
flowchart TD
    subgraph Compose Network (dev-net)
      CR["claude_runner\n(edit & prompts)"]
      PO["project_ops\n(HTTP API, has Docker socket)"]
      RT["Application Runtime\n(e.g. mcp-server, app)"]
      DB[(SQLServer / MySQL)]
      MCP["MCP Servers"]

      CR -- HTTP / TCP --> RT
      CR -- HTTP --> PO
      PO -- docker compose exec --> RT
      RT -- TCP --> DB
    end
```

### Key Containers

| Name            | Role                                                                           |
|-----------------|---------------------------------------------------------------------------------|
| **claude_runner** | Runs Claude; mounts repo RW; _no_ Docker socket.                              |
| **project_ops**  | Tiny Node/Express server; _has_ `/var/run/docker.sock`; executes commands in existing containers |
| **Application Runtime** | Long-lived services (Laravel php-fpm, Nginx, etc.) mounting code.        |
| **DB, MCP, etc.** | Supporting services.                                                          |

---

## project_ops – How It Works

1. Receives `POST /run { "command": "npm test" }` from Claude.
2. Executes the command using `docker compose exec` in the target service container.
3. Streams `stdout`/`stderr` back over the HTTP response until the command completes.
4. Returns the exit code with the output.

### Example handler (excerpt)
```js
const { command } = req.body;
if (!command) return res.status(400).json({error: 'Missing command'});

const task = spawn('docker', [
  'compose', '-p', COMPOSE_PROJECT_NAME,
  'exec', '-T', 'mcp-server',  // or any configured service
  'sh', '-c', command
]);

// Stream output back to client...
```

### Key Benefits
- **No allow-lists** – Any command can be executed
- **Reuses existing containers** – Commands run with proper environment and dependencies
- **Simple interface** – Just send the command string
- **Flexible** – Works with any toolchain (npm, composer, pytest, rake, etc.)

---

## Quick-Start

```bash
# 1. Bring up everything once
$ docker compose up -d

# 2. Open a Claude session inside claude_runner (or exec into it)
$ docker exec -it claude_runner bash

# 3. Ask Claude to run any command
./bin/run npm test
# or directly:
curl -XPOST project_ops:9000/run -d '{"command":"npm test"}' | cat
```

---

## Pros / Cons

### Pros
* **Zero Kubernetes** – only Docker/Compose required.
* **Fast on-boarding** – `docker compose up` and you're ready.
* **Clear privilege boundary** – only project_ops touches the Docker socket.
* **Easy to port-forward** – Compose exposes ports directly.

### Cons
* **Security** – project_ops still wields root-level Docker abilities (though limited to exec, not run).
* **No native job primitives** – retries, history, resources must be hand-rolled.
* **Scalability ceiling** – harder to mirror cloud environments (autoscaling, ingress).

---

## When to Choose This Pattern

Pick the Compose pattern when you need quick local iteration and your production stack _is not_ Kubernetes (or you simply don't want the K8s learning curve yet).  It's also a good stepping-stone before graduating to the Kubernetes pattern. 
