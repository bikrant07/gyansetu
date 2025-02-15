let teacherMode = false; // Track whether the user is in teacher mode
let api; // Jitsi API object
let excalidrawAPI; // Excalidraw API object

// Initialize the Jitsi session
function initializeJitsi(roomName) {
  const container = document.getElementById("jitsi-container");
  container.style.display = "block"; // Show the Jitsi container when class starts

  // Clear any existing Jitsi session
  if (api) {
    api.dispose();
  }

  // Create the Jitsi API object
  api = new JitsiMeetExternalAPI("8x8.vc", {
    roomName: `vpaas-magic-cookie-917959a8cef749a79f042ee34b5d2009/${roomName}`,
    parentNode: container,
    configOverwrite: {
      disableInviteFunctions: true,
      startWithVideoMuted: !teacherMode, // Teachers can start with video/audio on
      startWithAudioMuted: !teacherMode, // Teachers can start with video/audio on
    },
    interfaceConfigOverwrite: {
      TOOLBAR_BUTTONS: teacherMode
        ? ['microphone', 'camera', 'desktop', 'fullscreen', 'chat', 'raisehand', 'settings', 'videoquality', 'filmstrip', 'hangup']
        : ['microphone', 'camera', 'chat', 'raisehand', 'videoquality', 'filmstrip', 'hangup'],
    }
  });
}

// Start the class as a teacher
function startClass(className) {
  teacherMode = true; // Set the user as a teacher
  const roomName = className.replace(/\s+/g, ''); // Format room name
  initializeJitsi(roomName);

  // Show the Excalidraw whiteboard container
  const excalidrawContainer = document.getElementById("excalidraw-container");
  excalidrawContainer.style.display = "block";

  // Initialize Excalidraw whiteboard
  excalidrawAPI = new Excalidraw({
    element: document.getElementById("excalidraw"),
  });

  // Optional: Add a button or function to close the whiteboard
  const closeButton = document.createElement("button");
  closeButton.textContent = "Close Whiteboard";
  closeButton.onclick = closeWhiteboard;
  excalidrawContainer.appendChild(closeButton);
}

// Join the class as a student
function joinClass(className) {
  teacherMode = false; // Set the user as a student
  const roomName = className.replace(/\s+/g, ''); // Format room name
  initializeJitsi(roomName);

  // Hide the Excalidraw whiteboard container for students
  const excalidrawContainer = document.getElementById("excalidraw-container");
  excalidrawContainer.style.display = "none";
}

// Close the whiteboard (optional)
function closeWhiteboard() {
  const excalidrawContainer = document.getElementById("excalidraw-container");
  excalidrawContainer.style.display = "none";
  excalidrawAPI = null; // Clear the Excalidraw instance
}
