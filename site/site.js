// Adds a Copy button to every code block marked .code. The pages work without it.
for (const block of document.querySelectorAll('.code')) {
  const button = document.createElement('button');
  button.className = 'copy';
  button.type = 'button';
  button.textContent = 'Copy';
  button.addEventListener('click', async () => {
    // Copy the commands only: leave out prompts (.p) and comments (.c).
    const pre = block.querySelector('pre').cloneNode(true);
    pre.querySelectorAll('.p, .c').forEach((el) => el.remove());
    const text = pre.textContent.split('\n').map((l) => l.trimEnd()).filter(Boolean).join('\n');
    try {
      await navigator.clipboard.writeText(text);
      button.textContent = 'Copied';
    } catch {
      button.textContent = 'Press Ctrl+C';
    }
    setTimeout(() => { button.textContent = 'Copy'; }, 1500);
  });
  block.appendChild(button);
}
