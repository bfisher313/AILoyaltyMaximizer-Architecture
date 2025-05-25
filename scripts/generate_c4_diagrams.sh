#!/bin/bash

# Script to regenerate C4 diagrams from Structurizr DSL via PlantUML
# Assumes this script is run from its location within the /scripts/ directory.

# --- Determine Project Root Directory ---
# This assumes the script is in a /scripts/ subdirectory of the project root.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")" # Moves one level up from /scripts/ to the project root

# --- Configuration (Paths relative to PROJECT_ROOT) ---
STRUCTURIZR_DSL_FILE="$PROJECT_ROOT/diagrams_src/c4_model/c4_architecture.dsl"
PLANTUML_OUTPUT_DIR_INTERMEDIATE="$PROJECT_ROOT/diagrams_src/c4_model/plantuml_intermediate"
FINAL_IMAGE_OUTPUT_DIR="$PROJECT_ROOT/diagrams_output/c4_model_renders"
# Assumes 'plantuml' command is in PATH (e.g., installed via Homebrew)

# --- Script Logic ---

# Ensure output directories exist
mkdir -p "$PLANTUML_OUTPUT_DIR_INTERMEDIATE"
mkdir -p "$FINAL_IMAGE_OUTPUT_DIR"

echo "Starting C4 diagram generation..."
echo "Project Root: $PROJECT_ROOT"
echo "DSL File: $STRUCTURIZR_DSL_FILE"
echo "Intermediate PUML Dir: $PLANTUML_OUTPUT_DIR_INTERMEDIATE"
echo "Final Image Output Dir: $FINAL_IMAGE_OUTPUT_DIR"


# Step 1: Use structurizr-cli to export DSL to PlantUML format
echo "Exporting Structurizr DSL to PlantUML files in $PLANTUML_OUTPUT_DIR_INTERMEDIATE ..."
# It's often best to run structurizr-cli from the directory containing the .dsl file or specify paths carefully.
# Let's cd into the dsl directory, run, then cd back.
CURRENT_DIR=$(pwd)
cd "$(dirname "$STRUCTURIZR_DSL_FILE")"
structurizr-cli export -workspace "$(basename "$STRUCTURIZR_DSL_FILE")" -format plantuml -output "./plantuml_intermediate" # Output relative to current dir (diagrams_src/c4_model/)
cd "$CURRENT_DIR"


if [ $? -ne 0 ]; then
  echo "Error: Structurizr CLI export failed."
  exit 1
fi

echo "Structurizr DSL export to PlantUML complete."

# Step 2: Use plantuml to convert .puml files to .png
echo "Converting PlantUML files to PNG images in $FINAL_IMAGE_OUTPUT_DIR ..."

# Check if any .puml files were generated
if [ -z "$(ls -A $PLANTUML_OUTPUT_DIR_INTERMEDIATE/*.puml 2>/dev/null)" ]; then
  echo "No .puml files found in $PLANTUML_OUTPUT_DIR_INTERMEDIATE to process."
  echo "Cleaning up potentially empty intermediate PlantUML directory..."
  rm -rf "$PLANTUML_OUTPUT_DIR_INTERMEDIATE" # Remove the directory itself
  echo "Intermediate directory cleanup attempted."
  exit 0
fi

# Loop through all .puml files in the intermediate directory
for puml_file in "$PLANTUML_OUTPUT_DIR_INTERMEDIATE"/*.puml; do
  echo "Processing $puml_file ..."
  # Use plantuml command, ensuring output directory is correctly specified
  plantuml "$puml_file" -o "$FINAL_IMAGE_OUTPUT_DIR"

  if [ $? -ne 0 ]; then
    echo "Error: PlantUML conversion failed for $puml_file."
    # Decide if you want to exit on first error or continue
  else
    echo "Successfully generated PNG for $puml_file in $FINAL_IMAGE_OUTPUT_DIR"
  fi
done

echo "PlantUML to PNG conversion complete."

# Step 3: Clean up intermediate PlantUML files
echo "Cleaning up intermediate PlantUML files and directory..."
rm -rf "$PLANTUML_OUTPUT_DIR_INTERMEDIATE"

echo "Intermediate file cleanup complete."
echo "Diagrams generated in $FINAL_IMAGE_OUTPUT_DIR"

exit 0