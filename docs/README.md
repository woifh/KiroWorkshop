# API Documentation

This directory contains auto-generated API documentation for the Events API backend.

## Generated with pdoc

The documentation is generated using [pdoc](https://pdoc.dev/) from the Python source code.

## Viewing the Documentation

Open `index.html` in your web browser to view the documentation.

## Modules

- **main.py** - FastAPI application with all API endpoints
- **models.py** - Pydantic models for request/response validation
- **database.py** - DynamoDB client for data operations

## Regenerating Documentation

To regenerate the documentation after code changes:

```bash
cd backend
python3 -m pdoc main models database -o ../docs
```

## Requirements

```bash
pip install pdoc
```
