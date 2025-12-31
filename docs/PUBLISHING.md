# Publishing Guide for Singularity TreeSitter Mermaid (tree-sitter-mermaid)

This document explains how to publish tree-sitter-mermaid to package registries (npm, PyPI, crates.io, Swift Package Manager).

## 📦 Package Registry Status

| Registry | Package Name | Status | Owner | Notes |
|----------|--------------|--------|-------|-------|
| **npm** | `tree-sitter-mermaid` | ✅ Available | Singularity | Ready to publish! |
| **PyPI** | `tree-sitter-mermaid` | ✅ Available | Singularity | Ready to publish! |
| **crates.io** | `tree-sitter-mermaid` | ✅ Available | Singularity | Ready to publish! |
| **Swift PM** | N/A | ✅ Ready | - | Git-based, no registry |

## 🚀 Automated Publishing (Recommended)

All three package registries (npm, PyPI, crates.io) are configured with automated GitHub Actions workflows!

**One-time setup:**
1. Create accounts on npm, PyPI, and crates.io
2. Configure secrets (see setup sections below)
3. Create a GitHub release

**Then every release is automatic!**
```bash
gh release create v0.9.1 --generate-notes
```

This will automatically publish to:
- ✅ npm
- ✅ PyPI (via OIDC - no token needed!)
- ✅ crates.io

See workflows in `.github/workflows/publish-*.yml`

## 📋 Pre-Publishing Checklist

Before publishing to any registry:

- [ ] All tests passing (`make test`) - Currently: ✅ 133/133
- [ ] tree-sitter versions consistent (0.26.x, except Python bindings)
- [ ] Documentation up-to-date (README, ARCHITECTURE, etc.)
- [ ] CHANGELOG updated with release notes
- [ ] Version numbers synchronized across all files
- [ ] License file present (MIT) - ✅ Already present
- [ ] Repository URL correct in all package configs

## 🔧 Publishing to PyPI

### Initial Setup

1. **Create PyPI account**: https://pypi.org/account/register/
2. **Create API token**: https://pypi.org/manage/account/token/
3. **Configure credentials**:
   ```bash
   # Create ~/.pypirc
   cat > ~/.pypirc << 'EOF'
   [pypi]
   username = __token__
   password = pypi-<your-token-here>
   EOF
   chmod 600 ~/.pypirc
   ```

### Build and Publish

```bash
# Clean previous builds
rm -rf dist/ build/ *.egg-info

# Install build tools
pip install --upgrade build twine

# Build source distribution and wheel
python -m build

# Check the built package
twine check dist/*

# Upload to TestPyPI first (recommended)
twine upload --repository testpypi dist/*

# Test install from TestPyPI
pip install --index-url https://test.pypi.org/simple/ tree-sitter-mermaid

# If everything works, upload to real PyPI
twine upload dist/*
```

### Automated PyPI Publishing (GitHub Actions)

**✅ Already configured!** See `.github/workflows/publish-pypi.yml`

Uses **OIDC trusted publishing** (no API token needed). Setup:

1. Go to https://pypi.org/manage/account/publishing/
2. Add trusted publisher:
   - PyPI Project Name: `tree-sitter-mermaid`
   - Owner: `Singularity`
   - Repository: `tree-sitter-mermaid`
   - Workflow: `publish-pypi.yml`
3. Done! Release triggers automatically publish

## 🦀 Publishing to crates.io

**✅ Already configured!** See `.github/workflows/publish-crates.yml`

### Setup

1. Create account at https://crates.io/ (sign in with GitHub)
2. Generate API token: https://crates.io/settings/tokens
3. Add to GitHub repository secrets:
   - Name: `CARGO_REGISTRY_TOKEN`
   - Value: <your token>

Then releases automatically publish!

### Manual Publishing

```bash
# Login to crates.io
cargo login <your-api-token>

# Dry run first (recommended)
cargo publish --dry-run

# Publish
cargo publish
```

## 📦 Publishing to npm

**✅ Already configured!** See `.github/workflows/publish-npm.yml`

### Setup

1. Create account at https://www.npmjs.com/
2. Generate automation token: https://www.npmjs.com/settings/YOUR_USERNAME/tokens
3. Add to GitHub repository secrets:
   - Name: `NPM_TOKEN`
   - Value: <your token>

Then releases automatically publish!

### Manual Publishing

```bash
npm login
npm publish --access public
```

## 🍎 Swift Package Manager

**No action needed!** Swift packages are Git-based. Users can install directly:

```swift
.package(url: "https://github.com/Singularity-ng/singularity-parser-mermaid.git", from: "0.9.1")
```

The package is already configured in `Package.swift`.

## 🏷️ Version Bumping

When releasing a new version, update ALL these files:

```bash
# Automated version bump script
NEW_VERSION="0.9.1"

# Update all version fields
sed -i "s/version = \"[0-9.]*\"/version = \"$NEW_VERSION\"/" Cargo.toml
sed -i "s/\"version\": \"[0-9.]*\"/\"version\": \"$NEW_VERSION\"/" package.json
sed -i "s/version = \"[0-9.]*\"/version = \"$NEW_VERSION\"/" pyproject.toml
sed -i "s/version: \"[0-9.]*\"/version: \"$NEW_VERSION\"/" Package.swift
sed -i "s/VERSION := [0-9.]*/VERSION := $NEW_VERSION/" Makefile

# Commit
git add -A
git commit -m "Bump version to $NEW_VERSION"
git tag "v$NEW_VERSION"
git push origin main --tags
```

## 📝 Release Process

1. **Update version** (see above)
2. **Update CHANGELOG.md**
3. **Run full test suite**: `make test`
4. **Build all bindings** (optional - for local verification):
   ```bash
   cargo build
   npm run build
   python -m build
   ```
5. **Create GitHub Release** (automatically publishes):
   ```bash
   gh release create v0.9.1 --generate-notes
   ```
6. **Workflows automatically publish** to npm, PyPI, and crates.io!

## 🤖 Automated Publishing Workflow

### Recommended Setup

1. **Use GitHub Releases** as the trigger
2. **Automate PyPI** publishing (already yours)
3. **Manual npm/crates.io** (if you get ownership)

### GitHub Secrets Needed

- `PYPI_API_TOKEN` - PyPI trusted publisher token
- `NPM_TOKEN` - npm access token (if publishing)
- `CARGO_REGISTRY_TOKEN` - crates.io token (if publishing)

## 📊 Current Status

As of December 2025:

- ✅ **Package renamed**: `tree-sitter-mermaid` (available on all registries!)
- ✅ **Swift PM**: Ready (Git-based, working)
- ✅ **PyPI**: Ready to publish (automated workflow configured)
- ✅ **npm**: Ready to publish (automated workflow configured)
- ✅ **crates.io**: Ready to publish (automated workflow configured)

## 🎯 Recommended Next Steps

1. **Create accounts** on npm, PyPI, and crates.io
2. **Configure secrets** (NPM_TOKEN, CARGO_REGISTRY_TOKEN)
3. **Set up PyPI trusted publisher** (no token needed!)
4. **Create first release**: `gh release create v0.9.1 --generate-notes`
5. **Automated workflows** will publish to all three registries! 🚀

---

**Questions?** Open an issue or check the [Contributing Guide](CONTRIBUTING.md)
