/* ===== CORTINA ===== */
const cortina = document.querySelector('.cortina_div');
const botao = document.getElementById('botao_start');

if (cortina && botao) {
    document.body.classList.add('cortina_fechada');

    botao.addEventListener('click', function () {
        cortina.classList.add('aberta');
        document.body.classList.remove('cortina_fechada');
    });
}

/* ===== CARROSSEL DOS EPs ===== */
const slides = document.querySelectorAll('.slide_ep');
const btnEsq = document.querySelector('.slide_left');
const btnDir = document.querySelector('.slide_right');
const botoesDot = [
    document.querySelector('.dot_one'),
    document.querySelector('.dot_two')
];

const INTERVALO = 5000;
let atual = 0;
let timer;

function mostrar(indice) {
    if (slides.length === 0) return;
    atual = (indice + slides.length) % slides.length;

    slides.forEach((slide, i) => slide.classList.toggle('ativo', i === atual));

    botoesDot.forEach((btn, i) => {
        const img = btn && btn.querySelector('img');
        if (img) img.src = i === atual ? 'img/dot_green.svg' : 'img/dot_grey.svg';
    });
}

function iniciarAuto() {
    clearInterval(timer);
    timer = setInterval(() => mostrar(atual + 1), INTERVALO);
}

if (btnEsq) btnEsq.addEventListener('click', () => { mostrar(atual - 1); iniciarAuto(); });
if (btnDir) btnDir.addEventListener('click', () => { mostrar(atual + 1); iniciarAuto(); });
botoesDot.forEach((btn, i) => {
    if (btn) btn.addEventListener('click', () => { mostrar(i); iniciarAuto(); });
});

mostrar(0);
iniciarAuto();

/* ===== FOTOS DOS MEMBROS: barra arrastável + setas =====
   Cole no FINAL do seu script.js */
(function () {
    const trilho = document.getElementById('weverse_trilho');
    const barra  = document.querySelector('.weverse_barra');
    const thumb  = document.getElementById('weverse_thumb');
    const setaEsq = document.querySelector('.green_arrow_left');
    const setaDir = document.querySelector('.green_arrow_right');

    if (!trilho || !barra || !thumb) return;

    const maxScroll = () => trilho.scrollWidth - trilho.clientWidth;
    const curso     = () => barra.clientWidth - thumb.offsetWidth;

    /* posiciona e dimensiona a barra conforme a rolagem */
    function atualizar() {
        const ratio = trilho.scrollWidth ? trilho.clientWidth / trilho.scrollWidth : 1;
        thumb.style.width = Math.max(ratio * 100, 8) + '%';

        const max = maxScroll();
        thumb.style.left = (max > 1 ? (trilho.scrollLeft / max) * curso() : 0) + 'px';
        barra.classList.toggle('sem_scroll', max <= 1);
    }

    /* arrastar a barra */
    let arrastando = false, inicioX = 0, inicioScroll = 0;

    thumb.addEventListener('pointerdown', (e) => {
        arrastando = true;
        inicioX = e.clientX;
        inicioScroll = trilho.scrollLeft;
        thumb.setPointerCapture(e.pointerId);
        e.preventDefault();
    });

    thumb.addEventListener('pointermove', (e) => {
        if (!arrastando || curso() <= 0) return;
        trilho.scrollLeft = inicioScroll + ((e.clientX - inicioX) / curso()) * maxScroll();
    });

    const soltar = () => { arrastando = false; };
    thumb.addEventListener('pointerup', soltar);
    thumb.addEventListener('pointercancel', soltar);

    /* clicar na trilha leva a barra até o ponto clicado */
    barra.addEventListener('pointerdown', (e) => {
        if (e.target === thumb || curso() <= 0) return;
        const caixa = barra.getBoundingClientRect();
        const alvo = ((e.clientX - caixa.left - thumb.offsetWidth / 2) / curso()) * maxScroll();
        trilho.scrollTo({ left: alvo, behavior: 'smooth' });
    });

    /* setas: andam uma foto por clique */
    function passo() {
        const foto = trilho.querySelector('img');
        const gap = parseFloat(getComputedStyle(trilho).columnGap) || 0;
        return (foto ? foto.offsetWidth : trilho.clientWidth / 4) + gap;
    }

    if (setaEsq) setaEsq.addEventListener('click', () => trilho.scrollBy({ left: -passo(), behavior: 'smooth' }));
    if (setaDir) setaDir.addEventListener('click', () => trilho.scrollBy({ left:  passo(), behavior: 'smooth' }));

    trilho.addEventListener('scroll', atualizar);
    window.addEventListener('resize', atualizar);
    window.addEventListener('load', atualizar);
    atualizar();
})();

