const toast = document.querySelector("#copyToast");
let toastTimer;

document.querySelectorAll(".copy-button").forEach((button) => {
  button.addEventListener("click", async () => {
    const target = document.querySelector(`#${button.dataset.copyTarget}`);

    if (!target) {
      return;
    }

    try {
      await navigator.clipboard.writeText(target.innerText.trim());
      button.textContent = "Đã chép";
      toast.classList.add("show");
      window.clearTimeout(toastTimer);
      toastTimer = window.setTimeout(() => toast.classList.remove("show"), 1800);
      window.setTimeout(() => {
        button.textContent = "Sao chép";
      }, 1800);
    } catch {
      window.getSelection()?.selectAllChildren(target);
    }
  });
});

const sections = [...document.querySelectorAll("main section[id]")];
const navLinks = [...document.querySelectorAll(".nav-link")];

const updateActiveNav = () => {
  const activeSection = [...sections]
    .reverse()
    .find((section) => section.getBoundingClientRect().top <= 120);

  navLinks.forEach((link) => {
    link.classList.toggle("active", link.getAttribute("href") === `#${activeSection?.id || "overview"}`);
  });
};

window.addEventListener("scroll", updateActiveNav, { passive: true });
updateActiveNav();
