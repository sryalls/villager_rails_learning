#!/bin/bash

# Documentation validation script
echo "🔍 Validating Villager Rails Learning Repository Structure..."

# Check main directories
echo "📁 Checking directory structure..."
dirs=("architecture" "design-patterns" "coding-patterns" "learning-resources" "portfolio" "troubleshooting" "migration-guides" ".github")

for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ $dir/ exists"
    else
        echo "❌ $dir/ missing"
    fi
done

# Check key documentation files
echo ""
echo "📄 Checking key documentation files..."
files=(
    "README.md"
    ".github/copilot-instructions.md"
    "architecture/README.md"
    "design-patterns/README.md"
    "coding-patterns/README.md"
    "learning-resources/README.md"
    "portfolio/README.md"
    "troubleshooting/README.md"
    "troubleshooting/propshaft-compatibility-issue.md"
    "migration-guides/README.md"
    "migration-guides/propshaft-migration.md"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
    fi
done

echo ""
echo "🎯 Documentation repository validation complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Review and customize content for your specific needs"
echo "   2. Add screenshots and examples to portfolio section"
echo "   3. Create additional learning resources as needed"
echo "   4. Set up git repository and push to GitHub"
echo ""
echo "💡 This repository is ready to serve as a comprehensive learning and portfolio resource!"
