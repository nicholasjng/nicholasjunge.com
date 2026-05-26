# Requires the build directory to exist at plan time — run `npm run build` first.
# In CI the build step precedes terraform apply, so this is never a problem.

locals {
  build_dir = "${path.module}/../../build"

  # Filenames (basename only) to exclude from S3 uploads:
  #   .DS_Store — macOS metadata that can slip into build output on local builds
  #   .gitkeep  — empty markers for otherwise-empty directories in the repo
  excluded_files = [".DS_Store", ".gitkeep"]

  build_files = toset([
    for f in fileset(local.build_dir, "**") :
    f if !contains(local.excluded_files, basename(f))
  ])

  # HCL has no built-in MIME detection; this covers everything SvelteKit adapter-static produces.
  mime_types = {
    ".css"         = "text/css"
    ".html"        = "text/html; charset=utf-8"
    ".ico"         = "image/x-icon"
    ".jpeg"        = "image/jpeg"
    ".jpg"         = "image/jpeg"
    ".js"          = "application/javascript"
    ".json"        = "application/json"
    ".png"         = "image/png"
    ".svg"         = "image/svg+xml"
    ".ttf"         = "font/ttf"
    ".txt"         = "text/plain"
    ".webmanifest" = "application/manifest+json"
    ".webp"        = "image/webp"
    ".woff"        = "font/woff"
    ".woff2"       = "font/woff2"
    ".xml"         = "application/xml"
  }
}

resource "aws_s3_object" "site_files" {
  for_each = local.build_files

  bucket = aws_s3_bucket.site.id
  key    = each.value
  source = "${local.build_dir}/${each.value}"
  # etag triggers re-upload when file content changes
  etag = filemd5("${local.build_dir}/${each.value}")

  # try() handles files with no extension (e.g. no-extension manifests)
  content_type = try(
    lookup(local.mime_types, regex("\\.[^.]+$", each.value), "application/octet-stream"),
    "application/octet-stream"
  )

  # .html: revalidate on every request
  # _app/*: SvelteKit content-hashed assets, immutable for 1 year
  # everything else: 1 hour
  cache_control = (
    endswith(each.value, ".html")   ? "public, max-age=0, must-revalidate" :
    startswith(each.value, "_app/") ? "public, max-age=31536000, immutable" :
    "public, max-age=3600"
  )
}
