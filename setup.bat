@echo off
echo === PassCoder Setup ===
echo.

REM Check if Flutter is installed
echo Checking Flutter installation...
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter is not installed
    echo Please install Flutter from https://flutter.dev
    echo Then run this script again
    pause
    exit /b 1
)
echo ✅ Flutter is installed
echo.

REM Check if .env file exists
echo Checking environment configuration...
if exist .env (
    echo ✅ .env file exists
) else (
    echo Creating .env file from template...
    copy .env.example .env >nul
    echo ✅ .env file created
    echo ⚠️  Please edit .env file with your Supabase credentials
)
echo.

REM Install dependencies
echo Installing Flutter dependencies...
flutter pub get
if errorlevel 1 (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)
echo ✅ Dependencies installed successfully
echo.

REM Generate code for models
echo Generating code for models...
dart run build_runner build --delete-conflicting-outputs
echo.

echo === Setup Complete ===
echo.
echo Next steps:
echo 1. Edit .env file with your Supabase URL and anon key
echo 2. Go to your Supabase dashboard
echo 3. Run the SQL migration in supabase/migrations/001_initial_schema.sql
echo 4. Run 'flutter run' to start the app
echo.
echo For more information, see README.md
pause
