#!/bin/bash

# Fix markdown files by removing emoji characters
echo "Fixing markdown files..."

# Remove emoji characters from all .md files
find . -name "*.md" -type f -exec sed -i '' 's/[🚀📋🎯🎪🏗️🔄📁🔧🧪🎭🔧🏭📊🎯📞🎉⚠️✅]/ /g' {} \;

# Remove specific emoji patterns
find . -name "*.md" -type f -exec sed -i '' 's/## 🚀/## /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/## 📋/## /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/## 🎯/## /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/## 🎪/## /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/## 🏗️/## /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/## 🔄/## /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/## 📁/## /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/## 🔧/## /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/## 🧪/## /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/## 🎭/## /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/## 🏭/## /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/## 📊/## /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/## 📞/## /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/## ⚠️/## /g' {} \;

# Remove emoji from headers
find . -name "*.md" -type f -exec sed -i '' 's/### 🚀/### /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/### 📋/### /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/### 🎯/### /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/### 🎪/### /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/### 🏗️/### /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/### 🔄/### /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/### 📁/### /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/### 🔧/### /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/### 🧪/### /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/### 🎭/### /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/### 🏭/### /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/### 📊/### /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/### 📞/### /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/### ⚠️/### /g' {} \;

# Remove emoji from list items
find . -name "*.md" -type f -exec sed -i '' 's/- ✅/- /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/- 🚀/- /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/- 📋/- /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/- 🎯/- /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/- 🎪/- /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/- 🏗️/- /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/- 🔄/- /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/- 📁/- /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/- 🔧/- /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/- 🧪/- /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/- 🎭/- /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/- 🏭/- /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/- 📊/- /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/- 📞/- /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/- ⚠️/- /g' {} \;

# Remove emoji from titles
find . -name "*.md" -type f -exec sed -i '' 's/# 🚀/# /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/# 📋/# /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/# 🎯/# /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/# 🎪/# /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/# 🏗️/# /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/# 🔄/# /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/# 📁/# /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/# 🔧/# /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/# 🧪/# /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/# 🎭/# /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/# 🏭/# /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/# 📊/# /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/# 📞/# /g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/# ⚠️/# /g' {} \;

# Remove emoji from bold text
find . -name "*.md" -type f -exec sed -i '' 's/\*\*🎉/\*\*/g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/\*\*🚀/\*\*/g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/\*\*📋/\*\*/g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/\*\*🎯/\*\*/g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/\*\*🎪/\*\*/g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/\*\*🏗️/\*\*/g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/\*\*🔄/\*\*/g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/\*\*📁/\*\*/g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/\*\*🔧/\*\*/g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/\*\*🧪/\*\*/g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/\*\*🎭/\*\*/g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/\*\*🏭/\*\*/g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/\*\*📊/\*\*/g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/\*\*📞/\*\*/g' {} \;
find . -name "*.md" -type f -exec sed -i '' 's/\*\*⚠️/\*\*/g' {} \;

echo "Markdown files fixed!" 