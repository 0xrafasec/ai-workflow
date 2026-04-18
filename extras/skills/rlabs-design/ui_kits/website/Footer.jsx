// Footer
function Footer() {
  const cols = [
    { title: 'product', items: ['agents', 'studio', 'chains', 'observability', 'pricing'] },
    { title: 'developers', items: ['docs', 'sdk', 'cli', 'changelog', 'status'] },
    { title: 'company', items: ['about', 'careers', 'blog', 'press', 'contact'] },
    { title: 'legal',   items: ['terms', 'privacy', 'security', 'dpa'] },
  ];
  return (
    <footer style={{ padding: '80px 32px 32px', borderTop: '1px solid var(--border-subtle)', background: 'var(--bg-sunken)' }}>
      <div style={{ maxWidth: 1120, margin: '0 auto' }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1.4fr repeat(4, 1fr)', gap: 48, marginBottom: 64 }}>
          <div>
            <Wordmark size={22} />
            <p style={{ color: 'var(--fg2)', fontSize: 14, marginTop: 16, maxWidth: 280, lineHeight: 1.55 }}>
              The operating system for on-chain intelligence.
            </p>
          </div>
          {cols.map(c => (
            <div key={c.title}>
              <Eyebrow>{c.title}</Eyebrow>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 14 }}>
                {c.items.map(i => (
                  <a key={i} href="#" style={{ color: 'var(--fg1)', textDecoration: 'none', fontSize: 14 }}>{i}</a>
                ))}
              </div>
            </div>
          ))}
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: 28, borderTop: '1px solid var(--border-subtle)' }}>
          <Mono size={12} color="var(--fg3)">© 2026 rlabs, inc. · all rights reserved.</Mono>
          <Mono size={12} color="var(--fg3)">∎ intelligence, verified onchain.</Mono>
        </div>
      </div>
    </footer>
  );
}
Object.assign(window, { Footer });
