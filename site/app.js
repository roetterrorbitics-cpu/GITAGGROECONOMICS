const slides = [...document.querySelectorAll('.slide')];
const counter = document.querySelector('#counter');
const progress = document.querySelector('#progress-bar');
const previous = document.querySelector('#previous');
const next = document.querySelector('#next');
let current = 0;

function showSlide(index, focus = false) {
  current = Math.max(0, Math.min(index, slides.length - 1));
  slides.forEach((slide, slideIndex) => {
    const isActive = slideIndex === current;
    slide.hidden = !isActive;
    slide.classList.toggle('active', isActive);
  });
  counter.textContent = `${String(current + 1).padStart(2, '0')} / ${String(slides.length).padStart(2, '0')}`;
  progress.style.width = `${((current + 1) / slides.length) * 100}%`;
  previous.disabled = current === 0;
  next.disabled = current === slides.length - 1;
  history.replaceState(null, '', `#slide-${current + 1}`);
  if (focus) slides[current].focus();
}

function navigate(delta) { showSlide(current + delta, true); }
previous.addEventListener('click', () => navigate(-1));
next.addEventListener('click', () => navigate(1));
window.addEventListener('keydown', (event) => {
  if (['ArrowRight', ' ', 'PageDown'].includes(event.key)) { event.preventDefault(); navigate(1); }
  if (['ArrowLeft', 'PageUp'].includes(event.key)) { event.preventDefault(); navigate(-1); }
  if (event.key === 'Home') { event.preventDefault(); showSlide(0, true); }
  if (event.key === 'End') { event.preventDefault(); showSlide(slides.length - 1, true); }
});
const initial = Number(location.hash.replace('#slide-', ''));
showSlide(Number.isInteger(initial) && initial > 0 ? initial - 1 : 0);
