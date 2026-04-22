var kbTopScrollBound = false;

function kubeTidySyncTopButton() {
  var topButton = document.querySelector(".md-top");
  if (!topButton) {
    return;
  }

  if (window.scrollY > 240) {
    topButton.classList.add("kb-top-visible");
  } else {
    topButton.classList.remove("kb-top-visible");
  }
}

function kubeTidyBindTopButton() {
  kubeTidySyncTopButton();

  if (!kbTopScrollBound) {
    window.addEventListener("scroll", kubeTidySyncTopButton, { passive: true });
    kbTopScrollBound = true;
  }
}

document.addEventListener("DOMContentLoaded", kubeTidyBindTopButton);

if (typeof document$ !== "undefined" && document$.subscribe) {
  document$.subscribe(function () {
    kubeTidyBindTopButton();
  });
}
