# ml-meta

`ml-meta` is the **overview and entrypoint** for the entire ML pipeline ecosystem.  
It ties together the other sub-repositories into a **modular, end-to-end ML system**:

```
ml-infra → ml-data → ml-training → ml-serving → ml-ui
```

Each stage is contained in its own repository and can be run independently or as part of the full pipeline.  

---

## What This Repository Is

- A **map of the full pipeline**: links and explanations of all submodules.  
- **User guide**: how to set up, run, and chain stages together.  
- **Developer guide**: conventions, project structure, and how to extend the system.  

---

## Submodules Overview

- **[ml-infra](https://github.com/Ben0112358/ml-infra)** → infrastructure setup (folders, docker network, config file with all paths etc [used in pipeline mode]) 
- **[ml-data](https://github.com/Ben0112358/ml-data)** → data ingestion and preprocessing  
- **[ml-training](https://github.com/Ben0112358/ml-training)** → training models on prepared data  
- **[ml-serving](https://github.com/Ben0112358/ml-serving)** → serving trained models on endpoints  
- **[ml-ui](https://github.com/Ben0112358/ml-ui)** → user-facing frontend connected to serving

Each subrepo has its own README with **project-specific details**.  

---

## Running the Pipeline

There are **two ways to run** the system:

### 1. Pipeline Mode (recommended)
- Orchestrated via [`ml-pipeline`](https://github.com/Ben0112358/ml-pipeline).  
- Automatically handles:
  - Docker network names
  - Port assignments
  - Environment variable wiring
  - Cleanup between stages  

Usage:

```bash
bash execute.sh <project_name> <mode>
```

Where:
- `<project_name>` = the project you want to run  
- `<mode>` = `prod` or `dev`  
  - `prod` → uses the latest remote `main` branch of each subrepo  
  - `dev` → uses your local checkout/state  

This is the easiest way to run the full pipeline end-to-end. A lot of environment variables needed further down the pipeline are handled automatically by using suffixes based on `<project_name>`, `<mode>`, and the timestamp of the run.

---

### 2. Running without pipeline (manual)
- Run a specific stage directly via Docker Compose or Python.  
- You must manage environment variables (`ML_HOMELAB_ROOT`, ports, docker network) yourself.  
- Refer to the README of each subrepo for detailed instructions.  

Useful for local development and debugging individual stages.  

---

## Development Conventions (Dev Perspective)

### Folder layout
Each subrepo follows the same pattern:
```
docker-compose.<project>.yaml
Dockerfile.<project>
src/<subrepo_name>/<project>/
tests/
```

### Config
- Each stage has a `config.py` file which essentially ingests environment and makes them importable.

### Adding a new project
- Add a `<project_name>` folder in the relevant subrepo under `src/`  
- Implement its logic (see that subrepo’s `dummy_project` for reference)  
- Add corresponding Dockerfile + docker-compose file  

---

## Testing & CI

- Each subrepo has `tests/` with pytest-based unit tests  
- Run tests with:  
  ```bash
  poetry run pytest
  ```  
- Future CI/CD integration will run these automatically  

---

## Next Steps

1. Start with [ml-pipeline](https://github.com/Ben0112358/ml-pipeline) if you want the **full orchestrated pipeline**.  
2. Explore individual subrepos if you want to work on or debug a **specific stage**.  
3. To add your own project, follow the developer conventions listed above.  

---
