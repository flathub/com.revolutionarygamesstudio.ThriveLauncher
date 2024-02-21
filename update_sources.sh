#!/usr/bin/sh
# Updates the nuget sources based on the Thrive-Launcher repo in this repo (will be
# cloned automatically)

# Update this when com.revolutionarygamesstudio.ThriveLauncher.yaml is updated
DOTNET_VERSION="8.0.201"

IMAGE_TYPE="bookworm-slim-amd64"
IMAGE="mcr.microsoft.com/dotnet/sdk:$DOTNET_VERSION-$IMAGE_TYPE"

LAUNCHER_VERSION="v2.1.1"
# LAUNCHER_VERSION="master"

# Run in subshell to prevent this accidentally closing the higher level container (and
# changing the folder of the parent shell)
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

    if [ "$LAUNCHER_VERSION" = "master" ]; then
        echo "Using latest master branch version"
        git checkout master
        git pull
    else
        echo "Using specific launcher version: $LAUNCHER_VERSION"
        git fetch origin
        git checkout "$LAUNCHER_VERSION"
    fi

    git submodule update --init --recursive

    echo "Running build in container for consistent SDK version"
    echo "Using podman image $IMAGE"

    rm -rf ../scripts-output
    mkdir -p ../scripts-output
    podman run --rm --mount type=bind,src=../scripts-output,target=/out,z \
           --mount type=bind,src=.,target=/src,z $IMAGE bash -c \
           'cd /src/ && dotnet restore ThriveLauncher.sln --packages /out -r linux-x64'

    # This old approach no longer works as it isn't maintained
    # We use the whole solution here to make sure the scripts can also run when building
    # python3 ../flatpak-builder-tools/dotnet/flatpak-dotnet-generator.py ../nuget_sources.json \
    #         ThriveLauncher.sln --freedesktop $FREEDESKTOP_RUNTIME --dotnet $DOTNET_VERSION \
    #         --runtime linux-x64
    # python3 ../flatpak-builder-tools/dotnet/flatpak-dotnet-generator.py ../nuget_sources.json \
    #    ThriveLauncher/ThriveLauncher.csproj --runtime linux-x64

    python3 ../flatpak-nuget-source.py ../nuget_sources.json ../scripts-output/

    echo "Extracted nuget package sources from build"
    
    # Optional test to see if the launcher works locally, if it
    # doesn't then bad backages probably got written. To resolve the
    # problem the bin and obj folders need to be deleted to make a
    # fully fresh build.
    echo "Running Thrive Launcher to see if packages are correct"
    echo "Please close the window once it appears"
    dotnet run --project ThriveLauncher
)
