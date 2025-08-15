# Crush Flake - Autoupdating Nix Flake for Crush AI Coding Agent

[![CI](https://github.com/conneroisu/crush-flake/actions/workflows/ci.yml/badge.svg)](https://github.com/conneroisu/crush-flake/actions/workflows/ci.yml)
[![Update Nightly](https://github.com/conneroisu/crush-flake/actions/workflows/update-nightly.yml/badge.svg)](https://github.com/conneroisu/crush-flake/actions/workflows/update-nightly.yml)
[![Release](https://github.com/conneroisu/crush-flake/actions/workflows/release.yml/badge.svg)](https://github.com/conneroisu/crush-flake/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Nix Flake](https://img.shields.io/badge/Nix-flake-blue?logo=nixos)](https://nixos.org/)
[![Built with Claude Code](https://img.shields.io/badge/Built%20with-Claude%20Code-7C3AED)](https://claude.ai/code)

An automatically updating, comprehensively tested Nix flake for [Charm's Crush AI coding agent](https://github.com/charmbracelet/crush) that tracks nightly releases with full automation and robust testing.

## ✨ Features

- **🔄 Automatic Updates**: Tracks nightly releases from the upstream repository
- **🏗️ Smart Building**: Automatically determines and updates vendor hashes
- **🧪 Comprehensive Testing**: Full test suite with CI/CD integration
- **🏷️ Auto-tagging**: Automated release tagging system
- **🌍 Cross-platform**: Supports Linux (x86_64, aarch64) and macOS (Intel, Apple Silicon)
- **⚡ Fast Development**: Rich development environment with all necessary tools
- **🔍 Update Checking**: Smart update detection and notification system

## 🚀 Quick Start

### Install and Run Crush

```bash
# Install crush from this flake (latest)
nix profile install github:conneroisu/crush-flake

# Or run directly without installing
nix run github:conneroisu/crush-flake

# Or run with specific arguments
nix run github:conneroisu/crush-flake -- --help
```

### Latest Nightly Build

```bash
# Install latest nightly build (updated 2025-08-15)
nix profile install github:conneroisu/crush-flake#nightly-20250815-5f67a58

# Or run latest nightly directly
nix run github:conneroisu/crush-flake#nightly-20250815-5f67a58

# View all available nightly tags
nix flake show github:conneroisu/crush-flake --all-systems
```

### Development Environment

```bash
# Clone and enter development environment
git clone https://github.com/conneroisu/crush-flake.git
cd crush-flake
nix develop

# Available commands in dev shell:
update-nightly      # Update to latest nightly with automatic vendor hash
check-updates       # Check if updates are available
auto-update         # Automatically check for and apply updates
test-comprehensive  # Run full test suite
tag-release         # Create release tag
```

## 🏗️ Architecture

### Automatic Update System

The flake includes a sophisticated update mechanism that:

1. **Tracks Source Changes**: Monitors the upstream repository for new commits
2. **Updates Dependencies**: Automatically updates flake inputs
3. **Determines Vendor Hash**: Attempts build, captures hash mismatch, and updates automatically
4. **Validates Build**: Ensures the updated package builds successfully
5. **Tests Functionality**: Runs comprehensive tests on the new build

### CI/CD Pipeline

- **Nightly Updates**: Automated daily checks for new releases
- **Pull Request Creation**: Automatic PRs for updates with full testing
- **Comprehensive Testing**: Multi-platform build and functionality tests
- **Format Checking**: Automatic code formatting and style validation

## 📋 Usage

### Manual Updates

```bash
# Check for available updates
nix develop --command check-updates

# Update to latest nightly (with automatic vendor hash handling)
nix develop --command update-nightly

# Or do both automatically
nix develop --command auto-update
```

### Testing

```bash
# Run comprehensive test suite
nix develop --command test-comprehensive

# Test just the build
nix develop --command test-build

# Check flake integrity
nix flake check
```

### Release Management

```bash
# Create a release tag for current version
nix develop --command tag-release

# Check current version information
nix develop --command check-version
```

## 🔧 Development

### Project Structure

```
crush-flake/
├── flake.nix                 # Main flake configuration
├── flake.lock               # Locked dependency versions
├── .github/workflows/       # CI/CD automation
│   ├── ci.yml              # General CI pipeline
│   └── update-nightly.yml  # Automatic nightly updates
├── tests/                   # Test suite
│   └── test-flake.sh       # Comprehensive test script
└── README.md               # This file
```

### Key Components

1. **Flake Configuration** (`flake.nix`):
   - Package definition with automatic vendor hash handling
   - Development environment with comprehensive tooling
   - Automation scripts for updates and testing
   - Cross-platform support

2. **Update Automation**:
   - GitHub API integration for tracking releases
   - Smart vendor hash determination
   - Automatic file updates with validation

3. **Testing Infrastructure**:
   - Comprehensive test suite covering all functionality
   - CI/CD integration with multiple test scenarios
   - Cross-platform build verification

4. **Release Management**:
   - Automatic tagging based on upstream versions
   - Changelog generation
   - Version tracking and validation

### Development Workflow

1. **Setup**:
   ```bash
   git clone https://github.com/conneroisu/crush-flake.git
   cd crush-flake
   nix develop
   ```

2. **Make Changes**: Edit `flake.nix` or other files as needed

3. **Test Changes**:
   ```bash
   test-comprehensive  # Run full test suite
   nix flake check     # Validate flake structure
   ```

4. **Update Dependencies**:
   ```bash
   auto-update  # Check for and apply updates
   ```

5. **Create Release**:
   ```bash
   tag-release  # Create release tag
   ```

## 🤖 Automation

### GitHub Actions

The repository includes two main workflows:

1. **CI Pipeline** (`.github/workflows/ci.yml`):
   - Runs on every push and pull request
   - Tests formatting, building, and functionality
   - Validates development shell and scripts

2. **Nightly Updates** (`.github/workflows/update-nightly.yml`):
   - Runs daily at 2 AM UTC
   - Checks for new nightly releases
   - Automatically creates PRs with updates
   - Includes comprehensive testing

### Update Process

The automatic update process follows these steps:

1. **Detection**: Check GitHub API for new commits to main branch
2. **Update**: Update flake inputs to latest revision
3. **Build Attempt**: Try to build with fake vendor hash
4. **Hash Extraction**: Extract correct hash from build error
5. **File Update**: Automatically update `flake.nix` with correct hash
6. **Verification**: Build again to ensure success
7. **Testing**: Run comprehensive test suite
8. **PR Creation**: Create pull request with changes

## 📊 Testing

### Test Coverage

The comprehensive test suite covers:

- ✅ Flake validity and structure
- ✅ Package building and functionality
- ✅ Binary execution and basic operations
- ✅ Development environment setup
- ✅ Script functionality and automation
- ✅ Cross-platform compatibility (evaluation)
- ✅ Formatter and code quality checks
- ✅ Update mechanism operation

### Running Tests

```bash
# Full test suite
nix develop --command test-comprehensive

# Individual test components
nix flake check                    # Flake structure
nix build . --no-link             # Package build
nix develop --command test-build  # Build with functionality test
```

## 🔒 Security

### Considerations

- **Vendor Hash Verification**: Automatic vendor hash updates are validated through build testing
- **Source Integrity**: All sources are verified through Nix's content-addressed storage
- **CI/CD Security**: GitHub Actions run in isolated environments with minimal permissions
- **Update Validation**: All updates go through comprehensive testing before integration

### Safety Features

- **Atomic Updates**: All changes are validated before application
- **Rollback Capability**: Git history allows easy rollback of problematic updates
- **Test Validation**: No updates are applied without passing all tests
- **Manual Override**: All automation can be overridden manually when needed

## 🤝 Contributing

### How to Contribute

1. **Fork the Repository**: Create your own fork of the project
2. **Create Feature Branch**: `git checkout -b feature/amazing-feature`
3. **Make Changes**: Implement your improvements
4. **Test Thoroughly**: Run `test-comprehensive` to ensure everything works
5. **Format Code**: Run `nix fmt` to format all code
6. **Submit PR**: Create a pull request with a clear description

### Development Guidelines

- **Follow TigerStyle**: Adhere to the coding philosophy outlined in CLAUDE.md
- **Test Everything**: All changes must pass the comprehensive test suite
- **Document Changes**: Update documentation for any user-facing changes
- **Atomic Commits**: Make small, focused commits with clear messages

## 📜 License

This project is licensed under the MIT License - see the upstream [Crush project](https://github.com/charmbracelet/crush) for the original license.

## 🙏 Acknowledgments

- **[Charm](https://charm.sh)**: For creating the amazing Crush AI coding agent
- **[Nix Community](https://nixos.org)**: For the incredible Nix ecosystem
- **[TigerBeetle](https://tigerbeetle.com)**: For the TigerStyle development philosophy

## 📚 Additional Resources

- [Crush Project](https://github.com/charmbracelet/crush) - Original Crush repository
- [Nix Flakes](https://nixos.wiki/wiki/Flakes) - Nix Flakes documentation
- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - Comprehensive Nix documentation
- [TigerStyle](https://tigerstyle.dev) - Development philosophy and best practices

---

**Built with ❤️ using [Claude Code](https://claude.ai/code)**
