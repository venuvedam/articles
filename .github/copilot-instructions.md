# Venu's Articles Repository - Jekyll Site

This is a Jekyll-based GitHub Pages site for hosting articles, blog posts, and technical snippets using the jekyll-theme-hacker theme.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Initial Setup and Dependencies
- Install Ruby gems and Jekyll dependencies:
  - `gem install --user-install jekyll bundler` -- installs Jekyll and Bundler to user directory. Takes ~45 seconds.
  - `export PATH="$HOME/.local/share/gem/ruby/3.2.0/bin:$PATH"` -- adds gem binaries to PATH. ALWAYS run this before Jekyll commands.
  - `bundle config set --local path 'vendor/bundle'` -- configures local gem installation
  - `bundle install` -- installs project dependencies. Takes ~18 seconds fresh, ~1 second subsequent runs.

### Build and Development
- Build the site:
  - `bundle exec jekyll build` -- builds static site to _site/ directory. Takes ~1 second.
  - NEVER CANCEL: Build is very fast (<2 seconds) but set timeout to 60+ seconds for safety
- Develop locally:
  - `bundle exec jekyll serve --host 0.0.0.0 --port 4000` -- starts development server. Takes ~2 seconds to start.
  - Access site at http://localhost:4000
  - Use `--detach` flag to run server in background
  - Stop server with `pkill -f jekyll`
- Live reload during development:
  - `bundle exec jekyll serve --watch` -- automatically rebuilds on file changes

### Project Structure
- `_config.yml` -- Jekyll configuration, sets theme to jekyll-theme-hacker
- `Gemfile` -- Ruby dependencies (jekyll, jekyll-theme-hacker)
- `index.md` -- Homepage content
- `*.md` files -- Article pages (automatically converted to HTML)
- `_site/` -- Generated static site (excluded from git)
- `vendor/` -- Bundler dependencies (excluded from git)

## Validation

### ALWAYS Test Complete Scenarios
- After making content changes, ALWAYS test the complete workflow:
  1. `bundle exec jekyll build` -- verify build succeeds
  2. `bundle exec jekyll serve --detach` -- start development server
  3. `curl -I http://localhost:4000/` -- verify homepage loads (should return 200 OK)
  4. `curl -s http://localhost:4000/ | head -10` -- verify content renders correctly
  5. Test any new article pages: `curl -s http://localhost:4000/article-name.html`
  6. `pkill -f jekyll` -- stop server
- ALWAYS verify that markdown content renders correctly as HTML
- ALWAYS check that code blocks render with proper syntax highlighting

### No Testing Framework Required
- This is a simple Jekyll static site with no test suite
- Validation consists of successful builds and proper page rendering
- GitHub Pages will automatically build and deploy from source

## Critical Deployment Information

### GitHub Pages Integration
- Site automatically deploys to GitHub Pages when pushed to main/master branch
- GitHub Pages uses its own Jekyll build process (no manual build needed for deployment)
- Theme jekyll-theme-hacker is supported by GitHub Pages
- Local development uses same Jekyll version as GitHub Pages for consistency

### File Management
- NEVER commit build artifacts: _site/, vendor/, .bundle/, .jekyll-cache/
- DO commit: source files (*.md), _config.yml, Gemfile, Gemfile.lock
- Gemfile.lock should be committed to ensure consistent dependencies

## Common Tasks

### Adding New Articles
- Create new `.md` file in repository root
- Include YAML front matter:
  ```yaml
  ---
  layout: default
  title: "Article Title"
  date: YYYY-MM-DD
  ---
  ```
- Write content in Markdown format
- Build and test locally before committing

### Customizing Theme
- Override theme files by creating corresponding files in repository
- Theme documentation: https://github.com/pages-themes/hacker
- Common customizations: assets/css/style.scss for CSS overrides

### Troubleshooting
- Bundle install fails: Use `bundle config set --local path 'vendor/bundle'` first
- Jekyll command not found: Ensure PATH includes `$HOME/.local/share/gem/ruby/3.2.0/bin`
- Build warnings about Sass @import: These are deprecation warnings and can be ignored
- Site not loading: Check Jekyll server started successfully and no port conflicts

## Repository Quick Reference

### Repository Structure
```
.
├── .github/
│   └── copilot-instructions.md
├── .gitignore
├── _config.yml          # Jekyll configuration
├── Gemfile              # Ruby dependencies
├── Gemfile.lock         # Locked dependency versions
├── LICENSE              # Apache 2.0 license
├── README.md            # Repository description
├── index.md             # Homepage content
└── *.md                 # Article files
```

### Key Configuration Values
- Theme: `jekyll-theme-hacker`
- Ruby version: 3.2.3
- Jekyll version: 4.4.1
- Bundle path: `vendor/bundle` (local)

### Essential Commands Reference
```bash
# Setup (run once)
export PATH="$HOME/.local/share/gem/ruby/3.2.0/bin:$PATH"
bundle config set --local path 'vendor/bundle'
bundle install

# Development workflow
bundle exec jekyll build    # Build site
bundle exec jekyll serve    # Serve locally
bundle exec jekyll serve --detach  # Background server

# Validation
curl -I http://localhost:4000/      # Test homepage
pkill -f jekyll                     # Stop server
```

### Expected Timing
- Gem installation: 45 seconds (one-time setup)
- Bundle install: 18 seconds (fresh install), 1 second (subsequent runs)
- Jekyll build: 1 second
- Jekyll serve startup: 2 seconds
- NEVER CANCEL: All operations complete quickly, but set 60+ second timeouts for safety