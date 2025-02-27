// Function to open the whiteboard
function openWhiteboard() {
    document.getElementById("excalidraw-container").style.display = "block";
    initializeWhiteboard();
  }
  
  // Function to close the whiteboard
  function closeWhiteboard() {
    document.getElementById("excalidraw-container").style.display = "none";
  }
  
  // Initialize Excalidraw whiteboard
  function initializeWhiteboard() {
    const excalidrawApp = new Excalidraw({
      theme: "light",
      width: window.innerWidth - 40,
      height: window.innerHeight - 100,
    });
    document.getElementById("excalidraw").appendChild(excalidrawApp.render());
  }
  