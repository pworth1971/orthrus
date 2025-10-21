# Orthrus: AI Coding Agent Instructions

## Project Overview
Orthrus is a provenance-based intrusion detection system using Graph Neural Networks (GNNs) to detect attacks in system audit data. It processes DARPA TC datasets (CADETS, THEIA, CLEARSCOPE) through a sequential pipeline: graph construction → node/edge featurization → GNN training/testing → evaluation → attack reconstruction.

## Architecture & Pipeline
The system follows a strict dependency chain configured in `src/config.py::TASK_DEPENDENCIES`:
1. **Graph Construction** (`src/graph_construction/`) - Builds temporal graphs from PostgreSQL audit data
2. **Edge Featurization** (`src/edge_featurization/`) - Creates Word2Vec embeddings for nodes/edges  
3. **Detection** (`src/detection/`) - GNN training, testing, and evaluation
4. **Attack Reconstruction** (`src/attack_reconstruction/`) - Traces attack paths using dependency impact analysis

**Key Pattern**: Each stage creates artifacts in `ROOT_ARTIFACT_DIR` with hash-based paths for reproducibility. Stages depend on previous outputs and use `cfg._task_path` for file organization.

## Configuration System
- **Primary config**: `config/orthrus.yml` - hierarchical YAML with all hyperparameters
- **CLI overrides**: Use dot notation: `--detection.gnn_training.lr=0.001`
- **Dataset configs**: `DATASET_DEFAULT_CONFIG` in `src/config.py` defines train/val/test splits, ground truth paths
- **Database config**: Edit `DATABASE_DEFAULT_CONFIG` for PostgreSQL credentials

**Critical**: The `yacs` config system requires all parameters to have defaults. Check `TASK_ARGS` structure when adding new config options.

## Development Workflows

### Running Experiments
```bash
# Full pipeline (Docker recommended)
python src/orthrus.py CADETS_E3 --wandb

# Skip preprocessing (when graphs exist)
python src/orthrus.py CADETS_E3 --run_from_training

# Use pre-trained weights
python src/orthrus.py CADETS_E3 --from_weights
```

### Module-by-Module Execution
Always set `PYTHONPATH=src` and run from project root:
```bash
PYTHONPATH=src python src/graph_construction/build_orthrus_graphs.py CADETS_E3
PYTHONPATH=src python src/detection/orthrus_gnn_training.py CADETS_E3
```

### Database Setup
1. Use PostgreSQL dumps from PIDSMaker for quick setup
2. Initialize: `postgres/init_databases.sh && postgres/load_dumps.sh`
3. Alternative: Parse raw JSON: `PYTHONPATH=src python src/create_database.py CADETS_E3`

## Critical Patterns

### Model Architecture
- **Encoder**: `OrthrusEncoder` (GAT-based) processes temporal graphs with edge features
- **Decoder**: Edge type prediction for anomaly detection
- **Loss**: Binary classification on edge reconstruction quality
- **Key files**: `src/model.py`, `src/encoders.py`, `src/decoders.py`

### Data Flow
- **Input**: PostgreSQL tables (subject_node_table, file_node_table, netflow_node_table, edge_table)
- **Graph format**: NetworkX → PyTorch Geometric conversion in `src/data_utils.py`
- **Batching**: Custom temporal batching in `factory.py::batch_loader_factory()`

### Reproducibility Requirements
- Set `PYTHONHASHSEED=0` for Gensim Word2Vec consistency
- Use `--seed` parameter for PyTorch reproducibility
- Artifact paths include config hashes to prevent cache conflicts

## Integration Points

### External Dependencies
- **PostgreSQL**: Primary data storage, requires specific schema (see `src/create_database/`)
- **Weights & Biases**: Experiment tracking, disable with `WANDB_MODE=disabled`
- **Docker**: Preferred deployment via `compose-pidsmaker.yml`

### File Locations
- **Weights**: `weights/` directory for pre-trained models
- **Ground Truth**: `Ground_Truth/darpa/` with attack node CSVs
- **Artifacts**: Configurable via `ROOT_ARTIFACT_DIR` in `src/config.py`

### Key Helper Utilities
- `src/provnet_utils.py`: Graph operations, hashing, logging
- `src/factory.py`: Model, optimizer, and data loader factories
- `src/temporal.py`: Time-window graph processing

## Dataset-Specific Considerations
- **CADETS_E3**: Baseline dataset, well-balanced attacks
- **THEIA_E3/E5**: Larger scale, network-heavy attacks  
- **CLEARSCOPE_E3/E5**: Browser-based attacks, different node patterns
- Each dataset has specific train/val/test splits and ground truth files in `config.py`

## Common Issues & Debugging
- **CUDA/MPS**: Check `get_device()` in `src/provnet_utils.py` for GPU setup
- **Memory**: Large datasets may require gradient checkpointing or smaller batch sizes
- **Path errors**: Always use absolute paths; check `cfg._task_path` generation
- **Config validation**: `validate_yml_file()` catches type mismatches and None values

## Testing & Evaluation
Expected MCC scores: CADETS_E3 ~0.47, THEIA_E3 ~0.43. Results in `data/{DATASET}/evaluation/metrics.json`. Use `src/detection/evaluation.py` for custom metrics.