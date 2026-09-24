// Public website CV. From the repository root: npm run cv:build
#import "cv-style.typ": layout
#let style = layout()
#show: style.document
#let section = style.section
#let entry = style.entry
#let bullets = style.bullets

#(style.header)(summary: [
  Mathematician and software engineer with 5+ years of experience in ML, building open-source tooling and on-device inference pipelines. Independent work in scientific computing, GPU kernels, and compilers.
])

#section("Work Experience")
#entry(
  "Senior MLOps Engineer, appliedAI Institute for Europe gGmbH (Munich, DE)",
  "Nov 2022 – present",
  first: true,
  [Developed #link("https://github.com/aai-institute/lakefs-spec")[lakefs-spec] for data versioning and #link("https://github.com/aai-institute/nnbench")[nnbench] for model evaluation (>4k installs/month across both). Currently building on-device pipelines for landscape detail detection in aerial imagery with SAM v1/2, MLX, and BentoML; created a QGIS plugin for the project. Part of the team placing second in the #link("https://ki-allianz.de/hackathon2024/")[KI Kommune 2024] hackathon.],
  tools: [Python, C++, SAM v1/2, QGIS, Docker, Kubernetes, MLflow, JAX, MLX, BentoML.],
)
#entry(
  "Data Engineer / Analyst, Junge Die Bäckerei GmbH (Lübeck, DE-remote)",
  "Jul 2021 – Apr 2026",
  [Advised on a demand forecasting project, and maintained ETL pipelines for review aggregation and data quality assurance.],
  tools: [Python, Windows Server, MSSQL, Prefect, scikit-learn, duckdb.],
)
#entry(
  "Working Student ML Engineer, ZenML GmbH (Munich, DE)",
  "Jun 2020 – Mar 2021",
  [Built a test suite with >80% coverage and ML pipeline components for ZenML’s launch; ran distributed training for predictive maintenance on terabytes of bus data on GCP.],
  tools: [Python, Apache Beam, TensorFlow, TFX, BigQuery, Google Cloud Vertex AI.],
)
#entry(
  "Working Student Modeling & Simulation, Siemens (Munich, DE)",
  "Aug 2017 – Sep 2019",
  [Implemented a C++17 ODE solver for crack propagation and integrated it with Siemens NX CAD; built a real-time ML app with TensorFlow to predict transformer current loss.],
  tools: [Python, C++17, React, TensorFlow, Pandas, Websockets, Siemens NX.],
)

#section("Selected Projects and Contributions")
#entry(
  [#link("https://github.com/nicholasjng/palladium")[Palladium] and #link("https://github.com/nicholasjng/metal-runtime")[metal-runtime] — Compilers and GPU runtimes],
  "Independent projects",
  first: true,
  [Built a compiler that translates JAX/Pallas GPU kernels to Metal, and a C++ runtime with native JAX FFI dispatch, validation against CPU reference results, and batched/concurrent execution.
    #v(8pt)
    On an Apple M1 Pro, this runs an ensemble of 100,000 independent simulations in JAX 40x faster than the CPU-only baseline.],
)
#v(10pt)
#bullets(
  [*Benchmarking:* Maintaining Google Benchmark’s Python bindings; received a Google Open Source Peer Bonus in 2023. Built #link("https://github.com/nicholasjng/mew")[mew] on top of it with a Python API, CLI, and comparison workflow.],
  [*Open source:* Contributed NumPy functionality and numerical solver improvements to #link("https://github.com/jax-ml/jax/pulls?q=is%3Apr+author%3Anicholasjng+is%3Aclosed")[JAX]. Also contributed to MLIR, DuckDB, and nanobind. Authored #link("https://github.com/nicholasjng/nanobind-bazel/")[nanobind-bazel] for creating Python–C++ bindings in Bazel.],
)

#section("Education")
#entry(
  "M.Sc. Mathematics | TUM (Munich, DE) | GPA (US/DE): 3.5/1.5",
  "Oct 2017 – Jun 2020",
  first: true,
  [Study topics: Mathematical modeling, statistics and machine learning, time series analysis, optimization.],
)
#entry(
  "B.Sc. Physics | Bielefeld University (Bielefeld, DE) | GPA (US/DE): 3.2/1.8",
  "Oct 2013 – Sep 2017",
  [Study topics: Theoretical physics, numerical analysis, mathematical modeling.],
)

#section("Skills, Tools & Languages")
#list(indent: 0pt, body-indent: 5pt, tight: false, spacing: 7pt,
  [*Programming:* Python, C++17, TypeScript.],
  [*Frameworks & tools:* JAX/Pallas, MLX, Apple Metal, MLflow, BentoML, nanobind, CMake, Bazel, Docker, Kubernetes, Terraform.],
  [*Spoken languages:* German, English, Norwegian, Danish, Spanish.],
)
