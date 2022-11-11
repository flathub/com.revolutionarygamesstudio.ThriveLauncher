#!/usr/bin/sh
# Updates the nuget sources based on the Thrive-Launcher submodule in this repo
# Check the script in flatpak-builder-tools/dotnet/flatpak-dotnet-generator.py to see the
# required sdk and dotnet extension versions
(
    set -e
    cd Thrive-Launcher
    # Make sure all submodules are cloned and build works
    dotnet build ThriveLauncher.sln
    python3 ../flatpak-builder-tools/dotnet/flatpak-dotnet-generator.py ../nuget_sources.json ThriveLauncher/ThriveLauncher.csproj --runtime linux-x64

    # Optional test to see if the launcher works locally, if it
    # doesn't then bad backages probably got written. To resolve the
    # problem the bin and obj folders need to be deleted to make a
    # fully fresh build.
    echo "Running Thrive Launcher to see if packages are correct."
    echo "Please close the window once it appears"
    dotnet run --project ThriveLauncher
)
