#!/bin/bash

# Fitness Hub Website Deployment Script
# This script helps deploy the Fitness Hub website to various hosting platforms

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="fitness-hub"
BUILD_DIR="dist"
BACKUP_DIR="backups"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to create backup
create_backup() {
    if [ -d "$BUILD_DIR" ]; then
        print_status "Creating backup of existing build..."
        mkdir -p "$BACKUP_DIR"
        timestamp=$(date +"%Y%m%d_%H%M%S")
        cp -r "$BUILD_DIR" "$BACKUP_DIR/build_$timestamp"
        print_success "Backup created: $BACKUP_DIR/build_$timestamp"
    fi
}

# Function to prepare build directory
prepare_build() {
    print_status "Preparing build directory..."
    
    # Create build directory if it doesn't exist
    mkdir -p "$BUILD_DIR"
    
    # Copy all HTML, CSS, JS files
    cp *.html "$BUILD_DIR/" 2>/dev/null || true
    cp *.css "$BUILD_DIR/" 2>/dev/null || true
    cp *.js "$BUILD_DIR/" 2>/dev/null || true
    
    # Create assets directory if needed
    mkdir -p "$BUILD_DIR/assets"
    
    # Copy any additional assets
    if [ -d "images" ]; then
        cp -r images "$BUILD_DIR/"
    fi
    
    if [ -d "fonts" ]; then
        cp -r fonts "$BUILD_DIR/"
    fi
    
    print_success "Build directory prepared"
}

# Function to optimize files
optimize_files() {
    print_status "Optimizing files..."
    
    # Minify CSS if csso is available
    if command_exists csso; then
        for css_file in "$BUILD_DIR"/*.css; do
            if [ -f "$css_file" ]; then
                csso "$css_file" --output "$css_file"
                print_success "Minified: $(basename "$css_file")"
            fi
        done
    else
        print_warning "csso not found. CSS files not minified. Install with: npm install -g csso-cli"
    fi
    
    # Minify JS if uglify-js is available
    if command_exists uglifyjs; then
        for js_file in "$BUILD_DIR"/*.js; do
            if [ -f "$js_file" ]; then
                uglifyjs "$js_file" --compress --mangle --output "$js_file"
                print_success "Minified: $(basename "$js_file")"
            fi
        done
    else
        print_warning "uglifyjs not found. JS files not minified. Install with: npm install -g uglify-js"
    fi
}

# Function to validate HTML
validate_html() {
    print_status "Validating HTML files..."
    
    if command_exists html5validator; then
        html5validator --root "$BUILD_DIR" --also-check-css
        print_success "HTML validation completed"
    else
        print_warning "html5validator not found. Install with: pip install html5validator"
    fi
}

# Function to deploy to Netlify
deploy_netlify() {
    print_status "Deploying to Netlify..."
    
    if ! command_exists netlify; then
        print_error "Netlify CLI not found. Install with: npm install -g netlify-cli"
        return 1
    fi
    
    # Login check
    if ! netlify status >/dev/null 2>&1; then
        print_status "Please login to Netlify..."
        netlify login
    fi
    
    # Deploy
    netlify deploy --dir="$BUILD_DIR" --prod
    print_success "Deployed to Netlify successfully!"
}

# Function to deploy to Vercel
deploy_vercel() {
    print_status "Deploying to Vercel..."
    
    if ! command_exists vercel; then
        print_error "Vercel CLI not found. Install with: npm install -g vercel"
        return 1
    fi
    
    # Create vercel.json if it doesn't exist
    if [ ! -f "$BUILD_DIR/vercel.json" ]; then
        cat > "$BUILD_DIR/vercel.json" << EOF
{
  "version": 2,
  "builds": [
    {
      "src": "**/*",
      "use": "@vercel/static"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/\$1"
    }
  ]
}
EOF
        print_status "Created vercel.json configuration"
    fi
    
    cd "$BUILD_DIR"
    vercel --prod
    cd ..
    print_success "Deployed to Vercel successfully!"
}

