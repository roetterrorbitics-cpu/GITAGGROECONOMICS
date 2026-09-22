const slides = [...document.querySelectorAll('.slide')];
const counter = document.querySelector('#counter');
let current = 0;

function showSlide(index) {
  current = (index + slides.length) % slides.length;
  slides.forEach((slide, position) => slide.classList.toggle('active', position === current));
  counter.textContent = `${current + 1} / ${slides.length}`;
  history.replaceState(null, '', current === 0 ? location.pathname : `#${slides[current].id || current + 1}`);
}

document.querySelector('#next').addEventListener('click', () => showSlide(current + 1));
document.querySelector('#previous').addEventListener('click', () => showSlide(current - 1));
document.addEventListener('keydown', ({ key }) => {
  if (key === 'ArrowRight' || key === 'PageDown') showSlide(current + 1);
  if (key === 'ArrowLeft' || key === 'PageUp') showSlide(current - 1);
});
document.querySelectorAll('a[href^="#"]').forEach((link) => link.addEventListener('click', (event) => {
  const target = slides.findIndex((slide) => `#${slide.id}` === link.getAttribute('href'));
  if (target >= 0) { event.preventDefault(); showSlide(target); }
}));
