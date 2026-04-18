// Hero section
function Hero() {
  return (
    <section style={{
      position: 'relative', overflow: 'hidden',
      padding: '120px 32px 128px',
      borderBottom: '1px solid var(--border-subtle)',
    }}>
      {/* mesh accent */}
      <div style={{
        position: 'absolute', top: '-30%', right: '-10%', width: 720, height: 720,
        background: 'radial-gradient(circle at center, rgba(198,242,78,0.18), transparent 60%)',
        pointerEvents: 'none', filter: 'blur(20px)',
      }}/>
      {/* hairline grid */}
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        backgroundImage: 'linear-gradient(to right, var(--border-subtle) 1px, transparent 1px), linear-gradient(to bottom, var(--border-subtle) 1px, transparent 1px)',
        backgroundSize: '48px 48px',
        maskImage: 'radial-gradient(circle at 50% 40%, black, transparent 75%)',
        WebkitMaskImage: 'radial-gradient(circle at 50% 40%, black, transparent 75%)',
        opacity: 0.6,
      }}/>

      <div style={{ position: 'relative', maxWidth: 1120, margin: '0 auto' }}>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 8, padding: '6px 12px', border: '1px solid var(--border-subtle)', borderRadius: 9999, marginBottom: 32 }}>
          <span style={{ width: 6, height: 6, borderRadius: '50%', background: 'var(--rl-signal)' }}/>
          <Mono size={12} color="var(--fg2)">v1.4 · agent mesh is live on base</Mono>
        </div>
        <h1 style={{ fontSize: 'clamp(56px, 9vw, 128px)', lineHeight: 0.95, letterSpacing: '-0.03em', marginBottom: 28, maxWidth: 1000 }}>
          intelligence,<br/>verified onchain.
        </h1>
        <p className="lede" style={{ maxWidth: 620, marginBottom: 40, fontSize: 20 }}>
          Rlabs builds AI agents that settle onchain and answer for their actions.
          Deploy in minutes. Audit in seconds. Trust by default.
        </p>
        <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap' }}>
          <Button variant="signal" size="lg" iconRight={<Icon name="arrow" size={16}/>}>ship to mainnet</Button>
          <Button variant="secondary" size="lg" icon={<Icon name="terminal" size={16}/>}>read the docs</Button>
        </div>

        {/* stats row */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 32, marginTop: 96, paddingTop: 40, borderTop: '1px solid var(--border-subtle)' }}>
          {[
            ['4.2M', 'agent txns settled'],
            ['99.98%', 'uptime across mainnets'],
            ['142ms', 'median decision latency'],
            ['7', 'chains supported'],
          ].map(([v, l]) => (
            <div key={l}>
              <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 40, lineHeight: 1, letterSpacing: '-0.02em', textTransform: 'lowercase' }} className="num">{v}</div>
              <div style={{ fontSize: 13, color: 'var(--fg3)', marginTop: 6 }}>{l}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
Object.assign(window, { Hero });
