# 🔁 OpenRewrite Git Migration Runner

This project provides a **generic automation runner** to apply [OpenRewrite](https://docs.openrewrite.org/) recipes on one or more Git repositories.

Use this when you want to automate:
- ✅ Spring Framework or Boot upgrades (e.g., Spring 5 → 6)
- ✅ Jakarta EE migrations
- ✅ Gradle dependency and wrapper upgrades
- ✅ Java 8 → 17 migrations
- ✅ XML, JSP, TLD, or any custom file transformations
- ✅ Custom code cleanups or modernization
- ✅ Batch refactoring across multiple repositories

---

## 🏗️ Folder Structure
```bash 

rewrite-runner/
├── custom-recipe/
│   ├── build.gradle
│   └── src/main/java/org/example/CustomTldAndJspMigrationRecipe.java
├── init.gradle
├── migrate.sh
├── repos.txt
├── output/                # Cloned + migrated repos will be stored here
└── README.md
```
---

## ⚙️ Prerequisites

Ensure you have the following installed:
- Java 17+ (required by OpenRewrite)
- Gradle 7+
- Git CLI
- Internet access (to download rewrite libraries)

---

## 🚀 Getting Started

### 1. Clone this Runner

```bash
git clone https://github.com/your-org/rewrite-runner.git
cd rewrite-runner
```
---
### 2. List Git Repos to Migrate

Use HTTPS or SSH (depending on your access). One repo per line.

https://github.com/your-org/project-a.git
https://github.com/your-org/project-b.git
---
### 3. Pre-configured Recipes
This runner is pre-configured with the following recipes:
```bash
rewrite {
activeRecipe(
"org.openrewrite.java.spring.framework.UpgradeSpringFramework_6_0",
"org.openrewrite.java.spring.security6.UpgradeSpringSecurity_6_0",
"org.openrewrite.java.migrate.jakarta.JavaxMigrationToJakarta",
"org.openrewrite.gradle.UpdateGradleDependency",
"org.openrewrite.gradle.plugins.UpgradeGradleWrapper",
"org.example.CustomTldAndJspMigrationRecipe" // Example custom recipe
)
}
```
---
### 4. Add Custom Recipe (Optional)
The following custom recipe is currently available at the following path, this is to convert 
File: custom-recipe/src/main/java/org/recipe/CustomTldAndJspMigrationRecipe.java

### Build the Recipe
```bash

 cd custom-recipe
 ./gradlew build
 cd ..
```
This generates:
custom-recipe/build/libs/custom-recipe-1.0.0.jar

No publishing required — it’s loaded via local flatDir.

### 5. Run the Migration

```bash

  chmod +x migrate.sh
./migrate.sh
```

This will:
1.	Clone each repo into output/
2.	Build and inject the custom recipe (if any)
3.	Apply all configured OpenRewrite recipes
4.	Leave changes in-place for you to commit or verify

---

## 📁 Output
After migration, check:

````bash

output/
├── project-a/
│   └── [modified files]
└── project-b/
    └── [modified files]
    
````