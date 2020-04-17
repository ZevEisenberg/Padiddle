LOGFILE=~/Desktop/logfile.txt

function version {
    echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }';
}

# Don’t run on iOS devices.
if [[ "${SDKROOT}" != *"simulator"* ]]; then
    exit 0
fi

# Don’t run on iOS versions before 13.
if [ $(version "${TARGET_DEVICE_OS_VERSION}") -ge $(version "13") ]; then
    xcrun simctl boot "${TARGET_DEVICE_IDENTIFIER}"
    xcrun simctl status_bar "${TARGET_DEVICE_IDENTIFIER}" clear
fi
