---
type: system-overview
title: Data Processing System
description: Bulk import and export pipelines for documents, transactions, and reports with validation, mapping, and error handling.
tags: [data-processing, import, export, integration, bulk-operations]
openwiki:
  source_paths: [app/Traits/Import, app/Exports, app/Jobs/Common/CreateMediableForExport]
  roles: [domain, integration]
---

# Data Processing System

The data processing system provides infrastructure for bulk importing and exporting Akaunting data. This includes CSV/Excel imports with validation and mapping, as well as document and report exports in multiple formats.

## System Overview

The data processing domain bridges file formats and in-app data:

```
┌────────────────────────┐
│   File (CSV/Excel)     │
└────────────┬───────────┘
             │
     ┌───────▼───────┐
     │  Validation   │
     │  & Mapping    │
     └───────┬───────┘
             │
     ┌───────▼───────────────┐
     │  Data Models          │
     │  (Documents, etc.)    │
     └───────┬───────────────┘
             │
     ┌───────▼───────────────┐
     │  Export Formats       │
     │  (Excel/CSV/PDF)      │
     └───────────────────────┘
```

## Core Components

### Bulk Import

Handles importing documents and transactions from CSV/Excel files:
- **Validation Pipeline**: Row-level and cross-row validation
- **Mapping**: Column-to-field mapping with defaults
- **Error Handling**: Collects errors for batch feedback
- **Transaction Support**: Atomic operations or partial success

**Primary Path**: `app/Traits/Import`

### Bulk Export

Exports documents and reports to Excel, CSV, and PDF:
- **Template-Based**: Leverages existing document/report formatting
- **Filtering**: Optional filters before export
- **Async Processing**: Large exports via jobs
- **Media Files**: Generates temporary files for download

**Primary Path**: `app/Exports`, `app/Jobs/Common/CreateMediableForExport`

## Key Concepts

| Concept | Purpose |
|---------|---------|
| **Import Trait** | Reusable import logic mixed into import jobs |
| **Maatwebsite/Excel** | Backend for Excel file reading/writing |
| **Media** | Temporary files for export downloads; uses Laravel Media Library |
| **Job Dispatch** | Large exports run async via `CreateMediableForExport` |

## Related Systems

- [Documents System](../documents/overview.md) – Import/export document models
- [Banking System](../banking/overview.md) – Transaction import/export
- [Reports System](../reports.md) – Report export formats

## Detailed Pages

- [Bulk Import](imports.md) – CSV/Excel import pipeline with validation
- [Bulk Export](exports.md) – Document and report export formats
