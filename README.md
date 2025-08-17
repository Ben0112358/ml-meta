# ml-meta

`ml-meta` is the **overview and entrypoint** for the entire ML pipeline ecosystem.  
It ties together the other sub-repositories into a **modular, end-to-end ML system**:

```
ml-infra → ml-data → ml-training → ml-serving → ml-ui
```

Each stage is contained in its own repository and can be run independently or as part of the full pipeline.  

---

## 📖 What This Repository Is

- A **map of the full pipeline**: links and explanations of all submodules.  
- **User guide**: how to set up, run, and chain stages together.  
- **Developer guide**: conventions, project structure, and how to extend the system.  

---

## 🧩 Submodules Overview

- **[ml-infra](https://github.com/Ben0112358/ml-infra)** → infrastructure setup (networks, shared volumes, base configs)  
- **[ml-data](https://github.com/Ben0112358/ml-data)** → data ingestion and preprocessing  
- **[ml-training](https://github.com/Ben0112358/ml-training)** → training models on prepared data  
- **[ml-serving](https://github.com/Ben0112358/ml-serving)** → serving trained models on endpoints  
- **[ml-ui](https://github.com/Ben0112358/ml-ui)** → user-facing frontend connected to serving  

Each subrepo has its own README with **project-specific details**.  
This README focuses on the **big picture** and how everything ties together.

---

## 🚀 Quickstart (User Perspective)

1. **Clone the repositories** (or the umbrella pipeline repo if provided):  
   ```bash
   git clone https://github.com/Ben0112358/ml-meta
   # Then clone the other subrepos alongside it
   ```

2. **Set the common base path** for all stages:  
   ```bash
   export ML_HOMELAB_ROOT=/absolute/path/to/ml-homelab
   ```

3. **Run a stage** (containerized or Python). Examples:  
   ```bash
   cd ml-data
   ./execute.sh dummy_project dev
   ```

4. **Chain stages together**:  
   - `ml-data` writes processed data into `$ML_HOMELAB_ROOT`  
   - `ml-training` consumes it and writes models into `$ML_HOMELAB_ROOT`  
   - `ml-serving` consumes models and opens an API  
   - `ml-ui` connects to the serving API  

5. **Ports and networking**:  
   - Serving endpoints are exposed on `localhost:$SERVING_PORT`  
   - UI is exposed on `localhost:$UI_PORT`  
   - Both must share the same `DOCKER_NETWORK_NAME`  

---

## ⚙️ Development Conventions (Dev Perspective)

### Folder layout
Each subrepo follows the same pattern:
```
docker-compose.<project>.yaml
Dockerfile.<project>
src/<subrepo_name>/<project>/
tests/
```

### Adding a new project
- Add a `<project_name>` folder in the relevant subrepo under `src/`  
- Implement its logic (see that subrepo’s `dummy_project` for reference)  
- Add corresponding Dockerfile + docker-compose file  

### Logging & config
- Each stage has a `config.py` for environment variables and defaults  
- Global directories (data, models, logs) are always anchored at `$ML_HOMELAB_ROOT`  
- Logs follow a consistent format via the shared utils  

### Execution helper
- Each subrepo provides `execute.sh` for cleanup + containerized run  
- Runs can be prefixed with project and mode: `<project>_<mode>`  

---

## 🧪 Testing & CI

- Each subrepo has `tests/` with pytest-based unit tests  
- Run tests with:  
  ```bash
  poetry run pytest
  ```  
- Future CI/CD integration will run these automatically  

---

## 🌍 Why This Layout?

- **Separation of concerns** → each stage is self-contained but composable  
- **Flexibility** → run locally (Python) or in containers (Docker Compose)  
- **Reusability** → swap out projects or stages without breaking the rest  
- **Transparency** → explicit configs, minimal magic  

---

## 🔗 Next Steps

1. Pick a subrepo (start with [ml-data](https://github.com/Ben0112358/ml-data))  
2. Read its README for detailed usage  
3. Run a dummy project end-to-end across the pipeline  
4. Extend with your own project(s)  

---
