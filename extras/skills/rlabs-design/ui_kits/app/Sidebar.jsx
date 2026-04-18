// Dashboard sidebar
function Sidebar({ active, onNav }) {
  const items = [
    { key: 'home',     icon: 'home',     label: 'overview' },
    { key: 'agents',   icon: 'cpu',      label: 'agents' },
    { key: 'txs',      icon: 'activity', label: 'transactions' },
    { key: 'wallets',  icon: 'wallet',   label: 'wallets' },
    { key: 'chains',   icon: 'link',     label: 'chains' },
    { key: 'studio',   icon: 'terminal', label: 'studio' },
  ];
  return (
    <aside style={{
      width: 240, height: '100vh', position: 'sticky', top: 0,
      background: 'var(--bg-elevated)',
      borderRight: '1px solid var(--border-subtle)',
      display: 'flex', flexDirection: 'column', padding: '18px 12px',
      flexShrink: 0,
    }}>
      <div style={{ padding: '4px 8px 20px' }}><Wordmark size={18} /></div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        {items.map(it => {
          const isActive = active === it.key;
          return (
            <button key={it.key} onClick={() => onNav(it.key)} style={{
              display: 'flex', alignItems: 'center', gap: 10,
              padding: '9px 10px', border: 'none',
              background: isActive ? 'var(--bg-sunken)' : 'transparent',
              color: isActive ? 'var(--fg1)' : 'var(--fg2)',
              fontFamily: 'var(--font-body)', fontSize: 13, fontWeight: isActive ? 500 : 400,
              cursor: 'pointer', textAlign: 'left', borderRadius: 6,
              transition: `all 200ms ${EASE}`,
            }}
              onMouseEnter={e => { if (!isActive) e.currentTarget.style.background = 'var(--bg-sunken)'; }}
              onMouseLeave={e => { if (!isActive) e.currentTarget.style.background = 'transparent'; }}
            >
              <Icon name={it.icon} size={16}/>
              {it.label}
            </button>
          );
        })}
      </div>
      <div style={{ marginTop: 'auto', padding: '12px 8px', borderTop: '1px solid var(--border-subtle)', display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{ width: 28, height: 28, borderRadius: '50%', background: 'var(--rl-violet)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#FFF', fontWeight: 600, fontSize: 12 }}>a</div>
        <div style={{ display: 'flex', flexDirection: 'column' }}>
          <div style={{ fontSize: 13, fontWeight: 500 }}>aryan.eth</div>
          <Mono size={10} color="var(--fg3)">0x7f..a2b4</Mono>
        </div>
      </div>
    </aside>
  );
}
Object.assign(window, { Sidebar });
