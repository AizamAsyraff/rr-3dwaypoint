(() => {
    'use strict';

    const IN_GAME = typeof window.GetParentResourceName === 'function';
    const RESOURCE = IN_GAME ? window.GetParentResourceName() : 'rr-3dwaypoint';

    // ---------------------------------------------------------------------
    // Icons (24x24 line set, stroke = currentColor)
    // ---------------------------------------------------------------------

    const ICON_PATHS = {
        pin: '<path d="M12 21s-7-6.1-7-11.8A7 7 0 0 1 19 9.2C19 14.9 12 21 12 21z"/><circle cx="12" cy="9.3" r="2.4"/>',
        flag: '<path d="M5 21V4"/><path d="M5 4.5h11.5l-2.2 4 2.2 4H5"/>',
        star: '<path d="M12 3.2l2.7 5.5 6 .9-4.35 4.25 1.03 6-5.38-2.83-5.38 2.83 1.03-6L3.3 9.6l6-.9z"/>',
        home: '<path d="M3.5 10.5 12 3.8l8.5 6.7"/><path d="M5.5 9v11h13V9"/><path d="M10 20v-5.5h4V20"/>',
        car: '<path d="M4 16.5v-3.8l1.9-4.6A2 2 0 0 1 7.75 6.9h8.5a2 2 0 0 1 1.85 1.2l1.9 4.6v3.8"/><path d="M4 12.7h16"/><path d="M4 16.5h16"/><circle cx="7.5" cy="16.5" r="1.7"/><circle cx="16.5" cy="16.5" r="1.7"/>',
        box: '<path d="M12 3 20 7.5v9L12 21l-8-4.5v-9z"/><path d="M4 7.5 12 12l8-4.5"/><path d="M12 12v9"/>',
        briefcase: '<rect x="3.5" y="7" width="17" height="12.5" rx="2"/><path d="M9 7V5.5A1.5 1.5 0 0 1 10.5 4h3A1.5 1.5 0 0 1 15 5.5V7"/><path d="M3.5 12.5h17"/>',
        target: '<circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="4.5"/><circle cx="12" cy="12" r="0.8" fill="currentColor"/>',
        user: '<circle cx="12" cy="8" r="3.8"/><path d="M4.5 20.5a7.5 7.5 0 0 1 15 0"/>',
        cross: '<path d="M12 5v14"/><path d="M5 12h14"/>',
        dollar: '<path d="M12 3v18"/><path d="M16.5 7.5c-.7-1.4-2.4-2.3-4.5-2.3-2.6 0-4.3 1.3-4.3 3.2 0 4.4 9 2.4 9 6.9 0 1.9-1.9 3.3-4.7 3.3-2.3 0-4.1-1-4.8-2.6"/>',
        check: '<path d="M5 12.5 9.5 17 19 7.5"/>',
        close: '<path d="M6 6l12 12"/><path d="M18 6 6 18"/>',
        eye: '<path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z"/><circle cx="12" cy="12" r="2.8"/>',
        eyeOff: '<path d="M3 3l18 18"/><path d="M10.6 5.6A9.7 9.7 0 0 1 12 5.5c6 0 9.5 6.5 9.5 6.5a17 17 0 0 1-2.9 3.6"/><path d="M6.4 6.9A16.6 16.6 0 0 0 2.5 12S6 18.5 12 18.5c1.8 0 3.4-.6 4.7-1.4"/><path d="M9.9 10a2.8 2.8 0 0 0 4 4"/>',
    };

    const icon = (name) =>
        `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${ICON_PATHS[name] || ICON_PATHS.pin}</svg>`;

    // ---------------------------------------------------------------------
    // State
    // ---------------------------------------------------------------------

    const DEFAULT_SETTINGS = {
        enabled: true,
        offscreen: true,
        showStreet: true,
        showEta: true,
        groundMarker: true,
        autoClear: true,
        units: 'metric',
        scale: 1.0,
        opacity: 1.0,
    };

    const DEFAULT_LOCALE = {
        waypoint: 'Waypoint',
        arrived: 'Arrived',
        ui: {
            title: '3D Waypoint',
            subtitle: 'Display & behaviour',
            close: 'to close',
            reset: 'Reset',
            done: 'Done',
            preview: 'Preview',
            groups: { display: 'Display', behaviour: 'Behaviour', appearance: 'Appearance' },
            units: { metric: 'Metric', imperial: 'Imperial' },
            settings: {
                enabled: ['Show waypoints', 'Render markers in the world'],
                offscreen: ['Off-screen indicators', 'Point to waypoints behind you'],
                showStreet: ['Street name', 'Shown when you look at a marker'],
                showEta: ['Arrival time', 'Estimated from your current speed'],
                groundMarker: ['Ground beam', 'Light pillar at the destination'],
                autoClear: ['Clear on arrival', 'Remove the waypoint when reached'],
                units: ['Units', 'Distance format'],
                scale: ['Size', 'Marker scale'],
                opacity: ['Opacity', 'Overall HUD visibility'],
            },
        },
    };

    const SCHEMA = [
        { group: 'display', items: [
            { key: 'enabled', type: 'toggle' },
            { key: 'offscreen', type: 'toggle', needs: 'enabled' },
            { key: 'showStreet', type: 'toggle', needs: 'enabled' },
            { key: 'showEta', type: 'toggle', needs: 'enabled' },
            { key: 'groundMarker', type: 'toggle', needs: 'enabled' },
        ] },
        { group: 'behaviour', items: [
            { key: 'autoClear', type: 'toggle' },
            { key: 'units', type: 'segment', options: ['metric', 'imperial'] },
        ] },
        { group: 'appearance', items: [
            { key: 'scale', type: 'range', min: 0.7, max: 1.4, step: 0.05 },
            { key: 'opacity', type: 'range', min: 0.3, max: 1, step: 0.05 },
        ] },
    ];

    let settings = { ...DEFAULT_SETTINGS };
    let locale = DEFAULT_LOCALE;

    const meta = new Map();  // id -> { label, sublabel, icon, kind }
    const nodes = new Map(); // id -> node

    const $ = (sel, root = document) => root.querySelector(sel);
    const hud = $('#hud');
    const toasts = $('#toasts');
    const settingsEl = $('#settings');
    const tpl = $('#tpl-wp');

    const post = (name, data = {}) => {
        if (!IN_GAME) return Promise.resolve(null);
        return fetch(`https://${RESOURCE}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data),
        }).then((r) => r.json()).catch(() => null);
    };

    const merge = (base, over) => {
        if (!over || typeof over !== 'object' || Array.isArray(over)) return over ?? base;
        const out = { ...base };
        for (const k of Object.keys(over)) {
            out[k] = base && typeof base[k] === 'object' && !Array.isArray(base[k]) ? merge(base[k], over[k]) : over[k];
        }
        return out;
    };

    // ---------------------------------------------------------------------
    // Formatting
    // ---------------------------------------------------------------------

    function formatDistance(m) {
        if (settings.units === 'imperial') {
            const ft = m * 3.28084;
            if (ft < 1000) return [String(Math.round(ft)), 'ft'];
            const mi = m / 1609.344;
            return [mi < 10 ? mi.toFixed(2) : mi.toFixed(1), 'mi'];
        }
        if (m < 1000) return [String(Math.round(m)), 'm'];
        const km = m / 1000;
        return [km < 10 ? km.toFixed(2) : km.toFixed(1), 'km'];
    }

    function formatEta(s) {
        if (s < 0 || !Number.isFinite(s)) return '';
        if (s < 60) return `${Math.max(1, Math.round(s))}s`;
        if (s < 3600) return `${Math.round(s / 60)} min`;
        const h = Math.floor(s / 3600);
        return `${h}h ${Math.round((s % 3600) / 60)}m`;
    }

    // ---------------------------------------------------------------------
    // Markers
    // ---------------------------------------------------------------------

    function createNode(id, parent = hud) {
        const el = tpl.content.firstElementChild.cloneNode(true);
        const node = {
            id,
            el,
            label: $('.wp-label', el),
            num: $('.wp-dist .num', el),
            unit: $('.wp-dist .unit', el),
            sub: $('.wp-sub', el),
            eta: $('.wp-eta', el),
            ring: $('.wp-off-ring', el),
            offDist: $('.wp-off-dist', el),
            icons: el.querySelectorAll('.wp-icon'),
            on: true,
            focus: false,
            hidden: false,
            lastText: 0,
            lastAngle: null,
        };
        applyMeta(node, meta.get(id));
        parent.appendChild(el);
        return node;
    }

    function applyMeta(node, m) {
        if (!m) return;
        node.label.textContent = m.label || locale.waypoint;
        node.sub.textContent = settings.showStreet ? m.sublabel || '' : '';
        node.icons.forEach((i) => (i.innerHTML = icon(m.icon)));
        node.el.dataset.kind = m.kind || 'custom';
    }

    function setText(node, dist, eta) {
        const [num, unit] = formatDistance(dist);
        if (node.num.textContent !== num) node.num.textContent = num;
        if (node.unit.textContent !== unit) node.unit.textContent = unit;
        const off = `${num} ${unit}`;
        if (node.offDist.textContent !== off) node.offDist.textContent = off;
        const etaText = settings.showEta ? formatEta(eta) : '';
        if (node.eta.textContent !== etaText) node.eta.textContent = etaText;
        node.el.classList.toggle('no-extra', !node.sub.textContent && !etaText);
    }

    function onFrame(data) {
        hud.classList.remove('is-hidden');
        hud.classList.toggle('is-dim', !!data.h);

        const w = window.innerWidth;
        const h = window.innerHeight;
        const now = performance.now();
        const seen = new Set();

        for (const it of data.l || []) {
            let node = nodes.get(it.i);
            if (!node) {
                node = createNode(it.i);
                nodes.set(it.i, node);
            }
            seen.add(it.i);

            node.el.style.transform = `translate3d(${(it.x * w).toFixed(1)}px, ${(it.y * h).toFixed(1)}px, 0)`;
            node.el.style.setProperty('--s', it.s);

            if (node.hidden) {
                node.hidden = false;
                node.el.classList.remove('is-hidden');
            }
            if (node.on !== it.o) {
                node.on = it.o;
                node.el.classList.toggle('is-off', !it.o);
            }
            if (!it.o && node.lastAngle !== it.a) {
                node.lastAngle = it.a;
                node.ring.style.transform = `rotate(${it.a}deg)`;
            }
            if (node.focus !== !!it.f) {
                node.focus = !!it.f;
                node.el.classList.toggle('is-focus', node.focus);
            }
            if (now - node.lastText > 120) {
                node.lastText = now;
                setText(node, it.d, it.e);
            }
        }

        for (const [id, node] of nodes) {
            if (!seen.has(id) && !node.hidden) {
                node.hidden = true;
                node.el.classList.add('is-hidden');
            }
        }
    }

    function upsert(m) {
        meta.set(m.id, m);
        const node = nodes.get(m.id);
        if (node) applyMeta(node, m);
    }

    function remove({ id, reason }) {
        meta.delete(id);
        const node = nodes.get(id);
        if (!node) return;
        nodes.delete(id);

        if (reason === 'arrive' && !node.hidden) {
            node.label.textContent = locale.arrived;
            node.icons.forEach((i) => (i.innerHTML = icon('check')));
            node.el.classList.remove('is-off');
            node.el.classList.add('is-arrived');
            setTimeout(() => node.el.remove(), 1100);
        } else {
            node.el.classList.add('is-leaving');
            setTimeout(() => node.el.remove(), 320);
        }
    }

    function refreshAll() {
        for (const [id, node] of nodes) {
            applyMeta(node, meta.get(id));
            node.lastText = 0;
        }
    }

    // ---------------------------------------------------------------------
    // Toasts
    // ---------------------------------------------------------------------

    function toast({ title, sub, icon: ic, duration = 3200 }) {
        while (toasts.children.length >= 3) toasts.firstElementChild.remove();

        const el = document.createElement('div');
        el.className = 'toast glass';
        el.innerHTML = `
            <div class="wp-icon">${icon(ic || 'pin')}</div>
            <div class="toast-text">
                <div class="toast-title"></div>
                <div class="toast-sub"></div>
            </div>
            <div class="toast-bar" style="animation-duration:${duration}ms"></div>`;
        $('.toast-title', el).textContent = title || '';
        $('.toast-sub', el).textContent = sub || '';
        toasts.appendChild(el);

        setTimeout(() => {
            el.classList.add('is-out');
            setTimeout(() => el.remove(), 360);
        }, duration);
    }

    // ---------------------------------------------------------------------
    // Settings panel
    // ---------------------------------------------------------------------

    const body = $('#panel-body');
    const controls = {};
    let preview = null;
    let saveTimer = null;

    function buildPanel() {
        const ui = locale.ui;
        body.innerHTML = '';

        document.querySelectorAll('[data-i18n]').forEach((el) => {
            const v = ui[el.dataset.i18n];
            if (typeof v === 'string') el.textContent = v;
        });
        document.querySelectorAll('[data-icon]').forEach((el) => (el.innerHTML = icon(el.dataset.icon)));

        for (const section of SCHEMA) {
            const group = document.createElement('div');
            group.className = 'group';
            group.innerHTML = `<div class="group-title"></div>`;
            $('.group-title', group).textContent = ui.groups[section.group] || section.group;

            for (const item of section.items) {
                const [title, desc] = ui.settings[item.key] || [item.key, ''];
                const row = document.createElement('div');
                row.className = 'row';
                row.innerHTML = `<div class="row-text"><div class="row-title"></div><div class="row-desc"></div></div>`;
                $('.row-title', row).textContent = title;
                $('.row-desc', row).textContent = desc;
                row.appendChild(buildControl(item, row));
                group.appendChild(row);
            }
            body.appendChild(group);
        }

        const slot = $('#preview-slot');
        slot.innerHTML = '';
        meta.set('__preview', { label: locale.waypoint, sublabel: 'Vinewood Blvd, Downtown Vinewood', icon: 'flag', kind: 'map' });
        preview = createNode('__preview', slot);
        meta.delete('__preview');
        preview.el.classList.add('is-focus');
        preview.el.style.setProperty('--s', 0.82);
    }

    function buildControl(item, row) {
        const key = item.key;

        if (item.type === 'toggle') {
            const btn = document.createElement('button');
            btn.className = 'switch';
            btn.setAttribute('role', 'switch');
            btn.addEventListener('click', () => update(key, !settings[key]));
            controls[key] = { row, item, sync: () => btn.setAttribute('aria-checked', String(!!settings[key])) };
            return btn;
        }

        if (item.type === 'segment') {
            const seg = document.createElement('div');
            seg.className = 'segment';
            seg.innerHTML = '<span class="segment-thumb"></span>';
            const thumb = $('.segment-thumb', seg);
            const buttons = item.options.map((opt) => {
                const b = document.createElement('button');
                b.textContent = (locale.ui.units && locale.ui.units[opt]) || opt;
                b.addEventListener('click', () => update(key, opt));
                seg.appendChild(b);
                return b;
            });
            const sync = () => {
                buttons.forEach((b, i) => {
                    const active = item.options[i] === settings[key];
                    b.setAttribute('aria-pressed', String(active));
                    if (active) {
                        thumb.style.width = `${b.offsetWidth}px`;
                        thumb.style.transform = `translateX(${b.offsetLeft - buttons[0].offsetLeft}px)`;
                    }
                });
            };
            controls[key] = { row, item, sync };
            return seg;
        }

        const wrap = document.createElement('div');
        wrap.className = 'range';
        wrap.innerHTML = `<input type="range" min="${item.min}" max="${item.max}" step="${item.step}"><output></output>`;
        const input = $('input', wrap);
        const out = $('output', wrap);
        input.addEventListener('input', () => update(key, parseFloat(input.value)));
        controls[key] = {
            row,
            item,
            sync: () => {
                input.value = settings[key];
                const p = ((settings[key] - item.min) / (item.max - item.min)) * 100;
                input.style.setProperty('--p', `${p}%`);
                out.textContent = `${Math.round(settings[key] * 100)}%`;
            },
        };
        return wrap;
    }

    function syncPanel() {
        for (const key of Object.keys(controls)) {
            const c = controls[key];
            c.sync();
            c.row.classList.toggle('is-disabled', !!c.item.needs && !settings[c.item.needs]);
        }
        if (preview) {
            preview.sub.textContent = settings.showStreet ? 'Vinewood Blvd, Downtown Vinewood' : '';
            setText(preview, 1240, 96);
        }
    }

    function applySettings() {
        document.documentElement.style.setProperty('--hud-opacity', settings.opacity);
        document.documentElement.style.setProperty('--user-scale', settings.scale);
        refreshAll();
        syncPanel();
    }

    function update(key, value) {
        settings = { ...settings, [key]: value };
        applySettings();
        clearTimeout(saveTimer);
        saveTimer = setTimeout(() => post('saveSettings', settings), 150);
    }

    function openSettings() {
        settingsEl.classList.add('is-open');
        settingsEl.setAttribute('aria-hidden', 'false');
        requestAnimationFrame(syncPanel); // segment thumb needs layout
    }

    function closeSettings(notify = true) {
        if (!settingsEl.classList.contains('is-open')) return;
        settingsEl.classList.remove('is-open');
        settingsEl.setAttribute('aria-hidden', 'true');
        clearTimeout(saveTimer);
        post('saveSettings', settings);
        if (notify) post('close');
    }

    settingsEl.addEventListener('click', (e) => {
        if (e.target.closest('[data-close]')) closeSettings();
        if (e.target.closest('[data-reset]')) {
            post('resetSettings').then((s) => {
                settings = merge(DEFAULT_SETTINGS, s || DEFAULT_SETTINGS);
                applySettings();
            });
        }
    });

    window.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') closeSettings();
    });

    // ---------------------------------------------------------------------
    // Messages
    // ---------------------------------------------------------------------

    const handlers = {
        init(d) {
            locale = merge(DEFAULT_LOCALE, d.locale);
            settings = merge(DEFAULT_SETTINGS, d.settings);
            for (const m of d.waypoints || []) meta.set(m.id, m);
            buildPanel();
            applySettings();
        },
        frame: onFrame,
        hide() { hud.classList.add('is-hidden'); },
        upsert,
        remove,
        toast,
        settings(s) {
            settings = merge(DEFAULT_SETTINGS, s);
            applySettings();
        },
        'settings:open': openSettings,
        'settings:close': () => closeSettings(false),
    };

    function handle(msg) {
        const fn = msg && handlers[msg.action];
        if (fn) fn(msg.data || {});
    }

    window.addEventListener('message', (e) => handle(e.data));

    buildPanel();
    applySettings();
    post('ready');

    // ---------------------------------------------------------------------
    // Browser preview — open html/index.html directly to see the UI
    // ---------------------------------------------------------------------

    if (!IN_GAME) {
        document.body.classList.add('dev');

        const demo = [
            { id: '__map', label: 'Waypoint', sublabel: 'Vinewood Blvd, Downtown Vinewood', icon: 'flag', kind: 'map' },
            { id: 'job', label: 'Delivery', sublabel: 'Popular St, La Mesa', icon: 'box' },
            { id: 'garage', label: 'Garage', sublabel: 'Alta St, Pillbox Hill', icon: 'car' },
            { id: 'home', label: 'Home', sublabel: 'Grove St, Davis', icon: 'home' },
        ];

        handle({ action: 'init', data: { settings: DEFAULT_SETTINGS, waypoints: demo } });

        const params = new URLSearchParams(location.search);
        const t0 = performance.now();
        let jobActive = true;

        const tick = (t) => {
            const s = params.has('still') ? 0.4 : (t - t0) / 1000;
            const l = [
                { i: '__map', x: 0.5 + Math.sin(s * 0.35) * 0.07, y: 0.43, o: true, a: 0, d: 1240 - ((s * 12) % 900), s: 0.72, f: Math.abs(Math.sin(s * 0.35)) < 0.5, e: 96 },
                { i: 'garage', x: 0.965, y: 0.58, o: false, a: 12, d: 3400, s: 0.66, f: false, e: -1 },
                { i: 'home', x: 0.18, y: 0.93, o: false, a: 128, d: 7820, s: 0.6, f: false, e: -1 },
            ];
            if (jobActive) l.push({ i: 'job', x: 0.26, y: 0.56, o: true, a: 0, d: 186, s: 0.88, f: false, e: 14 });
            handle({ action: 'frame', data: { h: false, l } });
            requestAnimationFrame(tick);
        };
        requestAnimationFrame(tick);

        const bar = document.createElement('div');
        bar.className = 'dev-bar glass';
        const actions = {
            Settings: () => openSettings(),
            Toast: () => toast({ title: 'Waypoint set', sub: 'Vinewood Blvd, Downtown Vinewood', icon: 'flag' }),
            Arrive: () => {
                if (!jobActive) return;
                handle({ action: 'remove', data: { id: 'job', reason: 'arrive' } });
                jobActive = false;
                toast({ title: 'Arrived', sub: 'Delivery', icon: 'check' });
                setTimeout(() => {
                    upsert(demo[1]);
                    jobActive = true;
                }, 2500);
            },
        };
        for (const [name, fn] of Object.entries(actions)) {
            const b = document.createElement('button');
            b.textContent = name;
            b.addEventListener('click', fn);
            bar.appendChild(b);
        }
        document.body.appendChild(bar);

        if (params.has('settings')) openSettings();
        if (params.has('toast')) actions.Toast();
    }
})();
