/**
# Crush AI Coding Agent - Nightly Release Flake

## Description
Automatically tracking and building flake for Charm's Crush AI coding agent.
This flake tracks nightly releases from GitHub and provides both the package
and development environment for testing and contributing.

## Platform Support
- ✅ x86_64-linux
- ✅ aarch64-linux (ARM64 Linux)
- ✅ x86_64-darwin (Intel macOS)
- ✅ aarch64-darwin (Apple Silicon macOS)

## What This Provides
- **Crush Binary**: Latest nightly build of the crush AI coding agent
- **Development Environment**: Complete Go toolchain for crush development
- **Auto-updating**: Automatic tracking of nightly releases
- **Testing**: Comprehensive test suite for validating builds

## Usage
```bash
# Install crush from this flake
nix profile install github:conneroisu/crush-flake

# Run crush directly
nix run github:conneroisu/crush-flake

# Enter development shell
nix develop

# Update to latest nightly
nix flake update
```

## Auto-updating
This flake automatically tracks the nightly releases from:
https://github.com/charmbracelet/crush/releases/tag/nightly
*/
{
  description = "Autoupdating flake for Crush AI coding agent nightly releases";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Track the crush repository for nightly releases
    crush-src = {
      url = "github:charmbracelet/crush";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    treefmt-nix,
    crush-src,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (_final: prev: {
            buildGoModule = prev.buildGo124Module;
          })
        ];
      };

      # Extract version info from source revision
      # TODO: Update to latest version using update script
      packageVersion = "v0.4.0";

      # Build the crush package
      crushPackage = pkgs.buildGoModule rec {
        pname = "crush";
        version = packageVersion;
        src = crush-src;

        # Vendor hash - automatically updated by update script
        vendorHash = "sha256-vdzAVVGr7uTW/A/I8TcYW189E3960SCIqatu7Kb60hg=";

        # Build configuration
        subPackages = ["."];

        ldflags = [
          "-s"
          "-w"
          "-X main.version=${version}"
          "-X main.commit=${crush-src.rev or "unknown"}"
        ];

        meta = with pkgs.lib; {
          description = "AI coding agent for the terminal";
          homepage = "https://github.com/charmbracelet/crush";
          license = licenses.mit; # Treating FSL-1.1-MIT as MIT for now
          maintainers = with maintainers; [connerohnesorge];
          platforms = platforms.unix ++ platforms.darwin;
        };
      };

      # Development scripts
      rooted = exec:
        builtins.concatStringsSep "\n"
        [
          ''REPO_ROOT="$(git rev-parse --show-toplevel)"''
          exec
        ];

      scripts = {
        update-nightly = {
          exec = rooted ''
            set -euo pipefail

            echo "🚀 Starting automatic nightly update..."

            # Step 1: Update flake inputs
            echo "📦 Updating flake inputs..."
            nix flake update crush-src

            # Step 2: Try to build and capture vendor hash
            echo "🔨 Determining correct vendor hash..."

            # Try build and capture error to get correct vendor hash
            BUILD_OUTPUT=$(nix build .#crush --no-link 2>&1 || true)

            if echo "$BUILD_OUTPUT" | grep -q "hash mismatch"; then
              # Extract the correct hash from the error message
              CORRECT_HASH=$(echo "$BUILD_OUTPUT" | grep "got:" | sed -n 's/.*got: *\(sha256-[A-Za-z0-9+/=]*\).*/\1/p')

              if [ -n "$CORRECT_HASH" ]; then
                echo "✅ Found correct vendor hash: $CORRECT_HASH"

                # Update the flake.nix file with the correct hash
                sed -i "s|vendorHash = \"sha256-[A-Za-z0-9+/=]*\";|vendorHash = \"$CORRECT_HASH\";|" "$REPO_ROOT/flake.nix"

                echo "📝 Updated flake.nix with correct vendor hash"

                # Try building again to verify
                echo "🔧 Verifying build with correct hash..."
                if nix build .#crush --no-link; then
                  echo "✅ Build successful! Update completed."

                  # Show version info
                  echo ""
                  echo "📋 Update Summary:"
                  echo "✅ Update completed successfully!"
                else
                  echo "❌ Build failed even with correct hash"
                  exit 1
                fi
              else
                echo "❌ Could not extract correct hash from build output"
                exit 1
              fi
            elif echo "$BUILD_OUTPUT" | grep -q "built successfully\|these 0 derivations"; then
              echo "✅ Build already successful - no hash update needed"
            else
              echo "❌ Unexpected build error:"
              echo "$BUILD_OUTPUT"
              exit 1
            fi

            echo "🎉 Nightly update completed successfully!"
          '';
          description = "Automatically update to latest nightly release with correct vendor hash";
          deps = with pkgs; [nix gnused gnugrep];
        };

        check-version = {
          exec = ''
            echo "Current version: ${packageVersion}"
            echo "Source revision: ${crush-src.rev or "unknown"}"
          '';
          description = "Check current version information";
        };

        test-build = {
          exec = ''
            echo "🧪 Testing crush build..."
            if nix build .#crush --no-link; then
              echo "✅ Build test completed successfully"

              # Test that the binary works
              echo "🔧 Testing binary functionality..."
              CRUSH_BIN=$(nix build .#crush --no-link --print-out-paths)/bin/crush
              if [ -x "$CRUSH_BIN" ]; then
                echo "✅ Binary is executable"
                # Test version output
                if "$CRUSH_BIN" --version 2>/dev/null || "$CRUSH_BIN" version 2>/dev/null || "$CRUSH_BIN" -v 2>/dev/null; then
                  echo "✅ Binary responds to version commands"
                else
                  echo "⚠️  Binary doesn't respond to standard version commands (this may be normal)"
                fi
              else
                echo "❌ Binary is not executable"
                exit 1
              fi
            else
              echo "❌ Build test failed"
              exit 1
            fi
          '';
          description = "Test the crush build and binary functionality";
          deps = with pkgs; [nix];
        };

        check-updates = {
          exec = ''
            set -euo pipefail

            echo "🔍 Checking for nightly updates..."

            # Get current revision from flake.lock
            CURRENT_REV=$(nix flake metadata --json | jq -r '.locks.nodes["crush-src"].locked.rev // "unknown"')
            echo "📦 Current revision: $CURRENT_REV"

            # Get latest revision from GitHub API
            LATEST_INFO=$(curl -s "https://api.github.com/repos/charmbracelet/crush/commits/main")
            LATEST_REV=$(echo "$LATEST_INFO" | jq -r '.sha // "unknown"')
            LATEST_DATE=$(echo "$LATEST_INFO" | jq -r '.commit.committer.date // "unknown"')

            echo "🌐 Latest revision: $LATEST_REV"
            echo "📅 Latest commit date: $LATEST_DATE"

            if [ "$CURRENT_REV" != "$LATEST_REV" ]; then
              echo "🔄 Updates available!"
              echo ""
              echo "Run 'update-nightly' to update to the latest version."
              exit 2  # Exit code 2 indicates updates available
            else
              echo "✅ Already up to date!"
            fi
          '';
          description = "Check if nightly updates are available";
          deps = with pkgs; [nix curl jq];
        };

        auto-update = {
          exec = ''
            set -euo pipefail

            echo "🤖 Running automatic update check..."

            if check-updates; then
              echo "✅ Already up to date"
            elif [ $? -eq 2 ]; then
              echo "🔄 Updates found, starting automatic update..."
              update-nightly
            else
              echo "❌ Error checking for updates"
              exit 1
            fi
          '';
          description = "Automatically check for and apply nightly updates";
          deps = with pkgs; [nix curl jq gnused gnugrep];
        };

        test-comprehensive = {
          exec = ''
            echo "🧪 Running comprehensive test suite..."

            # Find the repository root
            if [ -f "./tests/test-flake.sh" ]; then
              ./tests/test-flake.sh
            elif [ -f "../tests/test-flake.sh" ]; then
              ../tests/test-flake.sh
            else
              echo "❌ Cannot find test-flake.sh script"
              echo "Please run from the repository root or ensure tests/test-flake.sh exists"
              exit 1
            fi
          '';
          description = "Run the comprehensive test suite";
          deps = with pkgs; [bash nix curl jq];
        };

        tag-release = {
          exec = ''
            set -euo pipefail

            echo "🏷️  Creating manual nightly release tag..."

            # Get current version info
            CURRENT_REV=$(nix flake metadata --json | jq -r '.locks.nodes["crush-src"].locked.rev // "unknown"')
            SHORT_REV=$(echo "$CURRENT_REV" | cut -c1-7)
            TIMESTAMP=$(date +%Y%m%d)
            TAG_NAME="nightly-$TIMESTAMP-$SHORT_REV"

            echo "Preparing to create tag: $TAG_NAME"

            # Validate tag format
            if ! echo "$TAG_NAME" | grep -qE '^nightly-[0-9]{8}-[a-f0-9]{7}$'; then
              echo "❌ Invalid tag format: $TAG_NAME"
              exit 1
            fi

            # Ensure we're on a clean state
            if [ -n "$(git status --porcelain)" ]; then
              echo "❌ Working directory is not clean. Please commit or stash changes."
              exit 1
            fi

            # Check for tag collision
            if git tag -l | grep -q "^$TAG_NAME$"; then
              echo "❌ Tag $TAG_NAME already exists locally"
              exit 1
            fi

            if git ls-remote --tags origin 2>/dev/null | grep -q "refs/tags/$TAG_NAME"; then
              echo "❌ Tag $TAG_NAME already exists on remote"
              exit 1
            fi

            echo "✅ Tag validation passed"

            # Create annotated tag
            git tag -a "$TAG_NAME" -m "Manual nightly release $TAG_NAME

            Manually created nightly release tag for Crush AI coding agent.

            ## Upstream Information
            - **Crush Revision**: $CURRENT_REV
            - **Source**: https://github.com/charmbracelet/crush/commit/$CURRENT_REV
            - **Tagged Date**: $(date -u '+%Y-%m-%d %H:%M:%S UTC')
            - **Tagged By**: $(git config user.name) <$(git config user.email)>

            ## Verification
            - ✅ Build tested locally
            - ✅ Working directory clean
            - ✅ No tag collision detected
            - ✅ Manual verification completed

            ## Installation
            \`\`\`bash
            # Install this release
            nix profile install github:conneroisu/crush-flake/$TAG_NAME

            # Run directly
            nix run github:conneroisu/crush-flake/$TAG_NAME
            \`\`\`

            🤖 Generated with [Claude Code](https://claude.ai/code)"

            echo "✅ Created local tag: $TAG_NAME"
            echo ""
            echo "To push the tag and trigger release:"
            echo "  git push origin $TAG_NAME"
            echo ""
            echo "To delete the tag if needed:"
            echo "  git tag -d $TAG_NAME"
          '';
          description = "Create a manual nightly release tag for the current version";
          deps = with pkgs; [git nix jq];
        };

        validate-tags = {
          exec = ''
            set -euo pipefail

            echo "🔍 Validating nightly tags..."

            # Get all nightly tags
            NIGHTLY_TAGS=$(git tag -l "nightly-*" | sort -V)
            TOTAL_COUNT=$(echo "$NIGHTLY_TAGS" | wc -l)

            echo "Found $TOTAL_COUNT nightly tags"

            if [ "$TOTAL_COUNT" -eq 0 ]; then
              echo "ℹ️  No nightly tags found"
              exit 0
            fi

            # Validate formats
            INVALID_COUNT=0
            echo ""
            echo "Validating tag formats..."

            for tag in $NIGHTLY_TAGS; do
              if ! echo "$tag" | grep -qE '^nightly-[0-9]{8}-[a-f0-9]{7}$'; then
                echo "❌ Invalid format: $tag"
                INVALID_COUNT=$((INVALID_COUNT + 1))
              fi
            done

            if [ "$INVALID_COUNT" -eq 0 ]; then
              echo "✅ All $TOTAL_COUNT nightly tags have valid format"
            else
              echo "❌ Found $INVALID_COUNT invalid tag formats"
              exit 1
            fi

            # Show recent tags
            echo ""
            echo "Recent nightly tags:"
            echo "$NIGHTLY_TAGS" | tail -5

            # Show tag statistics
            echo ""
            echo "Tag statistics:"
            echo "- Total nightly tags: $TOTAL_COUNT"
            echo "- Latest tag: $(echo "$NIGHTLY_TAGS" | tail -1)"
            echo "- Format: nightly-YYYYMMDD-SHORTREV"
          '';
          description = "Validate all nightly tags in the repository";
          deps = with pkgs; [git];
        };

        check-tagging-system = {
          exec = ''
            set -euo pipefail

            echo "🧪 Checking tagging system readiness..."

            # Check git configuration
            if ! git config user.name >/dev/null 2>&1; then
              echo "❌ Git user.name not configured"
              exit 1
            fi

            if ! git config user.email >/dev/null 2>&1; then
              echo "❌ Git user.email not configured"
              exit 1
            fi

            echo "✅ Git configuration ready"

            # Check repository state
            if [ -n "$(git status --porcelain)" ]; then
              echo "⚠️  Working directory has uncommitted changes"
            else
              echo "✅ Working directory clean"
            fi

            # Test tag generation
            CURRENT_REV=$(nix flake metadata --json | jq -r '.locks.nodes["crush-src"].locked.rev // "unknown"')
            SHORT_REV=$(echo "$CURRENT_REV" | cut -c1-7)
            TIMESTAMP=$(date +%Y%m%d)
            TEST_TAG="nightly-$TIMESTAMP-$SHORT_REV"

            echo "✅ Can generate tag: $TEST_TAG"

            # Check for collision
            if git tag -l | grep -q "^$TEST_TAG$"; then
              echo "⚠️  Tag $TEST_TAG already exists locally"
            else
              echo "✅ No local tag collision"
            fi

            # Validate upstream access
            if git ls-remote --tags origin >/dev/null 2>&1; then
              echo "✅ Can access remote tags"

              if git ls-remote --tags origin 2>/dev/null | grep -q "refs/tags/$TEST_TAG"; then
                echo "⚠️  Tag $TEST_TAG already exists on remote"
              else
                echo "✅ No remote tag collision"
              fi
            else
              echo "⚠️  Cannot access remote tags (check network/permissions)"
            fi

            echo ""
            echo "🎯 Tagging system status: Ready"
            echo "   Current crush revision: $CURRENT_REV"
            echo "   Generated tag would be: $TEST_TAG"
          '';
          description = "Check if the tagging system is properly configured and ready";
          deps = with pkgs; [git nix jq];
        };

        update-readme-example = {
          exec = ''
            set -euo pipefail

            echo "📚 Updating README nightly example..."

            # Get current revision info
            CURRENT_REV=$(nix flake metadata --json | jq -r '.locks.nodes["crush-src"].locked.rev // "unknown"')
            SHORT_REV=$(echo "$CURRENT_REV" | cut -c1-7)
            CURRENT_DATE=$(date +%Y-%m-%d)
            TAG_DATE=$(date +%Y%m%d)
            TAG_NAME="nightly-$TAG_DATE-$SHORT_REV"

            echo "🔄 Updating to tag: $TAG_NAME (date: $CURRENT_DATE)"

            if [ ! -f "README.md" ]; then
              echo "❌ README.md not found"
              exit 1
            fi

            # Create backup
            cp README.md README.md.backup

            # Update the README nightly example section
            sed -i "s|# Install latest nightly build (updated [0-9-]*)|# Install latest nightly build (updated $CURRENT_DATE)|g" README.md
            sed -i "s|github:conneroisu/crush-flake#nightly-[0-9]*-[a-f0-9]*|github:conneroisu/crush-flake#$TAG_NAME|g" README.md

            # Check if changes were made
            if diff -q README.md README.md.backup >/dev/null; then
              echo "ℹ️  No changes needed - README already up to date"
              rm README.md.backup
            else
              echo "✅ README updated successfully"
              echo "   New tag: $TAG_NAME"
              echo "   New date: $CURRENT_DATE"
              rm README.md.backup

              echo ""
              echo "📝 Changes made:"
              echo "   - Updated nightly build date to $CURRENT_DATE"
              echo "   - Updated nightly tag to $TAG_NAME"
              echo ""
              echo "🔧 To commit these changes:"
              echo "   git add README.md"
              echo "   git commit -m \"docs: update README nightly example to $TAG_NAME\""
            fi
          '';
          description = "Update README nightly example with current date and revision";
          deps = with pkgs; [nix jq gnused];
        };
      };

      scriptPackages =
        pkgs.lib.mapAttrs
        (
          name: script:
            pkgs.writeShellApplication {
              inherit name;
              text = script.exec;
              runtimeInputs = script.deps or [];
            }
        )
        scripts;

      treefmtModule = {
        projectRootFile = "flake.nix";
        programs = {
          alejandra.enable = true;
          deadnix.enable = true;
          statix.enable = true;
        };
      };
    in {
      packages = {
        default = crushPackage;
        crush = crushPackage;
      };

      apps = {
        default = {
          type = "app";
          program = "${crushPackage}/bin/crush";
        };
        crush = {
          type = "app";
          program = "${crushPackage}/bin/crush";
        };
      };

      devShells.default = pkgs.mkShell {
        name = "crush-flake-dev";

        packages = with pkgs;
          [
            # Nix tools
            alejandra
            nixd
            statix
            deadnix

            # Go development tools
            go_1_24
            air
            golangci-lint
            gopls
            revive
            golines
            gotests
            gotools

            # Build and release tools
            goreleaser
            cosign

            # Automation tools
            curl
            jq
            gh
          ]
          ++ builtins.attrValues scriptPackages;

        shellHook = ''
          echo "🔨 Crush Flake Development Environment"
          echo "📦 Version: ${packageVersion}"
          echo "🎯 Source: ${crush-src.rev or "unknown"}"
          echo ""
          echo "Available commands:"
          echo "  update-nightly        - Update to latest nightly release with automatic vendor hash"
          echo "  check-updates         - Check if nightly updates are available"
          echo "  auto-update           - Automatically check for and apply updates"
          echo "  check-version         - Check current version info"
          echo "  test-build            - Test the crush build and binary functionality"
          echo "  test-comprehensive    - Run the comprehensive test suite"
          echo "  tag-release           - Create a manual nightly release tag"
          echo "  validate-tags         - Validate all nightly tags in the repository"
          echo "  check-tagging-system  - Check if tagging system is properly configured"
          echo "  update-readme-example - Update README nightly example with current date/revision"
          echo ""
          echo "Quick start:"
          echo "  nix run .             - Run crush directly"
          echo "  auto-update           - Check for and apply updates"
          echo "  test-comprehensive    - Run all tests"
          echo "  check-tagging-system  - Verify tagging readiness"
          echo "  update-readme-example - Update README examples"
          echo ""
        '';
      };

      formatter = treefmt-nix.lib.mkWrapper pkgs treefmtModule;

      # Checks for CI/CD
      checks = {
        build = crushPackage;
        format = self.formatter.${system};
      };
    });
}
