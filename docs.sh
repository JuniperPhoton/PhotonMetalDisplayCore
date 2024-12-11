# Run the xcodebuild command
xcodebuild docbuild -scheme PhotonMetalDisplayCore \
    -derivedDataPath ./.build/derived-data \
    -destination 'generic/platform=iOS' \
    DOCC_HOSTING_BASE_PATH='PhotonMetalDisplayCore'

# Check if the command was successful
if [ $? -eq 0 ]; then
    rm -rf ./docs
    # Find and copy the .doccarchive to the current directory, renaming it to 'docs'
    find ./.build/derived-data -type d -name 'PhotonMetalDisplayCore.doccarchive' -exec cp -R {} ./docs \;
else
    echo "xcodebuild command failed."
fi