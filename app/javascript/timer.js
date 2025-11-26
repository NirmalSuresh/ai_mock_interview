function startTimer(seconds) {
  const timerElement = document.getElementById("time-value");
  if (!timerElement) return;

  function update() {
    if (seconds <= 0) {
      timerElement.textContent = "00:00";
      return;
    }

    let m = Math.floor(seconds / 60);
    let s = seconds % 60;

    timerElement.textContent =
      `${m.toString().padStart(2, "0")}:${s.toString().padStart(2, "0")}`;

    seconds -= 1;
    setTimeout(update, 1000);
  }

  update();
}

window.startTimer = startTimer;
