# via https://www.detroitlabs.com/blog/2019/09/19/fixing-simulator-status-bars-for-app-store-screenshots-with-xcode-11-and-ios-13/ and https://github.com/fastlane/fastlane/issues/15124

function version {
    echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }';
}

# Don’t run on iOS devices.
if [[ "${SDKROOT}" != *"simulator"* ]]; then
    exit 0
fi

# Don’t run on iOS versions before 13.
if [ $(version "${TARGET_DEVICE_OS_VERSION}") -ge $(version "13") ]; then
    # Boot sim to make sure it is running
    xcrun simctl boot "${TARGET_DEVICE_IDENTIFIER}"

    # --operatorName doesn't support empty string, even though it's supposed to. FB7664620
    zeroWidthSpace='\xE2\x80\x8B' # UTF-8 encoding of u+200B in Bash (different format from zsh)

    # 9:41 AM, with the correct date for iPads. Note that this will not be localized to other languages. FB7668656
    timeString="$(date -r 1568122860 +%FT%T%z)"

    xcrun simctl status_bar "${TARGET_DEVICE_IDENTIFIER}" override \
         --time "${timeString}" \
         --dataNetwork wifi \
         --wifiMode active \
         --wifiBars 3 \
         --cellularMode active \
         --operatorName $(echo -e $zeroWidthSpace) \
         --cellularBars 4 \
         --batteryState discharging \
         --batteryLevel 100
fi
