# Orthrus Copilot Instructions

## Project Overview
Orthrus is a provenance-based intrusion detection system using Graph Neural Networks (GNNs) for cybersecurity threat detection in system audit logs. It processes DARPA TC/OpTC datasets through a multi-stage pipeline: graph construction → featurization → detection → attack reconstruction.

## Core Architecture

### Pipeline Stages (Sequential Dependencies)
1. **Graph Construction** (`src/graph_construction/`) - Converts audit logs to time-windowed provenance graphs
2. **Edge Featurization** (`src/edge_featurization/`) - Creates node embeddings via Word2Vec and edge features
3. **Detection** (`src/detection/`) - GNN training/testing with anomaly scoring
4. **Attack Reconstruction** (`src/attack_reconstruction/`) - Post-detection attack path tracing

### Configuration System
- **Primary config**: `config/orthrus.yml` - Hierarchical YAML with task.subtask.parameter structure
- **CLI overrides**: `python src/orthrus.py DATASET --detection.gnn_training.lr=0.001`
- **Runtime config**: `src/config.py` contains `TASK_DEPENDENCIES` and database credentials
- **Key paths**: Set `ROOT_ARTIFACT_DIR` in `config.py` for output location

## Dataset & Database Integration

### Supported Datasets
- DARPA TC: CADETS_E3/E5, THEIA_E3/E5, CLEARSCOPE_E3/E5
- Each dataset requires PostgreSQL database with specific schema
- Ground truth files in `Ground_Truth/darpa/darpa/` for evaluation

### Database Workflow
1. Initialize: `postgres/init_databases.sh` (drops/creates all DBs)
2. Load dumps: `postgres/load_dumps.sh` (from pre-processed dumps)  
3. Parse JSON: `python src/create_database.py DATASET` (raw log processing)

## Development Patterns

### Entry Points
- **Main pipeline**: `python src/orthrus.py DATASET [args]` - Full pipeline execution
- **Skip preprocessing**: `--run_from_training` flag for detection-only runs
- **Component testing**: Individual module execution with `PYTHONPATH=src python ./src/module/script.py`

### Reproducibility Requirements  
- **Critical**: Set `PYTHONHASHSEED=0` for deterministic Word2Vec embeddings
- Seeds controlled via `--seed` parameter and `cfg.detection.gnn_training.use_seed`
- GPU/MPS memory management with explicit cache clearing after training

### Model Architecture
- **Factory pattern**: `src/factory.py` builds encoder/decoder combinations
- **Core model**: `Orthrus` class combines GNN encoder + edge prediction decoder
- **Temporal handling**: Last aggregator for dynamic graph processing
- **Device support**: CUDA, MPS (Apple Silicon), CPU with automatic detection

## Key Conventions

### File Organization
- **Artifacts**: All outputs in `ROOT_ARTIFACT_DIR/dataset_name/` subdirectories
- **Weights**: Pre-trained models loaded with `--from_weights` flag
- **Logs**: W&B integration via `--wandb` flag (requires `wandb login`)

### Error Patterns
- **Database connection**: Check credentials in `config.py` `DATABASE_DEFAULT_CONFIG`
- **Memory issues**: Reduce `batch_size`, `node_hid_dim`, or `time_window_size` in config
- **Reproducibility**: Ensure `PYTHONHASHSEED=0` for consistent results across runs

### Performance Tuning
- **Time windows**: Adjust `time_window_size` (15.0 default) for memory vs. accuracy tradeoff
- **GNN parameters**: Key tunable: `dropout`, `lr`, `node_hid_dim`, `node_out_dim`
- **Parallel processing**: Word2Vec uses `num_workers: 6`, tracing uses `workers: 8`

## Testing & Evaluation
- **Metrics**: MCC (Matthew's Correlation Coefficient) as primary metric
- **Thresholding**: Multiple methods in `node_evaluation.threshold_method`
- **Visualization**: Precision-recall curves, attack reconstruction graphs via W&B
- **Expected results**: See README.md table for dataset-specific benchmarks

## Docker Deployment
- **Container**: Ubuntu 22.04 + Anaconda + Python 3.9 + PostgreSQL 
- **Compose files**: `compose-pidsmaker.yml` for full stack, `compose-postgres.yml` for DB only
- **Entry script**: `run.sh` for containerized execution with W&B logging