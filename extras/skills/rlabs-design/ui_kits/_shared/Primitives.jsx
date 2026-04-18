// Shared Rlabs UI primitives — small, composable, reusable across kits.
// Requires colors_and_type.css + tokens.css loaded on the page.

const { useState } = React;

const EASE = 'cubic-bezier(0.2, 0.8, 0.2, 1)';

// ---------- Button ----------
function Button({ variant = 'primary', size = 'md', children, onClick, icon, iconRight }) {
  const base = {
    fontFamily: 'var(--font-body)',
    fontWeight: 500,
    border: 'none',
    borderRadius: size === 'sm' ? 6 : 8,
    cursor: 'pointer',
    display: 'inline-flex',
    alignItems: 'center',
    gap: 8,
    transition: `all 200ms ${EASE}`,
    whiteSpace: 'nowrap',
    textDecoration: 'none',
    padding: size === 'sm' ? '6px 12px' : size === 'lg' ? '14px 22px' : '10px 18px',
    fontSize: size === 'sm' ? 13 : size === 'lg' ? 15 : 14,
  };
  const variants = {
    primary: { background: 'var(--accent)', color: 'var(--accent-fg)' },
    signal: { background: 'var(--rl-signal)', color: 'var(--rl-near-black)' },
    secondary: { background: 'transparent', color: 'var(--fg1)', border: '1px solid var(--border-strong)' },
    ghost: { background: 'transparent', color: 'var(--fg1)' },
  };
  const [hover, setHover] = useState(false);
  const [pressed, setPressed] = useState(false);
  const hoverBg = {
    primary: 'var(--accent-hover)',
    signal: '#D3FB60',
    secondary: 'rgba(127,127,127,0.08)',
    ghost: 'rgba(127,127,127,0.08)',
  };
  return (
    <button
      onClick={onClick}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => { setHover(false); setPressed(false); }}
      onMouseDown={() => setPressed(true)}
      onMouseUp={() => setPressed(false)}
      style={{
        ...base,
        ...variants[variant],
        ...(hover && variant === 'primary' ? { background: hoverBg.primary } : {}),
        ...(hover && variant === 'signal' ? { filter: 'brightness(1.06)' } : {}),
        ...(hover && (variant === 'secondary' || variant === 'ghost') ? { background: hoverBg[variant] } : {}),
        transform: pressed ? 'scale(0.98)' : 'scale(1)',
      }}
    >
      {icon}
      {children}
      {iconRight}
    </button>
  );
}

// ---------- Mono ----------
const Mono = ({ children, color, size = 12 }) => (
  <span style={{ fontFamily: 'var(--font-mono)', fontSize: size, color: color || 'var(--fg2)' }}>
    {children}
  </span>
);

// ---------- Badge ----------
function Badge({ tone = 'neutral', children }) {
  const tones = {
    live:    { bg: 'rgba(169,214,56,0.14)', fg: 'var(--rl-signal-deep)', dot: '#A9D638' },
    ember:   { bg: 'rgba(255,91,46,0.14)', fg: '#C03A10', dot: '#FF5B2E' },
    lapis:   { bg: 'rgba(46,91,255,0.12)', fg: 'var(--rl-lapis-deep)', dot: '#2E5BFF' },
    neutral: { bg: 'var(--bg-sunken)', fg: 'var(--fg1)', dot: 'var(--rl-ash)' },
  };
  const t = tones[tone];
  return (
    <span style={{
      fontFamily: 'var(--font-body)', fontWeight: 500, fontSize: 11, letterSpacing: '0.02em',
      padding: '3px 9px', borderRadius: 9999, background: t.bg, color: t.fg,
      display: 'inline-flex', alignItems: 'center', gap: 5,
    }}>
      <span style={{ width: 6, height: 6, borderRadius: '50%', background: t.dot }} />
      {children}
    </span>
  );
}

// ---------- Eyebrow ----------
const Eyebrow = ({ children, color }) => (
  <div style={{
    fontFamily: 'var(--font-body)', fontWeight: 500, fontSize: 11,
    textTransform: 'uppercase', letterSpacing: '0.1em',
    color: color || 'var(--fg3)',
  }}>{children}</div>
);

// ---------- Mark (the R logo) ----------
function Mark({ size = 28 }) {
  return (
    <div style={{
      width: size, height: size, background: 'var(--fg1)',
      display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative',
      flexShrink: 0,
    }}>
      <span style={{
        fontFamily: 'var(--font-display)', fontWeight: 800,
        fontSize: size * 0.72, color: 'var(--bg)', letterSpacing: '-0.03em', lineHeight: 1,
      }}>R</span>
      <div style={{
        position: 'absolute', top: size * 0.14, right: size * 0.14,
        width: size * 0.1, height: size * 0.1, borderRadius: '50%', background: 'var(--rl-signal)',
      }} />
    </div>
  );
}

// ---------- Wordmark ----------
function Wordmark({ size = 22 }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
      <Mark size={size * 0.9} />
      <span style={{
        fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: size,
        letterSpacing: '-0.02em', lineHeight: 1, textTransform: 'lowercase', color: 'var(--fg1)',
      }}>rlabs</span>
    </div>
  );
}

// ---------- Icon (inline Lucide-style) ----------
function Icon({ name, size = 20, stroke = 1.75 }) {
  const paths = {
    zap: <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />,
    link: <g><path d="M9 17H7A5 5 0 0 1 7 7h2"/><path d="M15 7h2a5 5 0 1 1 0 10h-2"/><line x1="8" y1="12" x2="16" y2="12"/></g>,
    shield: <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>,
    grid: <g><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></g>,
    clock: <g><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></g>,
    activity: <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>,
    arrow: <g><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></g>,
    arrowup: <g><line x1="12" y1="19" x2="12" y2="5"/><polyline points="5 12 12 5 19 12"/></g>,
    arrowdown: <g><line x1="12" y1="5" x2="12" y2="19"/><polyline points="19 12 12 19 5 12"/></g>,
    play: <polygon points="5 3 19 12 5 21 5 3" />,
    pause: <g><rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/></g>,
    plus: <g><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></g>,
    check: <polyline points="20 6 9 17 4 12" />,
    x: <g><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></g>,
    search: <g><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></g>,
    settings: <g><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></g>,
    home: <g><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></g>,
    terminal: <g><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></g>,
    bell: <g><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></g>,
    user: <g><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></g>,
    box: <g><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></g>,
    wallet: <g><path d="M20 12V8H6a2 2 0 0 1-2-2c0-1.1.9-2 2-2h12v4"/><path d="M4 6v12c0 1.1.9 2 2 2h14v-4"/><path d="M18 12a2 2 0 0 0 0 4h4v-4z"/></g>,
    cpu: <g><rect x="4" y="4" width="16" height="16" rx="2"/><rect x="9" y="9" width="6" height="6"/><line x1="9" y1="1" x2="9" y2="4"/><line x1="15" y1="1" x2="15" y2="4"/><line x1="9" y1="20" x2="9" y2="23"/><line x1="15" y1="20" x2="15" y2="23"/><line x1="20" y1="9" x2="23" y2="9"/><line x1="20" y1="14" x2="23" y2="14"/><line x1="1" y1="9" x2="4" y2="9"/><line x1="1" y1="14" x2="4" y2="14"/></g>,
    menu: <g><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/></g>,
  };
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none"
         stroke="currentColor" strokeWidth={stroke} strokeLinecap="round" strokeLinejoin="round">
      {paths[name]}
    </svg>
  );
}

Object.assign(window, { Button, Mono, Badge, Eyebrow, Mark, Wordmark, Icon, EASE });