# Function to deploy to GitHub Pages
deploy_github_pages() {
    print_status "Deploying to GitHub Pages..."
    
    if ! command_exists git; then
        print_error "Git not found. Please install Git."
        return 1
    fi
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a Git repository. Please initialize Git first."
        return 1
    fi
    
    # Create gh-pages branch if it doesn't exist
    if ! git show-ref --verify --quiet refs/heads/gh-pages; then
        git checkout --orphan gh-pages
        git rm -rf .
        git commit --allow-empty -m "Initial gh-pages commit"
        git checkout main 2>/dev/null || git checkout master
    fi
    
    # Deploy to gh-pages
    git checkout gh-pages
    git rm -rf . 2>/dev/null || true
    cp -r "$BUILD_DIR"/* .
    git add .
    git commit -m "Deploy to GitHub Pages - $(date)"
    git push origin gh-pages
    git checkout main 2>/dev/null || git checkout master
    
    print_success "Deployed to GitHub Pages successfully!"
    print_status "Your site will be available at: https://yourusername.github.io/fitness-hub"
}

# Function to deploy to Firebase Hosting
deploy_firebase() {
    print_status "Deploying to Firebase Hosting..."
    
    if ! command_exists firebase; then
        print_error "Firebase CLI not found. Install with: npm install -g firebase-tools"
        return 1
    fi
    
    # Initialize Firebase if firebase.json doesn't exist
    if [ ! -f "firebase.json" ]; then
        print_status "Initializing Firebase..."
        firebase init hosting
    fi
    
    # Update firebase.json to use our build directory
    cat > firebase.json << EOF
{
  "hosting": {
    "public": "$BUILD_DIR",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
EOF
    
    firebase deploy
    print_success "Deployed to Firebase Hosting successfully!"
}

# Function to create FTP deployment script
create_ftp_script() {
    print_status "Creating FTP deployment script..."
    
    cat > deploy_ftp.sh << 'EOF'
#!/bin/bash

# FTP Deployment Configuration
FTP_HOST="your-ftp-host.com"
FTP_USER="your-username"
FTP_PASS="your-password"
FTP_DIR="/public_html"  # Remote directory

# Upload files using lftp
if command -v lftp >/dev/null 2>&1; then
    lftp -c "
    open ftp://$FTP_USER:$FTP_PASS@$FTP_HOST
    lcd dist
    cd $FTP_DIR
    mirror --reverse --delete --verbose
    bye
    "
    echo "FTP deployment completed!"
else
    echo "lftp not found. Install with: sudo apt-get install lftp (Ubuntu/Debian) or brew install lftp (macOS)"
fi
EOF
    
    chmod +x deploy_ftp.sh
    print_success "FTP deployment script created: deploy_ftp.sh"
    print_warning "Please edit deploy_ftp.sh with your FTP credentials before using"
}

# Function to run local server for testing
run_local_server() {
    print_status "Starting local development server..."
    
    cd "$BUILD_DIR"
    
    if command_exists python3; then
        print_status "Starting Python 3 server on http://localhost:8000"
        python3 -m http.server 8000
    elif command_exists python; then
        print_status "Starting Python 2 server on http://localhost:8000"
        python -m SimpleHTTPServer 8000
    elif command_exists node; then
        if command_exists npx; then
            print_status "Starting Node.js server on http://localhost:3000"
            npx serve -s . -l 3000
        else
            print_warning "npx not found. Install serve globally: npm install -g serve"
        fi
    else
        print_error "No suitable server found. Please install Python or Node.js"
    fi
}

# Function to show deployment status
show_status() {
    print_status "Deployment Status:"
    echo "===================="
    
    if [ -d "$BUILD_DIR" ]; then
        echo "✅ Build directory exists"
        echo "📁 Files in build:"
        ls -la "$BUILD_DIR"
    else
        echo "❌ Build directory not found"
    fi
    
    echo ""
    echo "Available deployment options:"
    echo "1. Netlify (netlify)"
    echo "2. Vercel (vercel)"
    echo "3. GitHub Pages (github)"
    echo "4. Firebase Hosting (firebase)"
    echo "5. FTP (create script)"
    echo "6. Local server (local)"
}

# Function to clean build directory
clean_build() {
    print_status "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
    print_success "Build directory cleaned"
}

# Main deployment function
main() {
    echo "🏋️ Fitness Hub Deployment Script 🏋️"
    echo "====================================="
    
    case "${1:-help}" in
        "build")
            create_backup
            prepare_build
            optimize_files
            validate_html
            print_success "Build completed successfully!"
            ;;
        "netlify")
            prepare_build
            deploy_netlify
            ;;
        "vercel")
            prepare_build
            deploy_vercel
            ;;
        "github")
            prepare_build
            deploy_github_pages
            ;;
        "firebase")
            prepare_build
            deploy_firebase
            ;;
        "ftp")
            prepare_build
            create_ftp_script
            ;;
        "local")
            if [ ! -d "$BUILD_DIR" ]; then
                prepare_build
            fi
            run_local_server
            ;;
        "clean")
            clean_build
            ;;
        "status")
            show_status
            ;;
        "help"|*)
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  build     - Build the project for deployment"
            echo "  netlify   - Deploy to Netlify"
            echo "  vercel    - Deploy to Vercel"
            echo "  github    - Deploy to GitHub Pages"
            echo "  firebase  - Deploy to Firebase Hosting"
            echo "  ftp       - Create FTP deployment script"
            echo "  local     - Run local development server"
            echo "  clean     - Clean build directory"
            echo "  status    - Show deployment status"
            echo "  help      - Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 build          # Build the project"
            echo "  $0 netlify        # Deploy to Netlify"
            echo "  $0 local          # Run local server"
            echo ""
            echo "Prerequisites:"
            echo "  - Node.js and npm (for CLI tools)"
            echo "  - Git (for GitHub Pages)"
            echo "  - Platform-specific CLI tools"
            ;;
    esac
}

# Run main function with all arguments
main "$@"