/* ===== BARRA DE PESQUISA (lupa da faixa verde) =====
   Cole no FINAL do seu script.js */
(function () {
    const botao   = document.getElementById('search_toggle');
    const painel  = document.getElementById('search_panel');
    const form    = document.getElementById('search_form');
    const campo   = document.getElementById('search_input');
    const lista   = document.getElementById('search_results');
    if (!botao || !painel || !campo || !lista) return;

    /* Páginas pesquisáveis. Para incluir uma nova, é só adicionar uma linha.
       "chaves" são as palavras extras que levam até a página. */
    const PAGINAS = [
        { titulo: 'Concepts',         url: 'concepts.html',   chaves: 'concept conceito ep color outside the lines green green' },
        { titulo: 'Members',          url: 'members.html',    chaves: 'membros juhoon james seonghyeon keonho' },
        { titulo: 'Fashion',          url: 'fashion.html',    chaves: 'moda looks roupas style' },
        { titulo: 'Tickets',          url: 'tickets.html',    chaves: 'ingressos shows tour concert' },
        { titulo: 'My account',       url: 'user_area.html',  chaves: 'conta usuario user login perfil' },
        { titulo: 'Cart',             url: 'user_cart.html',  chaves: 'carrinho compras cart' },
        { titulo: 'Help and Support', url: 'support.html',    chaves: 'ajuda suporte help contato' },
        { titulo: 'Privacy',          url: 'privacy.html',    chaves: 'privacidade dados' },
        { titulo: 'Terms',            url: 'terms.html',      chaves: 'termos condicoes' }
    ];

    /* tira acentos e maiúsculas para comparar */
    const limpar = (t) => t.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim();

    let atuais = [];

    function mostrar(termo) {
        const q = limpar(termo);
        atuais = q
            ? PAGINAS.filter(p => limpar(p.titulo + ' ' + p.chaves).includes(q))
            : PAGINAS.slice(0, 4);               // sugestões quando o campo está vazio

        lista.replaceChildren();

        if (atuais.length === 0) {
            const li = document.createElement('li');
            li.className = 'sem_resultado';
            li.textContent = 'No results found.';
            lista.appendChild(li);
            return;
        }

        atuais.forEach(p => {
            const li = document.createElement('li');
            const a = document.createElement('a');
            a.href = p.url;
            a.textContent = p.titulo;
            li.appendChild(a);
            lista.appendChild(li);
        });
    }

    function abrir() {
        painel.hidden = false;
        botao.setAttribute('aria-expanded', 'true');
        mostrar(campo.value);
        campo.focus();
    }

    function fechar() {
        painel.hidden = true;
        botao.setAttribute('aria-expanded', 'false');
    }

    botao.addEventListener('click', () => (painel.hidden ? abrir() : fechar()));
    campo.addEventListener('input', () => mostrar(campo.value));

    /* Enter abre o primeiro resultado */
    form.addEventListener('submit', (e) => {
        e.preventDefault();
        if (atuais.length) window.location.href = atuais[0].url;
    });

    /* setas ↑ ↓ percorrem os resultados */
    painel.addEventListener('keydown', (e) => {
        if (e.key !== 'ArrowDown' && e.key !== 'ArrowUp') return;
        const links = [...lista.querySelectorAll('a')];
        if (!links.length) return;
        e.preventDefault();
        const i = links.indexOf(document.activeElement);
        if (e.key === 'ArrowDown') (links[i + 1] || links[0]).focus();
        else if (i <= 0) campo.focus();
        else links[i - 1].focus();
    });

    /* Esc ou clique fora fecha */
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && !painel.hidden) { fechar(); botao.focus(); }
    });
    document.addEventListener('click', (e) => {
        if (!painel.hidden && !painel.contains(e.target) && !botao.contains(e.target)) fechar();
    });
})();