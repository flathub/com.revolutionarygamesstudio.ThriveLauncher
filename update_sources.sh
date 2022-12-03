#!/usr/bin/sh
# Updates the nuget sources based on the Thrive-Launcher submodule in this repo
# Check the script in flatpak-builder-tools/dotnet/flatpak-dotnet-generator.py to see the
# required sdk and dotnet extension versions
(
    set -e

    # This now clones the launcher as having a submodule with LFS breaks Flathub build bot
    # https://github.com/flatpak/flatpak-builder/issues/463
    if [ ! -d Thrive-Launcher ]; then
        echo "Cloning launcher to get required project files..."
        git clone https://github.com/Revolutionary-Games/Thrive-Launcher.git Thrive-Launcher
    fi

    echo "Entering launcher folder"
    cd Thrive-Launcher

    echo "Updating launcher version"
    git checkout master
    git pull
    git submodule update --init --recursive

    # Make sure all submodules are cloned and build works
    echo "Building and extracting nuget packages"
    dotnet build ThriveLauncher.sln
    # We use the whole solution here to make sure the scripts can also run when building
    python3 ../flatpak-builder-tools/dotnet/flatpak-dotnet-generator.py ../nuget_sources.json ThriveLauncher.sln --runtime linux-x64
    # python3 ../flatpak-builder-tools/dotnet/flatpak-dotnet-generator.py ../nuget_sources.json ThriveLauncher/ThriveLauncher.csproj --runtime linux-x64

    # Optional test to see if the launcher works locally, if it
    # doesn't then bad backages probably got written. To resolve the
    # problem the bin and obj folders need to be deleted to make a
    # fully fresh build.
    echo "Running Thrive Launcher to see if packages are correct"
    echo "Please close the window once it appears"
    dotnet run --project ThriveLauncher
)
