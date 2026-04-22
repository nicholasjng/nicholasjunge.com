---
title: 'lakefs-spec: Git for Your Data Lake, from Python'
description: How lakefs-spec makes working with lakeFS branches and versioned data feel as natural as reading a local file.
publishedOn: 2026-04-22
tags: [python, data-engineering, lakeFS, fsspec]
---

If you've ever stared at a broken data pipeline and wondered _which commit of the dataset caused this_, you've felt the pain that lakeFS was built to solve. And if you've wished you could interact with that versioned data lake from Python without wrestling with bespoke SDKs, [lakefs-spec](https://lakefs-spec.org) is the library you've been looking for.

## The problem: data versioning is hard

Modern data teams version their _code_ religiously. Git branches, pull requests, CI pipelines — these are standard practice. But the _data_ that flows through those pipelines? Usually it's a flat S3 bucket where files get overwritten, deleted, or quietly mutated, with no history and no rollback.

[lakeFS](https://lakefs.io) fixes this by adding a Git-like branching model on top of object storage. You get commits, branches, merges, and diffs — but for your Parquet files and CSV exports instead of source code. You can experiment on a `feature/new-etl` branch without touching `main`, and merge when you're confident.

## Enter lakefs-spec

[lakefs-spec](https://lakefs-spec.org) is a Python library that implements the [fsspec](https://filesystem-spec.readthedocs.io) interface for lakeFS. That one sentence is doing a lot of work, so let me unpack it.

**fsspec** is a Python standard for describing filesystems. Libraries like pandas, PyArrow, Dask, and DuckDB all accept fsspec-compatible filesystem objects or URLs. This means that if lakefs-spec speaks fsspec, it speaks the lingua franca of the entire Python data ecosystem.

The practical result: you can pass a `lakefs://` URI directly to pandas, just like you'd pass an S3 or local path:

```python
import pandas as pd

df = pd.read_parquet("lakefs://my-repo/main/data/sales.parquet")
```

That's it. No special client setup in the call site, no custom reader, no boilerplate. The library handles authentication, REST calls to the lakeFS server, and data streaming transparently.

![Architecture diagram showing how lakefs-spec bridges Python code and a lakeFS server with branches](/images/lakefs-spec-arch.svg)

## Transactions: atomic writes across files

Where lakefs-spec really shines is its transaction API. In lakeFS, a "commit" is an atomic snapshot of all files in a repository at a point in time. lakefs-spec lets you write multiple files inside a `transaction` context manager and commit them all at once:

```python
import lakefs_spec

fs = lakefs_spec.LakeFSFileSystem()

with fs.transaction("my-repo", "feature/new-model") as tx:
    # Write interim results
    with fs.open("lakefs://my-repo/feature/new-model/checkpoints/epoch_10.pkl", "wb") as f:
        pickle.dump(model_checkpoint, f)

    # Write final output
    df_results.to_parquet(
        "lakefs://my-repo/feature/new-model/output/predictions.parquet",
        filesystem=fs,
    )
    # tx.commit() is called automatically on context exit
```

If anything inside the block raises an exception, the transaction is rolled back — no partial writes, no corrupted state. This is a property that most data pipelines simply don't have today.

## First-class support for the scientific Python ecosystem

Because lakefs-spec is built on fsspec, the integration points are broad:

```python
import pyarrow.parquet as pq
import lakefs_spec

fs = lakefs_spec.LakeFSFileSystem()

# PyArrow dataset API
dataset = pq.ParquetDataset(
    "my-repo/main/data/",
    filesystem=fs,
)
table = dataset.read()

# DuckDB
import duckdb
duckdb.execute("""
    CREATE SECRET (
        TYPE lakeFS,
        ENDPOINT 'localhost:8000',
        KEY_ID 'your-key',
        SECRET 'your-secret'
    );
    SELECT * FROM read_parquet('lakefs://my-repo/main/data/*.parquet');
""")
```

The DuckDB example shows how a well-implemented fsspec driver ripples outward — tools that already know how to talk to fsspec gain lakeFS support for free.

## Reproducible experiments, finally

One of the most underrated use cases is reproducibility. When you're iterating on a model or ETL job, you want to be able to go back to _exactly_ the data that produced a given result. With lakefs-spec, you commit your data after each experiment run and tag it with a meaningful message:

```python
with fs.transaction("ml-experiments", "experiment/v3-features") as tx:
    df_features.to_parquet(
        "lakefs://ml-experiments/experiment/v3-features/features.parquet",
        filesystem=fs,
    )
    tx.commit(message="v3 feature set: add rolling 7-day window")
```

Now you can `git checkout` the data just as you'd check out a code commit. If experiment v4 is worse, you know exactly where to go back to.

## Getting started

Installation is a single pip command:

```bash
pip install lakefs-spec
```

The library requires a running lakeFS instance, which you can spin up locally with Docker in a few minutes following the [lakeFS quickstart](https://docs.lakefs.io/quickstart/). Once you have that, authentication is handled through environment variables or a config file — lakefs-spec picks up the same credentials that the lakeFS CLI uses.

The [documentation at lakefs-spec.org](https://lakefs-spec.org) is thorough and well-organized, covering everything from basic file operations to advanced topics like credential providers, caching, and integration with specific libraries.

## Why this matters

The combination of lakeFS and lakefs-spec represents a meaningful shift in how data teams can think about their work. The operations that software engineers take for granted — branching, merging, reverting, comparing changes — become available for data. And because lakefs-spec uses fsspec, you don't have to rewrite your pipelines to get there. The data versioning slots in beneath the libraries you already use.

If you work with data at any scale and haven't looked at lakeFS and lakefs-spec yet, I'd strongly encourage you to spend an afternoon with the quickstart. The productivity uplift from being able to say "let me check out the data from last Tuesday's run" is hard to overstate.

[lakefs-spec documentation](https://lakefs-spec.org) · [lakeFS project](https://lakefs.io)
