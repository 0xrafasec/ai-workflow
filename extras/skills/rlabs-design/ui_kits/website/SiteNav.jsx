// Marketing site Nav
const { useState: useStateNav } = React;

function SiteNav({ dark = true }) {
  const [open, setOpen] = useStateNav(false);
  const bg = dark ? 'rgba(10,10,11,0.72)' : 'rgba(250,250,247,0.72)';
  return (
    <nav style={{
      position: 'sticky', top: 0, zIndex: 200,
      height: 64, display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '0 32px',
      background: bg,
      backdropFilter: 'blur(24px) saturate(180%)',
      WebkitBackdropFilter: 'blur(24px) saturate(180%)',
      borderBottom: '1px solid var(--border-subtle)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 40 }}>
        <Wordmark size={20} />
        <div style={{ display: 'flex', gap: 22, fontFamily: 'var(--font-body)', fontSize: 14 }}>
          {['agents', 'chains', 'studio', 'docs', 'pricing'].map(l => (
            <a key={l} href="#" style={{ color: 'var(--fg2)', textDecoration: 'none', transition: `color 200ms ${EASE}` }}
               onMouseEnter={e => e.currentTarget.style.color = 'var(--fg1)'}
               onMouseLeave={e => e.currentTarget.style.color = 'var(--fg2)'}>
              {l}
            </a>
          ))}
        </div>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <Button variant="ghost" size="sm">sign in</Button>
        <Button variant="primary" size="sm" iconRight={<Icon name="arrow" size={14}/>}>start building</Button>
      </div>
    </nav>
  );
}
Object.assign(window, { SiteNav });
