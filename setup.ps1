# PassCoder Setup Script
# Run this script to set up your development environment

Write-Host "=== PassCoder Setup ===" -ForegroundColor Green
Write-Host ""

# Check if Flutter is installed
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1
    if ($flutterVersion -match "Flutter") {
        Write-Host "✅ Flutter is installed" -ForegroundColor Green
    } else {
        Write-Host "❌ Flutter is not installed" -ForegroundColor Red
        Write-Host "Please install Flutter from https://flutter.dev" -ForegroundColor Yellow
        Write-Host "Then run this script again" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "❌ Flutter is not installed" -ForegroundColor Red
    Write-Host "Please install Flutter from https://flutter.dev" -ForegroundColor Yellow
    Write-Host "Then run this script again" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Check if .env file exists
Write-Host "Checking environment configuration..." -ForegroundColor Yellow
if (Test-Path ".env") {
    Write-Host "✅ .env file exists" -ForegroundColor Green
} else {
    Write-Host "Creating .env file from template..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    Write-Host "✅ .env file created" -ForegroundColor Green
    Write-Host "⚠️  Please edit .env file with your Supabase credentials" -ForegroundColor Yellow
}

Write-Host ""

# Install dependencies
Write-Host "Installing Flutter dependencies..." -ForegroundColor Yellow
flutter pub get
if ($?) {
    Write-Host "✅ Dependencies installed successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Generate code for models
Write-Host "Generating code for models..." -ForegroundColor Yellow
dart run build_runner build --delete-conflicting-outputs
if ($?) {
    Write-Host "✅ Code generation completed" -ForegroundColor Green
} else {
    Write-Host "⚠️  Code generation failed (this is okay for first run)" -ForegroundColor Yellow
}

Write-Host ""

Write-Host "=== Setup Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Edit .env file with your Supabase URL and anon key" -ForegroundColor White
Write-Host "2. Go to your Supabase dashboard" -ForegroundColor White
Write-Host "3. Run the SQL migration in supabase/migrations/001_initial_schema.sql" -ForegroundColor White
Write-Host "4. Run 'flutter run' to start the app" -ForegroundColor White
Write-Host ""
Write-Host "For more information, see README.md" -ForegroundColor Cyan
