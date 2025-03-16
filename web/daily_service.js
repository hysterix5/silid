// Wait for Daily SDK to load before running any code
function waitForDailySdk(callback, retries = 10) {
    if (window.Daily) {
        console.log("✅ Daily SDK loaded successfully!");
        callback();
    } else if (retries > 0) {
        console.warn(`Daily SDK not loaded yet. Retrying... (${10 - retries})`);
        setTimeout(() => waitForDailySdk(callback, retries - 1), 500);
    } else {
        console.error("❌ Failed to load Daily SDK after multiple attempts.");
    }
}
// Function to initialize the call in fullscreen
window.initializeDaily = function (roomUrl, userName) {
    waitForDailySdk(() => {
        console.log("Daily SDK loaded. Initializing call...");

        // Destroy existing call if it exists
        if (window.dailyCall) {
            console.log("Destroying previous Daily call instance...");
            window.dailyCall.destroy();
            window.dailyCall = null;
        }

        // Remove existing iframe container if it exists
        let oldContainer = document.getElementById("daily-container");
        if (oldContainer) {
            oldContainer.remove();
        }

        // Create a new container div for the Daily iframe
        let container = document.createElement('div');
        container.id = "daily-container";
        document.body.appendChild(container);

        // Create the Daily video call frame (fullscreen)
        const call = window.Daily.createFrame(container, {
            iframeStyle: {
                position: 'fixed',
                top: '0',
                left: '0',
                width: '100vw',
                height: '100vh',
                border: 'none',
                zIndex: '9999' // Ensure it's on top
            },
            dailyConfig: {
                micAudioMode: 'music',
            },
            showLeaveButton: true,
            showFullscreenButton: true,
        });

        // Join the room
        call.join({ url: roomUrl,
            userName: userName,
        });

        // Store the call instance globally
        window.dailyCall = call;

        // Listen for events
        call.on('left-meeting', (event) => {
            console.log("Participant left", event);
            window.parent.postMessage(JSON.stringify({ type: 'left-meeting', data: event }), '*');
            destroyDailyCall();
            window.history.back();
        });

        call.on('meeting-ended', () => {
            console.log("Meeting ended");
            window.parent.postMessage(JSON.stringify({ type: 'meeting-ended' }), '*');
            destroyDailyCall();
        });

        // Function to leave the call
        window.leaveCall = function () {
            call.leave();
        };
    });
};

// Function to properly destroy the iframe
function destroyDailyCall() {
    if (window.dailyCall) {
        console.log("Destroying Daily call...");
        window.dailyCall.destroy();
        window.dailyCall = null;
    }
    document.getElementById("daily-container")?.remove();
}

// Listen for browser back navigation to clean up the iframe
window.addEventListener("popstate", () => {
    console.log("User navigated back. Destroying Daily iframe.");
    destroyDailyCall();
});
