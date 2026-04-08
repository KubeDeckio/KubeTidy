var ktTopScrollBound = false;

function kubeTidySyncTopButton() {
  var topButton = document.querySelector(".md-top");
  if (!topButton) {
    return;
  }

  if (window.scrollY > 240) {
    topButton.classList.add("kt-top-visible");
  } else {
    topButton.classList.remove("kt-top-visible");
  }
}

function kubeTidyBindTopButton() {
  kubeTidySyncTopButton();

  if (!ktTopScrollBound) {
    window.addEventListener("scroll", kubeTidySyncTopButton, { passive: true });
    ktTopScrollBound = true;
  }
}

document.addEventListener("DOMContentLoaded", kubeTidyBindTopButton);

if (typeof document$ !== "undefined" && document$.subscribe) {
  document$.subscribe(function () {
    kubeTidyBindTopButton();
  });
}
