#!/usr/bin/env Rscript
# Custom script to build R package manual with custom fonts
# This script builds the PDF manual with Charter (Georgia-like) and Roboto fonts

# Get package info
pkg_name <- "PowerAnalysisTool"
pkg_dir <- normalizePath(".")

# Create output directory
manual_dir <- file.path(pkg_dir, "inst", "doc")
if (!dir.exists(manual_dir)) {
  dir.create(manual_dir, recursive = TRUE)
}

# Custom LaTeX options for Rd2pdf
# This includes our custom style file
Sys.setenv(
  RD2PDF_INPUTENC = "utf8",
  RD_ENCODING = "UTF-8"
)

# Build the manual with custom options
manual_file <- file.path(manual_dir, paste0(pkg_name, "-manual.pdf"))

# Create a temporary custom Rd.sty that includes our fonts
custom_sty_path <- file.path(pkg_dir, "inst", "resources", "Rd_custom.sty")

message("Building PDF manual with custom fonts...")
message("  Body font: Charter (Georgia-like)")
message("  Header font: Roboto")
message("  Code font: Inconsolata")

# Use R CMD Rd2pdf with custom options
system2(
  "R",
  args = c(
    "CMD", "Rd2pdf",
    "--no-preview",
    "--force",
    sprintf("--RdMacros=%s", custom_sty_path),
    sprintf("--output=%s", manual_file),
    pkg_dir
  )
)

if (file.exists(manual_file)) {
  message(sprintf("\nSuccess! Manual created: %s", manual_file))
  message(sprintf("File size: %.1f KB", file.size(manual_file) / 1024))
} else {
  stop("Failed to create manual")
}
