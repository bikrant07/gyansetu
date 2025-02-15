// Elements
const runButton = document.getElementById("run");
const languageSelect = document.getElementById("language");
const outputPre = document.getElementById("output");
const editor = document.getElementById("editor");

// Piston API URL
const API_URL = "https://emkc.org/api/v2/piston/execute";

// Basic syntax highlighting function for editor input
function highlightCode(code) {
  // Regular expressions for keywords, numbers, strings, and comments
  const keywordRegex = /\b(if|else|elif|def|return|while|for|class|import|print|int|float|void|double)\b/g;
  const numberRegex = /\b\d+\b/g;
  const stringRegex = /(["'])(?:(?=(\\?))\2.)*?\1/g;
  const commentRegex = /(\/\/[^\n]*)|(#[^\n]*)/g; // Regex to capture single-line comments

  // Highlight keywords
  code = code.replace(keywordRegex, '<span class="keyword">$&</span>');
  // Highlight numbers
  code = code.replace(numberRegex, '<span class="number">$&</span>');
  // Highlight strings
  code = code.replace(stringRegex, '<span class="string">$&</span>');
  // Highlight comments
  code = code.replace(commentRegex, '<span class="comment">$&</span>');

  return code;
}

// Function to execute the code
function runCode() {
  const code = editor.innerText; // Get code from the editable div
  const language = languageSelect.value;

  if (!code.trim()) {
    outputPre.textContent = "Error: Code cannot be empty.";
    return;
  }

  outputPre.textContent = "Running your code...";

  // Send code to Piston API
  fetch(API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      language: language,
      version: "*",
      files: [{ content: code }],
    }),
  })
    .then((response) => response.json())
    .then((data) => {
      const result = data.run.output || "Error: No output received.";

      // Clear any HTML tags from the editor after execution
      editor.innerText = code;

      // Display raw output without syntax highlighting
      outputPre.textContent = result;
    })
    .catch((error) => {
      editor.innerText = code;
      outputPre.textContent = "Error: Unable to execute code.";
      console.error(error);
    });
}

// Event listeners for button click and language change
runButton.addEventListener("click", runCode);

languageSelect.addEventListener("change", () => {
  const language = languageSelect.value;
  // Change the highlighting mode based on the selected language
  editor.innerHTML = ""; // Clear the editor when language changes
});
